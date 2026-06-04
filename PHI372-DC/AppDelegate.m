//
//  AppDelegate.m
//

#import "AppDelegate.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "MKPushBootstrap.h"
#import "MKEventTrackingService.h"

static NSString * const kMKHasTrackedFirstOpenKey = @"MK.HasTrackedFirstOpen";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // SVProgressHUD 全局显示时长(默认 minimum=5s 偏长, 收紧到 1.5~3s)
    [SVProgressHUD setMinimumDismissTimeInterval:1.5];
    [SVProgressHUD setMaximumDismissTimeInterval:3.0];

    // 推送(Firebase + UNUserNotificationCenter delegate)
    [[MKPushBootstrap sharedInstance] setup];

    // 埋点: 首次打开 App (一次性)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kMKHasTrackedFirstOpenKey]) {
        [MKEventTrackingService recordEventWithCode:@"0"];
        [defaults setBool:YES forKey:kMKHasTrackedFirstOpenKey];
        [defaults synchronize];
    }
    // 埋点: 每次启动 App
    [MKEventTrackingService recordEventWithCode:@"1"];

    return YES;
}

#pragma mark - APNs Token (转发给 MKPushBootstrap)

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[MKPushBootstrap sharedInstance] handleAPNsDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[MKPushBootstrap sharedInstance] handleAPNsRegistrationError:error];
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
}

@end
