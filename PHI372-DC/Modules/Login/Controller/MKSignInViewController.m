//  MKSignInViewController.m
//  接入业务流: /sms/sendVerifySms + /auth/registerOrLogin

#import "MKSignInViewController.h"
#import "MKSignInCardView.h"
#import "MKGradientBackgroundView.h"
#import "MKConstants.h"
#import "MKLoginManager.h"
#import "MKNavigationController.h"
#import "MKHomeViewController.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKCommonParams.h"
#import "MKPhoneValidator.h"
#import "MKOTPValidator.h"
#import "MKLoginResponse.h"
#import "MKLoginUserInfo.h"
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKWebViewViewController.h"
#import "MKDeviceTool.h"
#import "MKEventTrackingService.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKSignInViewController ()
@property (nonatomic, strong) MKGradientBackgroundView *gradientBg;
@property (nonatomic, strong) MKSignInCardView *cardView;
@end

@implementation MKSignInViewController

- (instancetype)init {
    if (self = [super init]) { self.navBarStyle = MKNavBarStyleNone; }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self bindActions];
    // 延迟 1s 请 ATT, 避免与 KeyboardManager / 系统弹窗叠加
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self requestIDFAPermission];
    });
}

- (void)setupViews {
    self.gradientBg = [[MKGradientBackgroundView alloc]
        initWithFrame:CGRectMake(0, 0, kScreenWidth, kScaleH(484))];
    [self.view addSubview:self.gradientBg];

    self.cardView = [[MKSignInCardView alloc]
        initWithFrame:CGRectMake(kScaleW(18), kScaleH(103), kScaleW(339), kScaleH(512))];
    [self.view addSubview:self.cardView];
}

- (void)bindActions {
    __weak typeof(self) wself = self;
    self.cardView.onGetOTPTapped = ^{ [wself requestOTP]; };
    self.cardView.onSignInTapped = ^{ [wself doSignIn]; };
    self.cardView.onPrivacyPolicyTapped = ^{
        [MKEventTrackingService recordEventWithCode:@"2"];
        [wself openAgreementURLProvider:^NSString *(MKAppConfigModel *cfg) { return cfg.policyHref; }
                                  title:@"Privacy Policy"];
    };
    self.cardView.onServiceAgreementTapped = ^{
        [MKEventTrackingService recordEventWithCode:@"3"];
        [wself openAgreementURLProvider:^NSString *(MKAppConfigModel *cfg) { return cfg.agreementHref; }
                                  title:@"Service Agreement"];
    };
}

// 取 AppConfig 中的 URL 并 push WebView; 未加载先拉一次, 拉失败提示
- (void)openAgreementURLProvider:(NSString *(^)(MKAppConfigModel *cfg))urlBlock title:(NSString *)title {
    MKAppConfigManager *cfgMgr = [MKAppConfigManager sharedManager];
    NSString *cached = urlBlock(cfgMgr.currentAppConfig);
    if (cached.length > 0) {
        [self pushWebViewURL:cached title:title];
        return;
    }
    [SVProgressHUD showWithStatus:@"Loading..."];
    [cfgMgr loadConfigWithCompletion:^(MKAppConfigModel * _Nullable config) {
        [SVProgressHUD dismiss];
        NSString *url = urlBlock(config);
        if (url.length == 0) {
            [SVProgressHUD showErrorWithStatus:@"Link unavailable"];
            return;
        }
        [self pushWebViewURL:url title:title];
    }];
}

- (void)pushWebViewURL:(NSString *)url title:(NSString *)title {
    MKWebViewViewController *web = [[MKWebViewViewController alloc] initWithURL:url title:title];
    [self.navigationController pushViewController:web animated:YES];
}

#pragma mark - API: 发 OTP

