//
//  MKRejectFlowCoordinator.m
//

#import "MKRejectFlowCoordinator.h"
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKRejectWebViewController.h"
#import <UIKit/UIKit.h>

@implementation MKRejectFlowCoordinator

+ (BOOL)shouldTriggerRejectFlow {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.rejectH5;
    return url.length > 0;
}

+ (BOOL)presentRejectH5FromVC:(UIViewController *)host {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.rejectH5;
    if (url.length == 0) return NO;

    UIViewController *target = host ?: [self mk_topMostViewController];
    if (!target.navigationController) return NO;

    MKRejectWebViewController *web = [[MKRejectWebViewController alloc] initWithURL:url title:nil];
    [target.navigationController pushViewController:web animated:YES];
    return YES;
}

#pragma mark - Helpers

/// 从 keyWindow 出发找当前栈顶 VC, 穿透 presented / Navigation / TabBar。
+ (nullable UIViewController *)mk_topMostViewController {
    UIViewController *top = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes.allObjects) {
        if (![s isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)s).windows) {
            if (w.isKeyWindow) { top = w.rootViewController; break; }
        }
        if (top) break;
    }
    while (top.presentedViewController) top = top.presentedViewController;
    if ([top isKindOfClass:[UINavigationController class]]) {
        top = [(UINavigationController *)top topViewController];
    } else if ([top isKindOfClass:[UITabBarController class]]) {
        UIViewController *sel = [(UITabBarController *)top selectedViewController];
        top = [sel isKindOfClass:[UINavigationController class]]
            ? [(UINavigationController *)sel topViewController]
            : sel;
    }
    return top;
}

@end
