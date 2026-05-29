//
//  MKPushBootstrap.h
//
//  推送总线: 把 Firebase 初始化 + APNs token 处理 + UNUserNotificationCenterDelegate
//  从 AppDelegate 收编到一处。AppDelegate 只剩 3 处转发, 模板克隆即用。
//
//  典型接入(AppDelegate.m):
//
//      - (BOOL)application:... didFinishLaunchingWithOptions:... {
//          [[MKPushBootstrap sharedInstance] setup];
//          return YES;
//      }
//      - (void)application:... didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)t {
//          [[MKPushBootstrap sharedInstance] handleAPNsDeviceToken:t];
//      }
//      - (void)application:... didFailToRegisterForRemoteNotificationsWithError:(NSError *)e {
//          [[MKPushBootstrap sharedInstance] handleAPNsRegistrationError:e];
//      }
//
//  权限申请不在这里, 走 MKNotificationPermissionCoordinator。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKPushBootstrap : NSObject

+ (instancetype)sharedInstance;

/// 在 didFinishLaunchingWithOptions 调用一次。
/// 仅当 bundle 含 GoogleService-Info.plist 时初始化 Firebase, 否则跳过(测试期可以缺)。
- (void)setup;

/// 在 application:didRegisterForRemoteNotificationsWithDeviceToken: 转发。
- (void)handleAPNsDeviceToken:(NSData *)deviceToken;

/// 在 application:didFailToRegisterForRemoteNotificationsWithError: 转发。
- (void)handleAPNsRegistrationError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
