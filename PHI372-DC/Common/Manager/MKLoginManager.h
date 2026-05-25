//
//  MKLoginManager.h
//  PHI372-DC
//
//  极简登录态管理: 用 NSUserDefaults 记 isLoggedIn / mobile / token,
//  Phase 9 接入接口时替换为 [_DEFERRED/NetWorkTool/MKLoginManager.m] 那一版.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const MKLoginStateDidChangeNotification;

@interface MKLoginManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign, readonly) BOOL isLoggedIn;
@property (nonatomic, copy, readonly, nullable) NSString *mobile;
@property (nonatomic, copy, readonly, nullable) NSString *token;
@property (nonatomic, copy, readonly, nullable) NSString *userId;

/// KYC 完成态(用于首页判断走 BeforeKYC 还是 AfterKYC).
@property (nonatomic, assign) BOOL kycCompleted;

- (void)loginWithMobile:(NSString *)mobile token:(NSString *)token;
- (void)loginWithUserId:(NSString *)userId token:(NSString *)token mobile:(NSString *)mobile;
- (void)logout;

@end

NS_ASSUME_NONNULL_END
