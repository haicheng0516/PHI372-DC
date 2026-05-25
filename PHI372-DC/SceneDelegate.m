//
//  SceneDelegate.m
//  PHI372-DC
//

#import "SceneDelegate.h"
#import "MKNavigationController.h"
#import "MKLaunchViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *winScene = (UIWindowScene *)scene;
    if (![winScene isKindOfClass:[UIWindowScene class]]) return;

    self.window = [[UIWindow alloc] initWithWindowScene:winScene];

    // 启动总是先进 Launch, Launch 内部 1.5s 后根据登录态切到 Login 或 Home
    MKLaunchViewController *launch = [[MKLaunchViewController alloc] init];
    MKNavigationController *nav = [[MKNavigationController alloc] initWithRootViewController:launch];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {}
- (void)sceneDidBecomeActive:(UIScene *)scene {}
- (void)sceneWillResignActive:(UIScene *)scene {}
- (void)sceneWillEnterForeground:(UIScene *)scene {}
- (void)sceneDidEnterBackground:(UIScene *)scene {}

@end
