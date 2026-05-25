#import "MKOrderSubmitViewController.h"
#import "MKConstants.h"
#import "MKOrderListViewController.h"

@implementation MKOrderSubmitViewController
- (instancetype)init { if (self = [super init]) { self.navBarStyle = MKNavBarStyleLight; self.navTitle = @"Submitted"; } return self; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    UIView *ic = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth - kScaleW(96)) * 0.5, kNavBarHeight + kScaleH(80), kScaleW(96), kScaleW(96))];
    ic.backgroundColor = kColorPrimary; ic.layer.cornerRadius = kScaleW(48);
    [self.view addSubview:ic];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, kNavBarHeight + kScaleH(196), kScreenWidth, kScaleH(34))];
    t.text = @"Application Submitted"; t.font = kFontBold(22); t.textColor = kColorTextPrimary; t.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:t];

    UILabel *d = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(40), kNavBarHeight + kScaleH(240), kScreenWidth - kScaleW(80), kScaleH(60))];
    d.text = @"Your application is being reviewed. We will notify you within 30 minutes."; d.font = kFontRegular(14); d.textColor = kColorTextSecondary; d.numberOfLines = 0; d.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:d];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(76), kScaleW(303), kScaleH(56));
    btn.backgroundColor = kColorPrimary; btn.layer.cornerRadius = kScaleH(28);
    [btn setTitle:@"View Order" forState:UIControlStateNormal];
    [btn setTitleColor:kColorWhite forState:UIControlStateNormal];
    btn.titleLabel.font = kFontButtonLarge;
    [btn addTarget:self action:@selector(goToOrderList) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)goToOrderList { [self.navigationController pushViewController:[[MKOrderListViewController alloc] initWithTab:MKOrderListTabProcessing] animated:YES]; }
@end
