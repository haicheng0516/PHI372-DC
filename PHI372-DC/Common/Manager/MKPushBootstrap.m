//
//  MKPushBootstrap.m
//

#import "MKPushBootstrap.h"
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseMessaging/FirebaseMessaging.h>
#import "MKFCMTokenManager.h"
#import "MKEventTrackingService.h"

@interface MKPushBootstrap () <UNUserNotificationCenterDelegate>
@end

@implementation MKPushBootstrap

+ (instancetype)sharedInstance {
    static MKPushBootstrap *inst;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [[self alloc] init]; });
    return inst;
}

#pragma mark - Setup

- (void)setup {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (plistPath != nil) {
        [FIRApp configure];
        [FIRMessaging messaging].delegate = (id<FIRMessagingDelegate>)[MKFCMTokenManager sharedManager];
        NSLog(@"✅ [Push] FirebaseApp 初始化成功");
    } else {
        NSLog(@"⚠️ [Push] 未找到 GoogleService-Info.plist, Firebase 暂未初始化(测试前丢入)");
    }
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
}

#pragma mark - APNs Token Forwarding

- (void)handleAPNsDeviceToken:(NSData *)deviceToken {
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:deviceToken.length * 2];
    const unsigned char *bytes = deviceToken.bytes;
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [tokenString appendFormat:@"%02.2hhx", bytes[i]];
    }
    NSLog(@"✅ [Push] APNs 设备令牌: %@", tokenString);

    if ([FIRApp defaultApp] == nil) {
        NSLog(@"⚠️ [Push] Firebase 未初始化, 跳过 APNs → FCM 绑定");
        return;
    }
    [FIRMessaging messaging].APNSToken = deviceToken;
    [[MKFCMTokenManager sharedManager] fetchAndReport];
}

- (void)handleAPNsRegistrationError:(NSError *)error {
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
        NSLog(@"📊 [Push] 从推送进入 App, 埋点 602");
        [MKEventTrackingService recordEventWithCode:@"602"];
    }
    completionHandler();
}

@end
