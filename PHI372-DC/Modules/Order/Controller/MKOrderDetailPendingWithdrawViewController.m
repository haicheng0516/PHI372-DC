//
//  MKOrderDetailPendingWithdrawViewController.m
//  PHI372-DC — Figma 3:761 历史订单-处理中-详情-待提现
//
//  与 Reviewing 同款 hero/detail card, hero 色 = 橙 #FB8E11, 底部 Withdraw 主按钮
//

#import "MKOrderDetailPendingWithdrawViewController.h"
#import "MKConstants.h"
#import "MKOrderHeroCard.h"
#import "MKOrderDetailCard.h"
#import <Masonry/Masonry.h>

@implementation MKOrderDetailPendingWithdrawViewController

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
        m.bottom.equalTo(self.view).offset(-kScaleH(92) - kBottomSafeHeight);
    }];

    CGFloat y = kScaleH(12);

    MKOrderHeroCard *hero = [[MKOrderHeroCard alloc] initWithState:MKOrderHeroStateWithdraw];
    [hero setAppName:@"APPname"];
    [hero setStatusText:@"To be withdrawn"];
    [hero setAmount:@"₱ 50,000"];
    [hero setTermText:@"180 Days"];
    hero.frame = CGRectMake(kScaleW(18), y, kScaleW(339), [MKOrderHeroCard cardHeight]);
    [sv addSubview:hero];
    y += [MKOrderHeroCard cardHeight] + kScaleH(10);

    UIControl *plan = [self buildPlanRowAtY:y];
    [sv addSubview:plan];
    y += kScaleH(56) + kScaleH(10);

    MKOrderDetailCard *detail = [[MKOrderDetailCard alloc] initWithFrame:
        CGRectMake(kScaleW(18), y, kScaleW(339), [MKOrderDetailCard heightForRowCount:5 breakCount:0])];
    detail.cardNumber = @"4523 **** 8451 5238";
    [detail setRows:@[ @[@"Amount received", @"9,900"],
                       @[@"Interest", @"1,440"],
                       @[@"Service fee", @"100"],
                       @[@"Date of application", @"Feb 18, 2026"],
                       @[@"Due date", @"Aug 18, 2026"] ]];
    [sv addSubview:detail];
    y += detail.frame.size.height + kScaleH(16);

    UILabel *hint = [UILabel new];
    hint.text = @"Your application has been approved, please confirm the loan information. We will transfer the money to your bank account immediately.";
    hint.font = kFontRegular(13);
    hint.textColor = MKHexColor(0x999999);
    hint.numberOfLines = 0;
    hint.frame = CGRectMake(kScaleW(17), y, kScreenWidth - kScaleW(34), kScaleH(72));
    [sv addSubview:hint];
    y += kScaleH(72) + kScaleH(20);

    sv.contentSize = CGSizeMake(kScreenWidth, y);

    // Sticky Withdraw button
    UIButton *withdraw = [UIButton buttonWithType:UIButtonTypeCustom];
    withdraw.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(76),
                                  kScaleW(303), kScaleH(56));
    withdraw.backgroundColor = kColorPrimary;
    withdraw.layer.cornerRadius = kScaleH(28);
    [withdraw setTitle:@"Withdraw" forState:UIControlStateNormal];
    [withdraw setTitleColor:kColorWhite forState:UIControlStateNormal];
    withdraw.titleLabel.font = kFontSemibold(16);
    [self.view addSubview:withdraw];
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

@end
