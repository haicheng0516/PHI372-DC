//
//  MKLaunchViewController.m
//  PHI372-DC
//
//  Figma 3:1688 启动页. 进入 1.5s 后根据 MKLoginManager 切到 Login 或 Home.
//

#import "MKLaunchViewController.h"
#import "MKConstants.h"
#import "MKGradientBackgroundView.h"
#import "MKLoginManager.h"
#import "MKNavigationController.h"
#import "MKSignInViewController.h"
#import "MKHomeViewController.h"

@implementation MKLaunchViewController

- (instancetype)init {
    if (self = [super init]) { self.navBarStyle = MKNavBarStyleNone; }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Pencil 启动页结构: bg #ECEFF3 + 全屏图(image-import-2)占位 + 蒙版 #385330bd + 光晕 + logo + APP name
    self.view.backgroundColor = MKHexColor(0xECEFF3);

    // 图片占位 (image-import-2): 用浅金色 #C9A77E 模拟金币堆色温
    UIView *imagePlaceholder = [[UIView alloc] initWithFrame:self.view.bounds];
    imagePlaceholder.backgroundColor = MKHexColor(0xC9A77E);
    imagePlaceholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:imagePlaceholder];

    // 绿色蒙版层 #385330bd (alpha 0.74)
    UIView *mask = [[UIView alloc] initWithFrame:self.view.bounds];
    mask.backgroundColor = [UIColor colorWithRed:0x38/255.0 green:0x53/255.0 blue:0x30/255.0 alpha:0.74];
    mask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:mask];

    // Pencil: Ellipse 805 光晕 #F4C15F, blur 5.5, (262, 502, 65x58)
    // 用 shadow 模拟 blur 辉光
    UIView *glow = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(262), kScaleH(502), kScaleW(65), kScaleH(58))];
    glow.backgroundColor = MKHexColor(0xF4C15F);
    glow.layer.cornerRadius = kScaleW(29);
    glow.layer.shadowColor = MKHexColor(0xF4C15F).CGColor;
    glow.layer.shadowOffset = CGSizeZero;
    glow.layer.shadowRadius = kScaleW(20);
    glow.layer.shadowOpacity = 0.9;
    [self.view addSubview:glow];

    // Pencil logo 白色方块: (273, 610, 50x50) cornerRadius 14, shadow outer
    UIView *logo = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(273), kScaleH(610), kScaleW(50), kScaleW(50))];
    logo.backgroundColor = kColorWhite;
    logo.layer.cornerRadius = kScaleW(14);
    logo.layer.shadowColor = [UIColor colorWithRed:0.62 green:0.62 blue:0.62 alpha:0.08].CGColor;
    logo.layer.shadowOffset = CGSizeMake(0, kScaleH(16));
    logo.layer.shadowRadius = kScaleW(28);
    logo.layer.shadowOpacity = 1.0;
    [self.view addSubview:logo];

    // Pencil App name: (207, 687) ABeeZee 24 white
    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(207), kScaleH(687), kScreenWidth - kScaleW(207) - kScaleW(20), kScaleH(36))];
    name.text = @"APP name"; name.font = kFontRegular(24); name.textColor = kColorWhite;
    name.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:name];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self routeToNext];
    });
}

- (void)routeToNext {
    UIViewController *next = nil;
    UIViewController *stubRoot = nil;  // 当 DebugRoute 指向子页面时, 底下垫一个 Home 让返回按钮挂得出
    // 调试入口: defaults write com.mk.phi372dc MK.DebugRoute -string "VCClassName"
    NSString *dbg = [[NSUserDefaults standardUserDefaults] stringForKey:@"MK.DebugRoute"];
    if (dbg.length) {
        Class c = NSClassFromString(dbg);
        if (c) {
            next = [c new];
            // KYC / Profile / Order 等都是子页面, 给一个 Home 作为返回锚
            stubRoot = [MKHomeViewController new];
        }
    }
    if (!next) {
        if ([[MKLoginManager sharedManager] isLoggedIn]) {
            next = [MKHomeViewController new];
        } else {
            next = [MKSignInViewController new];
        }
    }
    MKNavigationController *nav;
    if (stubRoot) {
        nav = [[MKNavigationController alloc] initWithRootViewController:stubRoot];
        [nav pushViewController:next animated:NO];
    } else {
        nav = [[MKNavigationController alloc] initWithRootViewController:next];
    }
    UIWindow *win = self.view.window;
    if (!win) {
        // Fallback through scene
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)s).windows) { if (w.isKeyWindow) { win = w; break; } }
            }
            if (win) break;
        }
    }
    [UIView transitionWithView:win duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ win.rootViewController = nav; }
                    completion:^(BOOL finished) {
                        [nav setNeedsStatusBarAppearanceUpdate];
                    }];
}

@end
