//
//  MKOrderDetailWaitRepayViewController.m
//  PHI372-DC — Figma 3:814 历史订单-处理中-详情-待还款
//
//  hero 棕 #AF5D00, 明细卡含 5+5 行 (中间分割线), 底部双按钮 Repay/Defer
//

#import "MKOrderDetailWaitRepayViewController.h"
#import "MKConstants.h"
#import "MKOrderHeroCard.h"
#import "MKOrderDetailCard.h"
#import "MKOrderRepayViewController.h"
#import <Masonry/Masonry.h>

@implementation MKOrderDetailWaitRepayViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Loan Details";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    UIScrollView *sv = [UIScrollView new];
    sv.backgroundColor = kColorBackground;
    sv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    sv.showsVerticalScrollIndicator = NO;
    [self.view addSubview:sv];
    [sv mas_makeConstraints:^(MASConstraintMaker *m) {
        m.top.equalTo(self.view).offset(kNavBarHeight);
        m.left.right.equalTo(self.view);
        m.bottom.equalTo(self.view).offset(-kScaleH(150) - kBottomSafeHeight);
    }];

    CGFloat y = kScaleH(12);

    MKOrderHeroCard *hero = [[MKOrderHeroCard alloc] initWithState:MKOrderHeroStatePendingRepay];
    [hero setAppName:@"APPname"];
    [hero setStatusText:@"Pending Repayment"];
    [hero setAmount:@"₱ 50,000"];
    [hero setTermText:@"180 Days"];
    hero.frame = CGRectMake(kScaleW(18), y, kScaleW(339), [MKOrderHeroCard cardHeight]);
    [sv addSubview:hero];
    y += [MKOrderHeroCard cardHeight] + kScaleH(10);

    UIControl *plan = [self buildPlanRowAtY:y];
    [sv addSubview:plan];
    y += kScaleH(56) + kScaleH(10);

    // 5+5 rows with break in middle
    NSArray<NSArray<NSString *> *> *rows = @[
        @[@"Amount received", @"9,900"],
        @[@"Interest", @"1,440"],
        @[@"Service fee", @"100"],
        @[@"Date of application", @"Feb 18, 2026"],
        @[@"Due date", @"Aug 18, 2026"],
        @[@"Total repayment", @"9,900"],
        @[@"Amount of deduction", @"0"],
        @[@"Service fee", @"0"],
        @[@"Amount Due", @"11,000"],
        @[@"Deferment charge", @"100"],
    ];
    CGFloat detailH = [MKOrderDetailCard heightForRowCount:rows.count breakCount:1];
    MKOrderDetailCard *detail = [[MKOrderDetailCard alloc] initWithFrame:
        CGRectMake(kScaleW(18), y, kScaleW(339), detailH)];
    detail.cardNumber = @"4523 **** 8451 5238";
    [detail setRows:rows];
    [detail addBreakAfterRowIndex:4];   // 第 5 行(index=4) 之后画分割线
    [sv addSubview:detail];
    y += detailH + kScaleH(16);

    UILabel *hint = [UILabel new];
    hint.text = @"Please repay on time before the due date. Late repayment will incur additional charges and may affect your credit standing.";
    hint.font = kFontRegular(13);
    hint.textColor = MKHexColor(0x999999);
    hint.numberOfLines = 0;
    hint.frame = CGRectMake(kScaleW(17), y, kScreenWidth - kScaleW(34), kScaleH(72));
    [sv addSubview:hint];
    y += kScaleH(72) + kScaleH(20);

    sv.contentSize = CGSizeMake(kScreenWidth, y);

    // Sticky bottom: Repay + Defer (双按钮纵向)
    CGFloat btnY = kScreenHeight - kBottomSafeHeight - kScaleH(76);
    UIButton *defer = [UIButton buttonWithType:UIButtonTypeCustom];
    defer.frame = CGRectMake(kScaleW(36), btnY, kScaleW(303), kScaleH(56));
    defer.backgroundColor = MKHexColor(0xE9E9E4);
    defer.layer.cornerRadius = kScaleH(28);
    [defer setTitle:@"Defer" forState:UIControlStateNormal];
    [defer setTitleColor:kColorPrimary forState:UIControlStateNormal];
    defer.titleLabel.font = kFontSemibold(16);
    [self.view addSubview:defer];

    UIButton *repay = [UIButton buttonWithType:UIButtonTypeCustom];
    repay.frame = CGRectMake(kScaleW(36), btnY - kScaleH(56) - kScaleH(12),
                              kScaleW(303), kScaleH(56));
    repay.backgroundColor = kColorPrimary;
    repay.layer.cornerRadius = kScaleH(28);
    [repay setTitle:@"Repay" forState:UIControlStateNormal];
    [repay setTitleColor:kColorWhite forState:UIControlStateNormal];
    repay.titleLabel.font = kFontSemibold(16);
    [repay addTarget:self action:@selector(repay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:repay];
}

- (UIControl *)buildPlanRowAtY:(CGFloat)y {
    UIControl *c = [[UIControl alloc] initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), kScaleH(56))];
    c.backgroundColor = MKHexColor(0xBBCB2F);
    c.layer.cornerRadius = kScaleH(14);
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(20), 0, kScaleW(200), kScaleH(56))];
    l.text = @"Repayment plan";
    l.font = kFontSemibold(16);
    l.textColor = kColorPrimary;
    [c addSubview:l];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg]
                                                            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    arrow.tintColor = kColorWhite;
    arrow.backgroundColor = kColorPrimary;
    arrow.contentMode = UIViewContentModeCenter;
    arrow.layer.cornerRadius = kScaleW(10);
    arrow.frame = CGRectMake(kScaleW(339) - kScaleW(20) - kScaleW(20), (kScaleH(56) - kScaleW(20)) * 0.5, kScaleW(20), kScaleW(20));
    [c addSubview:arrow];
    return c;
}

- (void)repay {
    [self.navigationController pushViewController:[MKOrderRepayViewController new] animated:YES];
}

@end