- (void)requestOTP {
    NSString *phone = self.cardView.mobile ?: @"";
    NSString *phoneError = [MKPhoneValidator validationErrorMessage:phone];
    if (phoneError) {
        [SVProgressHUD showErrorWithStatus:phoneError];
        return;
    }
    NSString *normalized = [MKPhoneValidator submitPhoneNumber:phone];
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{
        @"mobile": normalized,
        @"verifyType": @"1"
    }];

    [SVProgressHUD showWithStatus:@"Sending..."];
    [[MKNetworkManager sharedManager] post:@"/app/v3/sms/sendVerifySms"
                                    params:body
                                   success:^(id resp) {
        // 发码接口回返 → 埋 4 (PHI259 一致, 不论 resultCode 是否 200)
        [MKEventTrackingService recordEventWithCode:@"4"];
        if (![resp isKindOfClass:[NSDictionary class]]) {
            [SVProgressHUD showErrorWithStatus:@"Bad response"];
            return;
        }
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code == 200) {
            [SVProgressHUD showSuccessWithStatus:@"OTP sent"];
            [self.cardView startOTPCountdown:60];
        } else {
            NSString *msg = resp[@"resultMsg"] ?: @"Failed to send OTP";
            [SVProgressHUD showErrorWithStatus:msg];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

#pragma mark - API: 登录

- (void)doSignIn {
    // 登录前埋 5
    [MKEventTrackingService recordEventWithCode:@"5"];
    NSString *phone = self.cardView.mobile ?: @"";
    NSString *otp = self.cardView.otp ?: @"";

    NSString *phoneError = [MKPhoneValidator validationErrorMessage:phone];
    if (phoneError) { [SVProgressHUD showErrorWithStatus:phoneError]; return; }
    NSString *otpError = [MKOTPValidator validationErrorMessage:otp];
    if (otpError) { [SVProgressHUD showErrorWithStatus:otpError]; return; }
    if (!self.cardView.agreementChecked) {
        [SVProgressHUD showErrorWithStatus:@"Please agree to the terms"];
        return;
    }

    NSString *normalized = [MKPhoneValidator submitPhoneNumber:phone];
    NSString *deviceId = [MKCommonParams shared].deviceId ?: @"";

    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{
        @"mobile": normalized,
        @"verifyCode": otp,
        @"imei": @"",
        @"serialNo": deviceId,
        @"longitude": @"-360",
        @"latitude": @"-360"
    }];

    [SVProgressHUD showWithStatus:@"Logging in..."];
    [[MKNetworkManager sharedManager] post:@"/app/v3/auth/registerOrLogin"
                                    params:body
                                   success:^(id resp) {
        NSLog(@"[Login] raw response = %@", resp);
        MKLoginResponse *r = [[MKLoginResponse alloc] initWithDictionary:resp];
        NSLog(@"[Login] parsed resultCode=%ld msg=%@ userId=%@ token=%@", (long)r.resultCode, r.resultMsg, r.data.userId, r.data.token);
        if (![r isSuccess]) {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Login failed"];
            return;
        }
        [[MKLoginManager sharedManager] loginWithUserId:r.data.userId
                                                  token:r.data.token
                                                 mobile:normalized];
        // 登录成功后上报设备指纹(风控/反欺诈), 不阻塞跳首页, 失败仅 log
        [self registerDevice];
        [SVProgressHUD showSuccessWithStatus:@"Welcome"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self enterHome];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

#pragma mark - 设备注册 (登录后上报指纹, 风控)

- (void)registerDevice {
    NSDictionary *deviceInfo = [MKDeviceTool collectDeviceInfoWithOrderId:@""];
    if (deviceInfo.count == 0) {
        NSLog(@"[registerDevice] device info empty, skip");
        return;
    }
    // 入参不参与签名: dataForSign 为空, dataForRequest 携带设备字段
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:@{}
                                                                                requestData:deviceInfo];
    [[MKNetworkManager sharedManager] post:@"/app/v3/mobile/registerDevice"
                                    params:body
                                   success:^(id resp) {
        NSInteger code = [resp[@"resultCode"] integerValue];
        NSLog(@"[registerDevice] resultCode=%ld msg=%@", (long)code, resp[@"resultMsg"]);
    } failure:^(NSError *error) {
        NSLog(@"[registerDevice] failed: %@", error.localizedDescription);
    }];
}

#pragma mark - IDFA / ATT (iOS 14+ 跟踪权限)

- (void)requestIDFAPermission {
    if (@available(iOS 14, *)) {
        ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
        if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus s) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self trackIDFAResult:s];
                });
            }];
        } else {
            [self trackIDFAResult:status];
        }
    }
}

- (void)trackIDFAResult:(ATTrackingManagerAuthorizationStatus)status API_AVAILABLE(ios(14)) {
    if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
        NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        NSLog(@"[ATT] authorized, IDFA=%@", idfa);
        [MKEventTrackingService recordEventWithCode:@"17"];
    } else {
        NSLog(@"[ATT] denied/restricted, status=%ld", (long)status);
        [MKEventTrackingService recordEventWithCode:@"18"];
    }
}

- (void)enterHome {
    MKHomeViewController *home = [MKHomeViewController new];
    MKNavigationController *nav = [[MKNavigationController alloc] initWithRootViewController:home];
    UIWindow *win = self.view.window;
    [UIView transitionWithView:win duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ win.rootViewController = nav; }
                    completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
