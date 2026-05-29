//  MKHomeProductCardView.m

#import "MKHomeProductCardView.h"
#import "MKConstants.h"
#import "UIImageView+MKProductLogo.h"

#define S(v) ((v) * kScale)

@interface MKHomeProductCardView ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *quotaValueLabel;
@property (nonatomic, strong) UILabel *rateValueLabel;
@property (nonatomic, strong) UIImageView *logoView;   // 占 Pencil 左下色块位置 (28×28 r=8)
@end

@implementation MKHomeProductCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kColorCardSecondary;
        self.alpha = 0.8;
        self.layer.cornerRadius = S(14);
        [self setupContent];
    }
    return self;
}

- (void)setupContent {
    // 左下 logo 位 (Pencil Hg6T2: 28×28 cornerRadius 8 fill #385330 at 相对卡 (17, 81))
    // Pencil 上是死色块, 实际渲染走接口 productLogo URL
    self.logoView = [[UIImageView alloc] initWithFrame:CGRectMake(S(17), S(81), S(28), S(28))];
    self.logoView.backgroundColor = kColorPrimary;       // 加载完成前 / 无 URL 的 fallback 色块
    self.logoView.contentMode = UIViewContentModeScaleAspectFill;
    self.logoView.clipsToBounds = YES;
    self.logoView.layer.cornerRadius = S(8);
    [self addSubview:self.logoView];

    // 产品名 (65,87)
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(S(47), S(87), S(120), S(16))];
    self.nameLabel.font = kFontRegular(10);
    self.nameLabel.textColor = kColorPrimary;
    self.nameLabel.text = @"Quick Cash";
    [self addSubview:self.nameLabel];

    // Pencil: 卡内 right padding = 9 (卡 339 - text right≈330 = 9)
    // value label right-align, width 给足容纳 "0.0010%" / "₱5,000-₱200,000" 等长字串
    const CGFloat cardW = S(339);
    const CGFloat valueRight = cardW - S(9);
    const CGFloat valueW = S(170);
    const CGFloat valueX = valueRight - valueW;

    // Quota range 标签 (35,20)
    UILabel *qLbl = [[UILabel alloc] initWithFrame:CGRectMake(S(17), S(20), S(120), S(16))];
    qLbl.text = @"Quota range";
    qLbl.font = kFontRegular(13);
    qLbl.textColor = MKHexColor(0xAEAEAE);
    [self addSubview:qLbl];

    self.quotaValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(valueX, S(20), valueW, S(16))];
    self.quotaValueLabel.font = kFontBold(14);
    self.quotaValueLabel.textColor = kColorBlack;
    self.quotaValueLabel.textAlignment = NSTextAlignmentRight;
    self.quotaValueLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.quotaValueLabel.text = @"₱5,000-₱200,000";
    [self addSubview:self.quotaValueLabel];

    // Reference Interest Rate (35,47)
    UILabel *rLbl = [[UILabel alloc] initWithFrame:CGRectMake(S(17), S(47), S(160), S(16))];
    rLbl.text = @"Reference Interest Rate";
    rLbl.font = kFontRegular(13);
    rLbl.textColor = MKHexColor(0xAEAEAE);
    [self addSubview:rLbl];

    self.rateValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(valueX, S(47), valueW, S(16))];
    self.rateValueLabel.font = kFontBold(14);
    self.rateValueLabel.textColor = kColorBlack;
    self.rateValueLabel.textAlignment = NSTextAlignmentRight;
    self.rateValueLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.rateValueLabel.text = @"0.05%";
    [self addSubview:self.rateValueLabel];

    // Apply 按钮 (Pencil: 相对卡 229,76, 92×37, cornerRadius 20)
    UIButton *apply = [UIButton buttonWithType:UIButtonTypeCustom];
    apply.frame = CGRectMake(S(229), S(76), S(92), S(37));
    apply.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    apply.backgroundColor = kColorPrimary;
    apply.layer.cornerRadius = S(20);
    [apply setTitle:@"Apply" forState:UIControlStateNormal];
    [apply setTitleColor:kColorWhite forState:UIControlStateNormal];
    apply.titleLabel.font = kFontSemibold(14);
    [apply addTarget:self action:@selector(applyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:apply];
}

- (void)setProductName:(NSString *)v   { _productName = [v copy]; self.nameLabel.text = v; }
- (void)setQuotaRange:(NSString *)v    { _quotaRange = [v copy]; self.quotaValueLabel.text = v; }
- (void)setInterestRate:(NSString *)v  { _interestRate = [v copy]; self.rateValueLabel.text = v; }

- (void)setLogoUrl:(NSString *)v {
    _logoUrl = [v copy];
    [self.logoView mk_setProductLogoURL:v fallbackColor:kColorPrimary];
}

- (void)applyTapped { if (self.onApplyTapped) self.onApplyTapped(); }

@end
