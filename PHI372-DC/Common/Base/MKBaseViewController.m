//
//  MKBaseViewController.m
//

#import "MKBaseViewController.h"
#import "MKConstants.h"

@interface MKBaseViewController ()
@property (nonatomic, strong) UIView *customNavBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, assign) BOOL didApplyStatusBarStyle;
@end

@implementation MKBaseViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _navBarStyle = MKNavBarStyleLight;          // 默认白底黑字
        _statusBarStyle = UIStatusBarStyleDefault;  // 跟随 navBarStyle 推断
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 系统导航栏全程隐藏, 由 customNavBar 替代
    self.navigationController.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupCustomNavBarIfNeeded];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.didApplyStatusBarStyle) return self.statusBarStyle;
    switch (self.navBarStyle) {
        case MKNavBarStyleNone:
        case MKNavBarStyleTransparent:
        case MKNavBarStylePrimaryDark:
            return UIStatusBarStyleLightContent;
        case MKNavBarStyleLight:
        default:
            return UIStatusBarStyleDarkContent;
    }
}

- (void)setStatusBarStyle:(UIStatusBarStyle)style {
    _statusBarStyle = style;
    _didApplyStatusBarStyle = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Custom NavBar

- (void)setupCustomNavBarIfNeeded {
    if (self.navBarStyle == MKNavBarStyleNone) return;

    BOOL light = (self.navBarStyle == MKNavBarStyleLight);
    BOOL primaryDark = (self.navBarStyle == MKNavBarStylePrimaryDark);
    UIColor *bg = light ? [UIColor whiteColor]
                : (primaryDark ? MKHexColor(0x385330) : [UIColor clearColor]);
    UIColor *fg = light ? [UIColor blackColor] : [UIColor whiteColor];
    BOOL showTitle = light || primaryDark;

    self.customNavBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kNavBarHeight)];
    self.customNavBar.backgroundColor = bg;
    if (primaryDark) {
        // Figma 标准品牌 nav: 底部圆角 14px (0 0 14 14)
        self.customNavBar.layer.cornerRadius = 14;
        self.customNavBar.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    }
    [self.view addSubview:self.customNavBar];

    // 返回按钮 (仅非根 VC 显示)
    BOOL showBack = (self.navigationController.viewControllers.count > 1);
    if (showBack) {
        self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.backButton.frame = CGRectMake(kScaleW(8), kStatusBarHeight, 44, 44);
        [self.backButton setTitle:@"‹" forState:UIControlStateNormal];  // 占位返回箭头, Phase 4 换图
        [self.backButton setTitleColor:fg forState:UIControlStateNormal];
        self.backButton.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightLight];
        [self.backButton addTarget:self action:@selector(onBackTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.customNavBar addSubview:self.backButton];
    }

    // 标题 (Light + PrimaryDark 显示)
    if (showTitle) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(60), kStatusBarHeight, kScreenWidth - kScaleW(120), 44)];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];   // Pencil: PingFang SC 20pt
        self.titleLabel.textColor = fg;
        self.titleLabel.text = self.navTitle ?: @"";
        [self.customNavBar addSubview:self.titleLabel];
    }
}

- (void)setNavTitle:(NSString *)navTitle {
    _navTitle = [navTitle copy];
    self.titleLabel.text = navTitle ?: @"";
}

- (void)onBackTapped {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
