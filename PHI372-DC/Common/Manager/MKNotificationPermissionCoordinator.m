//
//  MKNotificationPermissionCoordinator.m
//  PHI372-DC
//

#import "MKNotificationPermissionCoordinator.h"
#import "MKFCMTokenManager.h"
#import "MKEventTrackingService.h"
#import "MKBottomSheetView.h"
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

static NSString * const kLastCheckDateKey  = @"NotificationPermission.LastCheckDate";
static NSString * const kLastAuthStatusKey = @"NotificationPermission.LastAuthStatus";

@implementation MKNotificationPermissionCoordinator

+ (instancetype)sharedManager {
    static MKNotificationPermissionCoordinator *s_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[MKNotificationPermissionCoordinator alloc] init];
    });
    return s_instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // App 从后台 / 设置页回到前台时补检(用户可能在系统设置里开了通知)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Did Become Active

- (void)handleAppDidBecomeActive {
    [self syncPermissionStatusIfNeeded];
}

- (void)syncPermissionStatusIfNeeded {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        UNAuthorizationStatus current = settings.authorizationStatus;

        // 读取上次记录的状态后立即写入当前状态,避免后续切后台再回来重复埋 600
        NSNumber *lastRaw = [[NSUserDefaults standardUserDefaults] objectForKey:kLastAuthStatusKey];
        BOOL hasLast = [lastRaw isKindOfClass:[NSNumber class]];
        UNAuthorizationStatus last = hasLast ? (UNAuthorizationStatus)lastRaw.integerValue : UNAuthorizationStatusNotDetermined;
        [[NSUserDefaults standardUserDefaults] setObject:@(current) forKey:kLastAuthStatusKey];

        BOOL isAuthorized = (current == UNAuthorizationStatusAuthorized
                             || current == UNAuthorizationStatusProvisional
                             || current == UNAuthorizationStatusEphemeral);
        if (!isAuthorized) return;

        BOOL wasAuthorized = hasLast && (last == UNAuthorizationStatusAuthorized
                                         || last == UNAuthorizationStatusProvisional
                                         || last == UNAuthorizationStatusEphemeral);
        dispatch_async(dispatch_get_main_queue(), ^{
            // 状态从非授权切到授权(用户在系统设置里手动开启)→ 补埋 600
            if (!wasAuthorized) {
                NSLog(@"✅ [Push] 用户从设置授权了通知权限,补埋点 600");
                [MKEventTrackingService recordEventWithCode:@"600"];
            }
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            [[MKFCMTokenManager sharedManager] fetchAndReport];
        });
    }];
}

#pragma mark - Public

- (BOOL)hasCheckedToday {
    NSDate *last = [[NSUserDefaults standardUserDefaults] objectForKey:kLastCheckDateKey];
    if (![last isKindOfClass:[NSDate class]]) return NO;
    return [[NSCalendar currentCalendar] isDateInToday:last];
}

- (void)checkAndRequestIfNeededWithCompletion:(void (^)(BOOL))completion {
    if (self.hasCheckedToday) {
        if (completion) completion(NO);
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(NO); });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self markCheckedToday];
            switch (settings.authorizationStatus) {
                case UNAuthorizationStatusNotDetermined:
                    [self requestSystemAuthorization];
                    if (completion) completion(YES);
                    break;
                case UNAuthorizationStatusDenied:
                    [self showSecondaryDialog];
                    if (completion) completion(YES);
                    break;
                case UNAuthorizationStatusAuthorized:
                case UNAuthorizationStatusProvisional:
                case UNAuthorizationStatusEphemeral:
                    [self registerForRemoteNotificationsAndFetch];
                    if (completion) completion(NO);
                    break;
                default:
                    if (completion) completion(NO);
                    break;
            }
        });
    }];
}

#pragma mark - System Authorization

- (void)requestSystemAuthorization {
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    __weak typeof(self) weakSelf = self;
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options
                                                                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error) {
            NSLog(@"❌ [Push] 请求通知权限错误: %@", error.localizedDescription);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (granted) {
                NSLog(@"✅ [Push] 通知权限已授权,埋点 600");
                [MKEventTrackingService recordEventWithCode:@"600"];
                // 立即写入最新授权状态,避免下次 didBecomeActive 误判"上次非授权"重复埋 600
                [[NSUserDefaults standardUserDefaults] setObject:@(UNAuthorizationStatusAuthorized) forKey:kLastAuthStatusKey];
                [self registerForRemoteNotificationsAndFetch];
            } else {
                NSLog(@"❌ [Push] 通知权限被拒绝,埋点 601");
                [MKEventTrackingService recordEventWithCode:@"601"];
                [[NSUserDefaults standardUserDefaults] setObject:@(UNAuthorizationStatusDenied) forKey:kLastAuthStatusKey];
            }
        });
    }];
}

- (void)registerForRemoteNotificationsAndFetch {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[MKFCMTokenManager sharedManager] fetchAndReport];
}

#pragma mark - Secondary Dialog (denied 状态引导去设置;复用本项目封装的返回弹窗)

- (void)showSecondaryDialog {
    // 二次弹窗即"通知权限请求失败"语义,弹窗显示时即埋 601
    NSLog(@"❌ [Push] 通知权限请求失败,弹出二次引导,埋点 601");
    [MKEventTrackingService recordEventWithCode:@"601"];

    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypePermissionNotification config:nil];
    __weak typeof(self) weakSelf = self;
    sheet.onConfirmTapped = ^{
        [weakSelf openAppSettings];
    };
    [sheet show];
}

- (void)openAppSettings {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

#pragma mark - Check Date

- (void)markCheckedToday {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastCheckDateKey];
}

@end
