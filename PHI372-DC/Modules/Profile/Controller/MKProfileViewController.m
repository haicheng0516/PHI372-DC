//  MKProfileViewController.m
//  PHI372-DC — Figma 3:338 个人中心
//  布局精确还原 Figma 3:338 (375×812):
//    顶部绿色 BG     0,0,375,222    fill #385330  圆角 0 0 14 14
//      + 钱币插画图 (image fill, scaleMode=FILL)
//      + 黄色椭圆光 (133,502, 65×58, blur 6.3px, #F4C15F)   *相对蒙版组
//      + 蒙版         rgba(56,83,48,0.9)
//    Avatar            (163,103) 50×50 圆形, stroke #385330 1px, shadow
//    Appname 文本      (145,167) 86×22, Inter 500 18, white
//    返回箭头          (30,64) 24×24
//    Card #1 白卡     (18,239) 339×166  r=14   3 行: Repayment Instructions / Feedback / Official Website
//    Card #2 白卡     (18,417) 339×205  r=14   4 行: About / Terms of the loan / Privacy policy / Log out
//    菜单文字          Source Sans Pro 600 14, #0D1218 (SF semibold 14)
//    每行 icon x=38(图内 38) 24×24; chevron 右边距=15

#import "MKProfileViewController.h"
#import "MKConstants.h"
#import "MKProfileFeedbackViewController.h"
#import "MKProfileAboutViewController.h"
#import "MKProfileRepaymentInfoViewController.h"
#import "MKProfileAgreementViewController.h"
#import "MKProfileOfficialReloanViewController.h"
#import "MKBottomSheetView.h"
#import "MKLoginManager.h"
#import "MKNavigationController.h"
#import "MKSignInViewController.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

#pragma mark - Menu Row

@interface MKProfileMenuRow : UIControl
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIImageView *chevron;
@end

@implementation MKProfileMenuRow
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _iconView = [[UIImageView alloc] init];
        _iconView.tintColor = kColorPrimary;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = kFontSemibold(14);
        _titleLabel.textColor = MKHexColor(0x0D1218);
        [self addSubview:_titleLabel];

        _chevron = [[UIImageView alloc] init];
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold];
        _chevron.image = [[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _chevron.tintColor = MKHexColor(0x2A2A2A);
        _chevron.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_chevron];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height;
    CGFloat w = self.bounds.size.width;
    // icon: 内card 起点 x=20 (相对 view x=38 - card x=18), 24×24, 垂直居中
    CGFloat iconSize = kScaleW(24);
    self.iconView.frame = CGRectMake(kScaleW(20), (h - iconSize) * 0.5, iconSize, iconSize);
    CGFloat textX = kScaleW(20) + iconSize + kScaleW(10);
    self.titleLabel.frame = CGRectMake(textX, 0, w - textX - kScaleW(40), h);
    // chevron: 距右 15, 14×14
    CGFloat cvSize = kScaleW(14);
    self.chevron.frame = CGRectMake(w - kScaleW(15) - cvSize, (h - cvSize) * 0.5, cvSize, cvSize);
}
@end

#pragma mark - VC

@interface MKProfileViewController ()
@property (nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *sections;
@end

@implementation MKProfileViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.navBarStyle = MKNavBarStyleNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self buildItems];
    [self setupHeader];
    [self setupCards];
    [self setupBackButton];
}

- (void)buildItems {
    self.sections = @[
        @[ // Card 1 — 服务说明类
            @{ @"title": @"Repayment Instructions", @"symbol": @"doc.text",              @"cls": @"MKProfileRepaymentInfoViewController" },
            @{ @"title": @"Feedback",               @"symbol": @"questionmark.circle",   @"cls": @"MKProfileFeedbackViewController" },
            @{ @"title": @"Official Website",       @"symbol": @"globe",                 @"cls": @"MKProfileOfficialReloanViewController" },
        ],
        @[ // Card 2 — 账号/法律/退出
            @{ @"title": @"About",                  @"symbol": @"person",                                @"cls": @"MKProfileAboutViewController" },
            @{ @"title": @"Terms of the loan",      @"symbol": @"doc.plaintext",                         @"cls": @"MKProfileAgreementViewController" },
            @{ @"title": @"Privacy policy",         @"symbol": @"lock.shield",                           @"cls": @"MKProfileAgreementViewController" },
            @{ @"title": @"Log out",                @"symbol": @"rectangle.portrait.and.arrow.right",    @"cls": @"_LOGOUT_" },
        ],
    ];
}

