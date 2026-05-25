//
//  MKNavigationController.m
//

#import "MKNavigationController.h"
#import "MKConstants.h"

@implementation MKNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 系统 NavBar 默认隐藏 — 各 VC 由 MKBaseViewController 自己画 NavBar
    self.navigationBar.hidden = YES;
    self.interactivePopGestureRecognizer.delegate = nil;
}

// 显式把状态栏 / 安全区代理给 topVC, 防止系统不转发
- (UIViewController *)childViewControllerForStatusBarStyle { return self.topViewController; }
- (UIViewController *)childViewControllerForStatusBarHidden { return self.topViewController; }
- (UIStatusBarStyle)preferredStatusBarStyle { return self.topViewController.preferredStatusBarStyle; }
- (BOOL)prefersStatusBarHidden { return self.topViewController.prefersStatusBarHidden; }

@end
