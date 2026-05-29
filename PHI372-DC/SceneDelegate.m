//
//  SceneDelegate.m
//

#import "SceneDelegate.h"
#import "MKNavigationController.h"
#import "MKLoginManager.h"
#import "MKSignInViewController.h"
#import "MKHomeViewController.h"
#import "MKNotificationPermissionCoordinator.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *winScene = (UIWindowScene *)scene;
    if (![winScene isKindOfClass:[UIWindowScene class]]) return;

    self.window = [[UIWindow alloc] initWithWindowScene:winScene];

    // LaunchScreen.storyboard 显示 Se_bg + logo + APP name 至 didFinishLaunching 完成,
    // 此时根据登录态直接装载首页或登录页 — 不需要再走中间 splash VC
    UIViewController *root = nil;
    NSString *dbg = [[NSUserDefaults standardUserDefaults] stringForKey:@"MK.DebugRoute"];
    if (dbg.length) {
        Class c = NSClassFromString(dbg);
        if (c) {
            MKNavigationController *nav = [[MKNavigationController alloc] initWithRootViewController:[MKHomeViewController new]];
            [nav pushViewController:[c new] animated:NO];
            root = nav;
        }
    }
    if (!root) {
        UIViewController *first = [[MKLoginManager sharedManager] isLoggedIn]
            ? (UIViewController *)[MKHomeViewController new]
            : (UIViewController *)[MKSignInViewController new];
        root = [[MKNavigationController alloc] initWithRootViewController:first];
    }
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {}
- (void)sceneDidBecomeActive:(UIScene *)scene {
    // 显式同步通知权限状态: 覆盖用户从设置/推送启动等不依赖通知监听的路径,
    // 状态从非授权变为授权时补埋 600 + 注册 + 拉 token
    [[MKNotificationPermissionCoordinator sharedManager] syncPermissionStatusIfNeeded];
}
- (void)sceneWillResignActive:(UIScene *)scene {}
- (void)sceneWillEnterForeground:(UIScene *)scene {}
- (void)sceneDidEnterBackground:(UIScene *)scene {}

@end
