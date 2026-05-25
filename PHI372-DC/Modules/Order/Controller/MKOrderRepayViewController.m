//
//  MKOrderRepayViewController.m
//  PHI372-DC — Figma 3:869 历史订单-处理中-详情-待还款-还款 (Bill / Dragonpay 引导)
//
//  布局精确还原 (375×812):
//    顶部 484pt 绿渐变 (与 Loan Details 同款) + 品牌绿 nav
//    标题 "Repayment"
//    Amount 卡 (18,112) 339×144 灰底 r=14 #E9E9E4
//      - 顶部深绿块 (12,63) 315×66 #385330 r=14 含: ₱ 50,000 大字 (黑) + copy 图标
//      - 底部 "Dragonpay" 14pt center #999999
//    Bill 区块 1 (18,268) 339×195 浅灰 80% r=14
//      - "BILL" 标签 (26,18) 14pt UPPER rgba(white,0.5)
//      - "3454 2283 5969 4859" 卡号 14pt white
//      - 说明文本 (21,115) 292×54 12pt
//    Bill 区块 2 (18,475) 339×199 浅灰 80% r=14
//      - 银行/线下说明 (21, 35) 292×90 12pt
//      - 备注长文 (19, 16/176) 292×162 12pt #666666
//

#import "MKOrderRepayViewController.h"
#import "MKConstants.h"
#import "MKBottomSheetView.h"
#import <Masonry/Masonry.h>

@implementation MKOrderRepayViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Repayment";
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

    // Amount 卡 (灰底 + 内嵌深绿块 + ₱ 大字 + Dragonpay)
    UIView *amountCard = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), kScaleH(144))];
    amountCard.backgroundColor = MKHexColor(0xE9E9E4);
    amountCard.layer.cornerRadius = kScaleH(14);
    [sv addSubview:amountCard];

    // 内嵌深绿块: ₱ 50,000 + copy icon
    UIView *amountBg = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(12), kScaleH(8), kScaleW(315), kScaleH(66))];
    amountBg.backgroundColor = kColorPrimary;
    amountBg.layer.cornerRadius = kScaleH(14);
    [amountCard addSubview:amountBg];

    UILabel *amount = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(20), 0, kScaleW(200), kScaleH(66))];
    amount.text = @"₱ 50,000";
    amount.font = [UIFont systemFontOfSize:kScaleW(28) weight:UIFontWeightBold];
    amount.textColor = MKHexColor(0x000000);
    [amountBg addSubview:amount];

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular];
    UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [copyBtn setImage:[[UIImage systemImageNamed:@"doc.on.doc" withConfiguration:cfg]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
              forState:UIControlStateNormal];
    copyBtn.tintColor = kColorWhite;
    copyBtn.frame = CGRectMake(kScaleW(282), kScaleH(21), kScaleW(24), kScaleW(24));
    [copyBtn addTarget:self action:@selector(copyAmount) forControlEvents:UIControlEventTouchUpInside];
    [amountBg addSubview:copyBtn];

    // Dragonpay 标签
    UILabel *dragonpay = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(110), kScaleW(339), kScaleH(20))];
    dragonpay.text = @"Dragonpay";
    dragonpay.font = kFontRegular(14);
    dragonpay.textColor = MKHexColor(0x999999);
    dragonpay.textAlignment = NSTextAlignmentCenter;
    [amountCard addSubview:dragonpay];

    y += kScaleH(144) + kScaleH(12);

    // Bill 区块 1
    UIView *bill1 = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), kScaleH(195))];
    bill1.backgroundColor = [MKHexColor(0xE9E9E4) colorWithAlphaComponent:0.8];
    bill1.layer.cornerRadius = kScaleH(14);
    [sv addSubview:bill1];

    // 深绿块 within bill1 (top section)
    UIView *bill1Header = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(12), kScaleH(8), kScaleW(315), kScaleH(66))];
    bill1Header.backgroundColor = kColorPrimary;
    bill1Header.layer.cornerRadius = kScaleH(14);
    [bill1 addSubview:bill1Header];

    UILabel *billLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(14), kScaleH(8), kScaleW(60), kScaleH(20))];
    billLabel.text = @"BILL";
    billLabel.font = kFontRegular(14);
    billLabel.textColor = [kColorWhite colorWithAlphaComponent:0.5];
    [bill1Header addSubview:billLabel];

    UILabel *refNumber = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(14), kScaleH(32), kScaleW(280), kScaleH(20))];
    refNumber.text = @"3454 2283 5969 4859";
    refNumber.font = kFontRegular(14);
    refNumber.textColor = kColorWhite;
    [bill1Header addSubview:refNumber];

    UILabel *bill1Body = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(15), kScaleH(86), kScaleW(309), kScaleH(99))];
    bill1Body.text = @"You can pay using your e-wallet (GCash, Maya, etc.). Open the e-wallet app, scan or enter the reference number above, and pay the corresponding amount.";
    bill1Body.font = kFontRegular(12);
    bill1Body.textColor = MKHexColor(0x171718);
    bill1Body.numberOfLines = 0;
    [bill1 addSubview:bill1Body];

    y += kScaleH(195) + kScaleH(12);

    // Bill 区块 2
    UIView *bill2 = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), kScaleH(199))];
    bill2.backgroundColor = [MKHexColor(0xE9E9E4) colorWithAlphaComponent:0.8];
    bill2.layer.cornerRadius = kScaleH(14);
    [sv addSubview:bill2];

    UILabel *bill2Body = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(15), kScaleH(18), kScaleW(309), kScaleH(80))];
    bill2Body.text = @"You can also pay at supported convenience stores (7-Eleven, M Lhuillier, Cebuana, Palawan, etc.) or via online banking transfer using the reference number above.";
    bill2Body.font = kFontRegular(12);
    bill2Body.textColor = MKHexColor(0x171718);
    bill2Body.numberOfLines = 0;
    [bill2 addSubview:bill2Body];

    UILabel *bill2Note = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(15), kScaleH(104), kScaleW(309), kScaleH(90))];
    bill2Note.text = @"Note: payment may take 1-3 business days to reflect. Please keep the receipt for verification. Late payments will incur additional service fees according to the loan agreement.";
    bill2Note.font = kFontRegular(12);
    bill2Note.textColor = MKHexColor(0x666666);
    bill2Note.numberOfLines = 0;
    [bill2 addSubview:bill2Note];

    y += kScaleH(199) + kScaleH(20);

    sv.contentSize = CGSizeMake(kScreenWidth, y + kBottomSafeHeight);
}

- (void)copyAmount {
    UIPasteboard.generalPasteboard.string = @"50000";
}

@end
