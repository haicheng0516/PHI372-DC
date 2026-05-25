//
//  MKProductSuccessViewController.m
//  PHI372-DC — Figma Q5IzQ "产品申请-申请成功 –老客"
//
//  模态弹窗 (60% 黑遮罩 + 居中 #f8f8f7 卡片 331×338 r28). Pencil 坐标:
//    Card r5bLG  y=418 h=338 (相对 812 frame, 上下居中)
//    Icon Hluh8  68×60 @ (154, 441) — 卡片内 y=23
//    Title KfCC1 "Success!" 20/PingFangSC center @ y=535 — 卡片内 y=117
//    Body XxOT8  14/PingFangSC #666 (48, 579) w=272 — 卡片内 y=161
//    Button Yt7qi 279×56 r80 #385330 (48, 668) — 卡片内 y=250
//

#import "MKProductSuccessViewController.h"
#import "MKConstants.h"
#import "MKHomeViewController.h"
#import "MKNavigationController.h"

@implementation MKProductSuccessViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Pencil NkYnW: 全屏 60% 黑遮罩
    self.view.backgroundColor = MKColorAlpha(0, 0, 0, 0.6);

    // Pencil r5bLG: 卡片 331×338 r28 #f8f8f7, 屏内上下居中
    CGFloat cardW = kScaleW(331);
    CGFloat cardH = kScaleH(338);
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth - cardW) * 0.5,
                                                              (kScreenHeight - cardH) * 0.5,
                                                              cardW, cardH)];
    card.backgroundColor = MKHexColor(0xF8F8F7);
    card.layer.cornerRadius = kScaleW(28);
    [self.view addSubview:card];

    // Pencil Hluh8: Se_success icon 68×60 卡片内 y=23
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mk_result_success"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.frame = CGRectMake((cardW - kScaleW(68)) * 0.5, kScaleH(23), kScaleW(68), kScaleH(60));
    // 资源 fallback: 用绿色圆 + 白勾绘制
    if (!icon.image) {
        icon.backgroundColor = kColorPrimary;
        icon.layer.cornerRadius = kScaleW(30);
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightBold];
        UIImageView *check = [[UIImageView alloc] initWithImage:
                              [[UIImage systemImageNamed:@"checkmark" withConfiguration:cfg]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        check.tintColor = kColorWhite;
        check.frame = CGRectMake(0, 0, kScaleW(68), kScaleH(60));
        check.contentMode = UIViewContentModeCenter;
        [icon addSubview:check];
    }
    [card addSubview:icon];

    // Pencil KfCC1: "Success!" 20/PingFangSC 卡片内 y=117
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(117), cardW, kScaleH(28))];
    title.text = @"Success!";
    title.font = [UIFont systemFontOfSize:kScaleW(20) weight:UIFontWeightSemibold];
    title.textColor = MKHexColor(0x171718);
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];

    // Pencil XxOT8: body 14/PingFangSC #666 卡片内 (26, 161) w=279 (272 + 6 微调)
    UILabel *body = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(26), kScaleH(161),
                                                                cardW - kScaleW(52), kScaleH(63))];
    body.text = @"Your application is under review. Once approved, the money will be credited to your bank account.";
    body.font = kFontRegular(14);
    body.textColor = MKHexColor(0x666666);
    body.textAlignment = NSTextAlignmentCenter;
    body.numberOfLines = 0;
    [card addSubview:body];

    // Pencil Yt7qi: Confirm 279×56 r28 #385330 卡片内 y=250
    UIControl *btn = [UIControl new];
    btn.frame = CGRectMake((cardW - kScaleW(279)) * 0.5, kScaleH(250), kScaleW(279), kScaleH(56));
    btn.backgroundColor = kColorPrimary;
    btn.layer.cornerRadius = kScaleH(28);
    [btn addTarget:self action:@selector(confirmTap) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:btn];

    UILabel *btnText = [[UILabel alloc] initWithFrame:btn.bounds];
    btnText.text = @"Confirm";
    btnText.textColor = kColorWhite;
    btnText.textAlignment = NSTextAlignmentCenter;
    btnText.font = [UIFont systemFontOfSize:kScaleW(16) weight:UIFontWeightSemibold];
    [btn addSubview:btnText];
}

- (void)confirmTap {
    // dismiss 自身, 然后 pop 到 home (presenter 是 LoanDetails, 它的 nav root 是 home)
    UIViewController *presenter = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        UINavigationController *nav = presenter.navigationController ?: (UINavigationController *)presenter;
        [nav popToRootViewControllerAnimated:YES];
    }];
}

@end
