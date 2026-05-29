//
//  MKFCMTokenManager.m
//  PHI372-DC
//

#import "MKFCMTokenManager.h"
#import "MKLoginManager.h"
#import "MKEncryptManager.h"
#import "MKNetworkManager.h"
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseMessaging/FirebaseMessaging.h>

@interface MKFCMTokenManager () <FIRMessagingDelegate>
@property (nonatomic, copy, nullable) NSString *pendingToken;
@property (nonatomic, assign) BOOL hasReported;
@property (nonatomic, assign) BOOL isReporting;
@end

@implementation MKFCMTokenManager

+ (instancetype)sharedManager {
    static MKFCMTokenManager *s_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[MKFCMTokenManager alloc] init];
    });
    return s_instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLoginStateChanged:)
                                                     name:MKLoginStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (void)fetchAndReport {
    if ([FIRApp defaultApp] == nil) {
        NSLog(@"⚠️ [FCM] Firebase 未初始化,跳过 token 获取");
        return;
    }
    [self fetchTokenWithRetryCount:0];
}

- (void)resetReportFlag {
    self.hasReported = NO;
}

#pragma mark - Token Fetch

- (void)fetchTokenWithRetryCount:(NSInteger)retryCount {
    __weak typeof(self) weakSelf = self;
    [[FIRMessaging messaging] tokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        if (error) {
            NSLog(@"❌ [FCM] 获取 token 失败: %@", error.localizedDescription);
            if (retryCount < 5) {
                NSTimeInterval delay = pow(2.0, (double)retryCount); // 1,2,4,8,16 秒
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [self fetchTokenWithRetryCount:retryCount + 1];
                });
            }
            return;
        }

        if (token.length == 0) {
            NSLog(@"⚠️ [FCM] token 为空,稍后重试");
            if (retryCount < 5) {
                NSTimeInterval delay = pow(2.0, (double)retryCount);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [self fetchTokenWithRetryCount:retryCount + 1];
                });
            }
            return;
        }

        NSLog(@"✅ [FCM] 获取 token 成功: %@", token);
        self.pendingToken = token;
        [self reportToken:token];
    }];
}

#pragma mark - Report

- (void)reportToken:(NSString *)token {
    if (self.hasReported) {
        NSLog(@"⚠️ [FCM] token 已上报过,跳过");
        return;
    }
    if (self.isReporting) {
        NSLog(@"⚠️ [FCM] 正在上报中,跳过重复触发");
        return;
    }
    MKLoginManager *m = [MKLoginManager sharedManager];
    BOOL isLoggedIn = (m.token.length > 0) && (m.userId.length > 0);
    if (!isLoggedIn) {
        NSLog(@"⚠️ [FCM] 未登录,暂存 token 等登录后补发");
        return;
    }

    self.isReporting = YES;

    // googleToken 不参与签名,signData 传空
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:@{}
                                                                               requestData:@{ @"googleToken": token }];

    __weak typeof(self) weakSelf = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/user/info"
                                    params:body
                                   success:^(id _Nullable responseObject) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isReporting = NO;

        BOOL ok = ([responseObject isKindOfClass:[NSDictionary class]]
                   && [responseObject[@"resultCode"] integerValue] == 200);
        if (ok) {
            NSLog(@"✅ [FCM] googleToken 上报成功");
            self.hasReported = YES;
            self.pendingToken = nil;
        } else {
            NSString *msg = [responseObject isKindOfClass:[NSDictionary class]] ? (responseObject[@"resultMsg"] ?: @"unknown") : @"unknown";
            NSLog(@"❌ [FCM] googleToken 上报失败: %@,暂存等待下次补发", msg);
        }
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isReporting = NO;
        NSLog(@"❌ [FCM] googleToken 上报网络错误: %@", error.localizedDescription);
    }];
}

#pragma mark - Login State Change

- (void)handleLoginStateChanged:(NSNotification *)note {
    if (![[MKLoginManager sharedManager] isLoggedIn]) {
        NSLog(@"🔁 [FCM] 用户已登出,重置 token 上报状态");
        self.hasReported = NO;
        self.pendingToken = nil;
        return;
    }

    if (self.hasReported) return;

    if (self.pendingToken.length > 0) {
        NSLog(@"🔁 [FCM] 用户已登录,补发暂存 token");
        [self reportToken:self.pendingToken];
    } else {
        [self fetchTokenWithRetryCount:0];
    }
}

#pragma mark - FIRMessagingDelegate

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    if (fcmToken.length == 0) {
        NSLog(@"⚠️ [FCM] MessagingDelegate 回调 token 为空");
        return;
    }
    NSLog(@"✅ [FCM] MessagingDelegate 回调收到 token: %@", fcmToken);

    if (![fcmToken isEqualToString:self.pendingToken]) {
        // 服务端刷新了 token,重置上报标记并再次上报
        self.pendingToken = fcmToken;
        self.hasReported = NO;
        [self reportToken:fcmToken];
    } else if (!self.hasReported) {
        [self reportToken:fcmToken];
    }
}

@end
