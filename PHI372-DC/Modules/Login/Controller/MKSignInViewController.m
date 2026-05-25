//
//  MKSignInViewController.m
//  PHI372-DC
//
//  接入 334 业务流: /sms/sendVerifySms + /auth/registerOrLogin
//

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
        [SVProgressHUD showSuccessWithStatus:@"Welcome"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self enterHome];
        });
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
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
