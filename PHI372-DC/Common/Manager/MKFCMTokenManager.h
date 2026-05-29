//
//  MKFCMTokenManager.h
//
//  负责拉取 Firebase FCM token(带重试),并通过 /app/v3/user/info 上报给后端。
//  未登录时先暂存,登录后由 MKLoginStateDidChangeNotification 触发补发。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKFCMTokenManager : NSObject

+ (instancetype)sharedManager;

/// 拉取 token 并尝试上报(带简单指数退避重试)。
/// AppDelegate 拿到 APNs token 后 / 权限授权成功后调用。
- (void)fetchAndReport;

/// 重置上报状态(如需要重新上报)
- (void)resetReportFlag;

@end

NS_ASSUME_NONNULL_END
