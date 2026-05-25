//
//  MKOrderDetailReviewingViewController.m
//  PHI372-DC — Figma 3:719 历史订单-处理中-详情-审核中
//
//  布局: 顶部 484pt 绿渐变 + 标题 "Loan Details" + Hero 卡(绿 #11722E) + Repayment plan 行 +
//         明细卡(6 行) + 底部 hint 长段 + (无 CTA)
//

#import "MKOrderDetailReviewingViewController.h"
#import "MKConstants.h"
#import "MKOrderHeroCard.h"
#import "MKOrderDetailCard.h"
#import <Masonry/Masonry.h>

@implementation MKOrderDetailReviewingViewController

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
        m.left.right.bottom.equalTo(self.view);
    }];

    CGFloat y = kScaleH(12);

    // Hero (figma 18,112 → y=0 of scroll content offset 12)
    MKOrderHeroCard *hero = [[MKOrderHeroCard alloc] initWithState:MKOrderHeroStateReviewing];
    [hero setAppName:@"APPname"];
    [hero setStatusText:@"Under review"];
    [hero setAmount:@"₱ 50,000"];
    [hero setTermText:@"180 Days"];
    hero.frame = CGRectMake(kScaleW(18), y, kScaleW(339), [MKOrderHeroCard cardHeight]);
    [sv addSubview:hero];
    y += [MKOrderHeroCard cardHeight] + kScaleH(10);

    // Repayment plan 行 (yellow-green)
    UIControl *plan = [self buildPlanRowAtY:y];
    [sv addSubview:plan];
    y += kScaleH(56) + kScaleH(10);

    // 明细卡
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

    // Footer hint
    UILabel *hint = [UILabel new];
    hint.text = @"Your application is currently being reviewed. Once approved, the funds will be transferred to your bank account.";
    hint.font = kFontRegular(13);
    hint.textColor = MKHexColor(0x999999);
    hint.numberOfLines = 0;
    hint.frame = CGRectMake(kScaleW(17), y, kScreenWidth - kScaleW(34), kScaleH(72));
    [sv addSubview:hint];
    y += kScaleH(72) + kScaleH(20);

    sv.contentSize = CGSizeMake(kScreenWidth, y + kBottomSafeHeight);
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