- (void)setupHeader {
    CGFloat hH = kScaleH(222);
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, hH)];
    header.backgroundColor = kColorPrimary;
    header.clipsToBounds = YES;
    header.layer.cornerRadius = kScaleH(14);
    header.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.view addSubview:header];

    // 钱币插画底图 (Figma 23:5114, image fill cover)
    UIImageView *bgImg = [[UIImageView alloc] initWithFrame:header.bounds];
    bgImg.image = [UIImage imageNamed:@"mk_me_header_bg"];
    bgImg.contentMode = UIViewContentModeScaleAspectFill;
    bgImg.clipsToBounds = YES;
    [header addSubview:bgImg];

    // 蒙版: rgba(56,83,48,0.9) — Figma 23:5116
    UIView *mask = [[UIView alloc] initWithFrame:header.bounds];
    mask.backgroundColor = MKColorAlpha(56, 83, 48, 0.9);
    [header addSubview:mask];

    // Avatar (Figma 1:2: 163,103 50×50 圆, stroke #385330 1px)
    UIView *avatar = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(163), kScaleH(103), kScaleW(50), kScaleW(50))];
    avatar.backgroundColor = kColorWhite;
    avatar.layer.cornerRadius = kScaleW(25);
    avatar.layer.borderWidth = 1;
    avatar.layer.borderColor = kColorPrimary.CGColor;
    avatar.layer.shadowColor = [UIColor blackColor].CGColor;
    avatar.layer.shadowOpacity = 0.01;
    avatar.layer.shadowOffset = CGSizeMake(0, 4);
    avatar.layer.shadowRadius = 4;
    [header addSubview:avatar];

    // Appname (Figma 1:12: 145,167 86×22, Inter 500 18, white, center) — 走 Info.plist 显示名
    UILabel *appName = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(167), kScreenWidth, kScaleH(22))];
    appName.text = MKAppDisplayName();
    appName.textAlignment = NSTextAlignmentCenter;
    appName.font = kFontMedium(18);
    appName.textColor = kColorWhite;
    [header addSubview:appName];
}

- (void)setupBackButton {
    if (self.navigationController.viewControllers.count <= 1) return;
    // Figma: 返回箭头 (30,64) 24×24, 白色
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(kScaleW(20), kStatusBarHeight + kScaleH(8), 44, 44);
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
    UIImage *img = [[UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [back setImage:img forState:UIControlStateNormal];
    back.tintColor = MKHexColor(0xBBCB2F);
    back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    back.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    [back addTarget:self action:@selector(onBackTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
}

- (void)setupCards {
    // Card 1: (18,239) 339×166  顶部 padding=24  行高 49
    UIView *c1 = [self buildCardAtY:239 height:166 topPad:24 items:self.sections[0] sectionIdx:0];
    [self.view addSubview:c1];

    // Card 2: (18,417) 339×205  顶部 padding=19  行高 49
    UIView *c2 = [self buildCardAtY:417 height:205 topPad:19 items:self.sections[1] sectionIdx:1];
    [self.view addSubview:c2];
}

- (UIView *)buildCardAtY:(CGFloat)y height:(CGFloat)h topPad:(CGFloat)topPad items:(NSArray<NSDictionary *> *)items sectionIdx:(NSInteger)section {
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(18), kScaleH(y), kScaleW(339), kScaleH(h))];
    card.backgroundColor = MKHexColor(0xE9E9E4);
    card.layer.cornerRadius = kScaleH(14);
    card.clipsToBounds = YES;

    CGFloat rowH = kScaleH(40);  // 触摸区高度 (覆盖 icon 24 + 上下小间隔)
    for (NSInteger i = 0; i < items.count; i++) {
        // icon y (相对 card): topPad + i*49 - (rowH-24)/2  →  让 icon (24h) 居中于 rowH
        CGFloat iconTopInCard = kScaleH(topPad) + kScaleH(i * 49);
        CGFloat rowY = iconTopInCard - (rowH - kScaleH(24)) * 0.5;
        MKProfileMenuRow *row = [[MKProfileMenuRow alloc] initWithFrame:CGRectMake(0, rowY, card.bounds.size.width, rowH)];
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular];
        UIImage *img = [[UIImage systemImageNamed:items[i][@"symbol"] withConfiguration:cfg]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        row.iconView.image = img;
        row.iconView.tintColor = MKHexColor(0x0D1218);
        row.titleLabel.text = items[i][@"title"];
        row.tag = section * 100 + i;
        [row addTarget:self action:@selector(rowTapped:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:row];
    }
    return card;
}

- (void)rowTapped:(MKProfileMenuRow *)row {
    NSInteger section = row.tag / 100;
    NSInteger idx = row.tag % 100;
    NSString *cls = self.sections[section][idx][@"cls"];
    if ([cls isEqualToString:@"_LOGOUT_"]) {
        MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeLogoutConfirm config:nil];
        __weak typeof(self) wself = self;
        sheet.onConfirmTapped = ^{ [wself performLogout]; };
        [sheet show];
    } else {
        Class c = NSClassFromString(cls);
        if (c) [self.navigationController pushViewController:[c new] animated:YES];
    }
}

#pragma mark - Logout

- (void)performLogout {
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    [SVProgressHUD showWithStatus:@"Signing out..."];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/auth/logout"
                                    params:body
                                   success:^(id resp) {
        NSInteger code = [resp[@"resultCode"] integerValue];
        NSLog(@"[Logout] resp code=%ld msg=%@", (long)code, resp[@"resultMsg"]);
        [[MKLoginManager sharedManager] logout];
        if (code == 200) {
            [SVProgressHUD showSuccessWithStatus:@"Signed out"];
        } else {
            [SVProgressHUD dismiss];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [wself goToSignIn]; });
    } failure:^(NSError *error) {
        NSLog(@"[Logout] network fail, clearing local anyway: %@", error);
        [[MKLoginManager sharedManager] logout];
        [SVProgressHUD dismiss];
        [wself goToSignIn];
    }];
}

- (void)goToSignIn {
    MKSignInViewController *signin = [[MKSignInViewController alloc] init];
    MKNavigationController *nav = [[MKNavigationController alloc] initWithRootViewController:signin];
    UIWindow *win = self.view.window;
    [UIView transitionWithView:win duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ win.rootViewController = nav; }
                    completion:nil];
}

@end
