//
//  AppDelegate.m
//  PHI372-DC
//
//  Created by Seacity on 2026/5/19.
//

#import "AppDelegate.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // SVProgressHUD 全局显示时长(默认 minimum=5s 偏长, 收紧到 1.5~3s)
    [SVProgressHUD setMinimumDismissTimeInterval:1.5];
    [SVProgressHUD setMaximumDismissTimeInterval:3.0];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
