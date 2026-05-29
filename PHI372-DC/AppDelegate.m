//
//  AppDelegate.m
//  PHI372-DC
//
//  Created by Seacity on 2026/5/19.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseMessaging/FirebaseMessaging.h>
#import "MKFCMTokenManager.h"
#import "MKEventTrackingService.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // SVProgressHUD 全局显示时长(默认 minimum=5s 偏长, 收紧到 1.5~3s)
    [SVProgressHUD setMinimumDismissTimeInterval:1.5];
    [SVProgressHUD setMaximumDismissTimeInterval:3.0];

    // Firebase 推送(仅当 GoogleService-Info.plist 已打包进 bundle 时初始化)
    [self setupPushNotifications];
    return YES;
}

#pragma mark - Push Notifications

- (void)setupPushNotifications {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (plistPath != nil) {
        [FIRApp configure];
        [FIRMessaging messaging].delegate = (id<FIRMessagingDelegate>)[MKFCMTokenManager sharedManager];
        NSLog(@"✅ [Push] FirebaseApp 初始化成功");
    } else {
        NSLog(@"⚠️ [Push] 未找到 GoogleService-Info.plist,Firebase 暂未初始化(测试前丢入)");
    }
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
}

#pragma mark - APNs Token

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:deviceToken.length * 2];
    const unsigned char *bytes = deviceToken.bytes;
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [tokenString appendFormat:@"%02.2hhx", bytes[i]];
    }
    NSLog(@"✅ [Push] APNs 设备令牌: %@", tokenString);

    if ([FIRApp defaultApp] == nil) {
        NSLog(@"⚠️ [Push] Firebase 未初始化,跳过 APNs → FCM 绑定");
        return;
    }
    [FIRMessaging messaging].APNSToken = deviceToken;
    [[MKFCMTokenManager sharedManager] fetchAndReport];
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"❌ [Push] APNs 注册失败: %@", error.localizedDescription);
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner
                          | UNNotificationPresentationOptionList
                          | UNNotificationPresentationOptionSound);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
    }
}

/// 用户从推送进入 App: 仅当 inactive/background 时埋 602
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateInactive || state == UIApplicationStateBackground) {
        NSLog(@"📊 [Push] 从推送进入 App,埋点 602");
        [MKEventTrackingService recordEventWithCode:@"602"];
    }
    completionHandler();
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
}


@end
