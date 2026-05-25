//  MKLoanProductHeroView.m
//  PHI372-DC
//  Pencil 坐标 (375 frame, hero 起 y=106). Hero 内 local y = pencil_y - 106.

#import "MKLoanProductHeroView.h"
#import "MKConstants.h"
#import <SDWebImage/SDWebImage.h>

static const CGFloat kY0 = 106.0;

@interface MKLoanProductHeroView ()
@property (nonatomic, assign) MKHeroVariant variant;

@property (nonatomic, strong) UIImageView *iconBox;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UIControl *termCapsule;
@property (nonatomic, strong) UILabel *termLabel;
@property (nonatomic, strong) UIImageView *termCapsuleChevron;
@property (nonatomic, strong) UIControl *amountSubLabel;
@property (nonatomic, strong) UILabel *amountSubText;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UIControl *amountChevron;
@property (nonatomic, strong) UIImageView *moneyBag;
@property (nonatomic, strong) UILabel *statusLabel;  // Compact 右上状态文字 (无背景, 白字)
@end

@implementation MKLoanProductHeroView

+ (CGFloat)heightForVariant:(MKHeroVariant)variant {
    switch (variant) {
        case MKHeroVariantFull:    return kScaleH(244);
        case MKHeroVariantCompact: return kScaleH(171);
        case MKHeroVariantMini:    return kScaleH(144);
    }
}

- (instancetype)initWithVariant:(MKHeroVariant)variant {
    if (self = [super initWithFrame:CGRectZero]) {
        _variant = variant;
        self.backgroundColor = kColorPrimary;
        // Pencil: Full r=24, Compact r=14, Mini r=14
        self.layer.cornerRadius = (variant == MKHeroVariantFull) ? kScaleH(24) : kScaleH(14);
        if (variant == MKHeroVariantFull)         [self buildFull];
        else if (variant == MKHeroVariantCompact) [self buildCompact];
        // TODO: buildMini 在接入还款页时实现
    }
    return self;
}

- (void)buildCompact {
    _iconBox = [UIImageView new];
    _iconBox.backgroundColor = kColorWhite;
    _iconBox.layer.cornerRadius = kScaleH(7);
    _iconBox.layer.masksToBounds = YES;
    _iconBox.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_iconBox];

    _appNameLabel = [UILabel new];
    _appNameLabel.font = kFontRegular(14);
    _appNameLabel.textColor = kColorWhite;
    [self addSubview:_appNameLabel];

    // 右上角状态文字 (无背景, 白字, PingFang SC 14)
    _statusLabel = [UILabel new];
    _statusLabel.font = kFontRegular(14);
    _statusLabel.textColor = kColorWhite;
    _statusLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:_statusLabel];

    // 金额 (大字, 与 Full 共用)
    _amountLabel = [UILabel new];
    _amountLabel.font = [UIFont systemFontOfSize:kScaleW(28) weight:UIFontWeightSemibold];
    _amountLabel.textColor = kColorWhite;
    [self addSubview:_amountLabel];

    // 金额 chevron (仅 isMultiAmount=YES 显示, 待提现态)
    _amountChevron = [UIControl new];
    _amountChevron.backgroundColor = kColorWhite;
    _amountChevron.layer.cornerRadius = kScaleW(18);
    _amountChevron.hidden = YES;
    [_amountChevron addTarget:self action:@selector(amountChevronTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_amountChevron];
    UIImageSymbolConfiguration *bigCfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
    UIImageView *bigChevronIcon = [[UIImageView alloc] initWithImage:
                                   [[UIImage systemImageNamed:@"chevron.right" withConfiguration:bigCfg]
                                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    bigChevronIcon.tintColor = kColorPrimary;
    bigChevronIcon.contentMode = UIViewContentModeCenter;
    bigChevronIcon.tag = 8810;
    bigChevronIcon.userInteractionEnabled = NO;
    [_amountChevron addSubview:bigChevronIcon];

    // term 椭圆胶囊 (深绿底 #252F2C, 白字)
    _termCapsule = [UIControl new];
    _termCapsule.backgroundColor = MKHexColor(0x252F2C);
    _termCapsule.layer.cornerRadius = kScaleH(17.5);
    [_termCapsule addTarget:self action:@selector(termCapsuleTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_termCapsule];
    _termLabel = [UILabel new];
    _termLabel.font = kFontRegular(14);
    _termLabel.textColor = kColorWhite;
    _termLabel.textAlignment = NSTextAlignmentCenter;
    _termLabel.userInteractionEnabled = NO;
    [_termCapsule addSubview:_termLabel];
    UIImageSymbolConfiguration *smallCfg = [UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightBold];
    UIImage *smallChevron = [[UIImage systemImageNamed:@"chevron.right" withConfiguration:smallCfg]
                              imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _termCapsuleChevron = [[UIImageView alloc] initWithImage:smallChevron];
    _termCapsuleChevron.tintColor = MKHexColor(0x252F2C);
    _termCapsuleChevron.contentMode = UIViewContentModeCenter;
    _termCapsuleChevron.backgroundColor = kColorWhite;
    _termCapsuleChevron.layer.cornerRadius = kScaleW(10);
    _termCapsuleChevron.hidden = YES;
    _termCapsuleChevron.userInteractionEnabled = NO;
    [_termCapsule addSubview:_termCapsuleChevron];
}

- (void)buildFull {
    _iconBox = [UIImageView new];
    _iconBox.backgroundColor = kColorWhite;
    _iconBox.layer.cornerRadius = kScaleH(7);
    _iconBox.layer.masksToBounds = YES;
    _iconBox.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_iconBox];

    _appNameLabel = [UILabel new];
    _appNameLabel.font = kFontRegular(14);
    _appNameLabel.textColor = kColorWhite;
    [self addSubview:_appNameLabel];

    _termCapsule = [UIControl new];
    _termCapsule.backgroundColor = kColorPrimaryDark;
    _termCapsule.layer.cornerRadius = kScaleH(17.5);
    [_termCapsule addTarget:self action:@selector(termCapsuleTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_termCapsule];

    _termLabel = [UILabel new];
    _termLabel.font = kFontRegular(14);
    _termLabel.textColor = kColorWhite;
    _termLabel.textAlignment = NSTextAlignmentCenter;
    _termLabel.userInteractionEnabled = NO;
    [_termCapsule addSubview:_termLabel];

    UIImageSymbolConfiguration *smallCfg = [UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightBold];
    UIImage *smallChevron = [[UIImage systemImageNamed:@"chevron.right" withConfiguration:smallCfg]
                              imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _termCapsuleChevron = [[UIImageView alloc] initWithImage:smallChevron];
    _termCapsuleChevron.tintColor = kColorPrimary;
    _termCapsuleChevron.contentMode = UIViewContentModeCenter;
    _termCapsuleChevron.backgroundColor = kColorWhite;
    _termCapsuleChevron.layer.cornerRadius = kScaleW(10);
    _termCapsuleChevron.hidden = YES;
    _termCapsuleChevron.userInteractionEnabled = NO;
    [_termCapsule addSubview:_termCapsuleChevron];

    _amountSubLabel = [UIControl new];
    [_amountSubLabel addTarget:self action:@selector(amountSubTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_amountSubLabel];

    _amountSubText = [UILabel new];
    _amountSubText.font = kFontRegular(14);
    _amountSubText.textColor = [kColorWhite colorWithAlphaComponent:0.45];
    _amountSubText.userInteractionEnabled = NO;
    [_amountSubLabel addSubview:_amountSubText];

    // Pencil eQqbA: Inter 28 / 600. 原稿 #000000, 实际深绿底用白
    _amountLabel = [UILabel new];
    _amountLabel.font = [UIFont systemFontOfSize:kScaleW(28) weight:UIFontWeightSemibold];
    _amountLabel.textColor = kColorWhite;
    [self addSubview:_amountLabel];

    _amountChevron = [UIControl new];
    _amountChevron.backgroundColor = kColorWhite;
    _amountChevron.layer.cornerRadius = kScaleW(18);
    _amountChevron.hidden = YES;
    [_amountChevron addTarget:self action:@selector(amountChevronTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_amountChevron];

    UIImageSymbolConfiguration *bigCfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
    UIImageView *amountChevronIcon = [[UIImageView alloc] initWithImage:
                                      [[UIImage systemImageNamed:@"chevron.right" withConfiguration:bigCfg]
                                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    amountChevronIcon.tintColor = kColorPrimary;
    amountChevronIcon.contentMode = UIViewContentModeCenter;
    amountChevronIcon.tag = 8810;
    amountChevronIcon.userInteractionEnabled = NO;
    [_amountChevron addSubview:amountChevronIcon];

    _moneyBag = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mk_money_bag"]];
    _moneyBag.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_moneyBag];
}

- (void)configureAppName:(NSString *)appName
                termText:(NSString *)termText
              amountText:(NSString *)amountText
              subLabel:(NSString *)subLabel {
    self.appNameLabel.text = appName.length > 0 ? appName : @"APPname";
    self.termLabel.text = termText.length > 0 ? termText : @"-- Days";
    self.amountLabel.text = amountText.length > 0 ? amountText : @"--";
    self.amountSubText.text = subLabel.length > 0 ? subLabel : @"loan amount";
    [self setNeedsLayout];
}

- (void)configureCompactAppName:(NSString *)appName
                       termText:(NSString *)termText
                     amountText:(NSString *)amountText
                     statusText:(NSString *)statusText {
    self.appNameLabel.text = appName.length > 0 ? appName : @"APPname";
    self.termLabel.text    = termText.length > 0 ? termText : @"-- Days";
    self.amountLabel.text  = amountText.length > 0 ? amountText : @"--";
    self.statusLabel.text  = statusText ?: @"";
    [self setNeedsLayout];
}

- (void)setProductLogoURL:(NSString *)urlStr {
    if (urlStr.length == 0) { _iconBox.image = nil; return; }
    [_iconBox sd_setImageWithURL:[NSURL URLWithString:urlStr]];
}

- (void)setIsMultiAmount:(BOOL)isMultiAmount {
    _isMultiAmount = isMultiAmount;
    [self setNeedsLayout];
}

- (void)setIsMultiTerm:(BOOL)isMultiTerm {
    _isMultiTerm = isMultiTerm;
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.variant == MKHeroVariantFull)         [self layoutFull];
    else if (self.variant == MKHeroVariantCompact) [self layoutCompact];
}

- (void)layoutCompact {
    // Pencil cpq29 实测 (hero abs y=112, 内部坐标 = abs - hero origin):
    //   icon       abs (34,126) 24x24   → 内 (16,14)
    //   appName    abs (67,131)         → 内 (49,19)
    //   status     abs (253,131) 右上    → 内 (235,19)
    //   amount     abs (34,164) 大字    → 内 (16,52)
    //   termPill   abs (254,168) 90x35  → 内 (236,56)
    //   pill text  abs (269,179)        → 内 (251,67) — pill 内部居中
    self.iconBox.frame      = CGRectMake(kScaleW(16), kScaleH(14), kScaleW(24), kScaleW(24));
    self.appNameLabel.frame = CGRectMake(kScaleW(49), kScaleH(15), kScaleW(170), kScaleH(20));
    self.statusLabel.frame  = CGRectMake(kScaleW(180), kScaleH(15), kScaleW(143), kScaleH(20));

    // 金额 (₱ 50,000) y=52
    self.amountLabel.frame = CGRectMake(kScaleW(16), kScaleH(52), kScaleW(200), kScaleH(42));

    // 金额 chevron (isMultiAmount → 待提现态显示, 紧贴金额右侧)
    self.amountChevron.hidden = !self.isMultiAmount;
    if (self.isMultiAmount) {
        // Pencil b5RSzJ chevron 36×36 圆, 紧贴 amount 右
        self.amountChevron.frame = CGRectMake(kScaleW(155), kScaleH(55), kScaleW(36), kScaleW(36));
        UIImageView *icon = (UIImageView *)[self.amountChevron viewWithTag:8810];
        icon.frame = self.amountChevron.bounds;
    }

    // term capsule 90×35, 内 (236,56); 含 chevron 时宽 107
    CGFloat capsuleW = self.isMultiTerm ? kScaleW(107) : kScaleW(90);
    CGFloat capsuleH = kScaleH(35);
    CGFloat capsuleX = self.isMultiTerm ? kScaleW(219) : kScaleW(236);
    self.termCapsule.frame = CGRectMake(capsuleX, kScaleH(56), capsuleW, capsuleH);
    self.termCapsuleChevron.hidden = !self.isMultiTerm;
    if (self.isMultiTerm) {
        self.termCapsuleChevron.frame = CGRectMake(capsuleW - kScaleW(26),
                                                    (capsuleH - kScaleW(20)) * 0.5,
                                                    kScaleW(20), kScaleW(20));
        self.termLabel.frame = CGRectMake(0, 0, capsuleW - kScaleW(30), capsuleH);
    } else {
        self.termLabel.frame = self.termCapsule.bounds;
    }
}

- (void)layoutFull {
    // Pencil 坐标都是相对 375 frame, hero 在 (18, 106). hero 内 x' = pencil_x - 18, y' = pencil_y - 106
    self.iconBox.frame      = CGRectMake(kScaleW(35 - 18), kScaleH(119 - kY0), kScaleW(24), kScaleW(24));
    self.appNameLabel.frame = CGRectMake(kScaleW(68 - 18), kScaleH(124 - kY0), kScaleW(120), kScaleH(20));

    // term capsule: chevron 独立按 isMultiTerm 控制
    CGFloat capsuleW = self.isMultiTerm ? kScaleW(107) : kScaleW(84);
    CGFloat capsuleH = kScaleH(35);
    CGFloat capsuleRight = kScaleW(349 - 18);
    self.termCapsule.frame = CGRectMake(capsuleRight - capsuleW, kScaleH(118 - kY0), capsuleW, capsuleH);

    self.termCapsuleChevron.hidden = !self.isMultiTerm;
    if (self.isMultiTerm) {
        self.termCapsuleChevron.frame = CGRectMake(capsuleW - kScaleW(26),
                                                    (capsuleH - kScaleW(20)) * 0.5,
                                                    kScaleW(20), kScaleW(20));
        self.termLabel.frame = CGRectMake(0, 0, capsuleW - kScaleW(30), capsuleH);
    } else {
        self.termLabel.frame = self.termCapsule.bounds;
    }

    self.amountSubLabel.frame = CGRectMake(kScaleW(35 - 18), kScaleH(159 - kY0), kScaleW(280), kScaleH(20));
    self.amountSubText.frame  = self.amountSubLabel.bounds;
    self.amountLabel.frame    = CGRectMake(kScaleW(35 - 18), kScaleH(182 - kY0), kScaleW(240), kScaleH(42));

    self.amountChevron.hidden = !self.isMultiAmount;
    if (self.isMultiAmount) {
        self.amountChevron.frame = CGRectMake(kScaleW(181 - 18), kScaleH(185 - kY0),
                                              kScaleW(36), kScaleW(36));
        UIImageView *icon = (UIImageView *)[self.amountChevron viewWithTag:8810];
        icon.frame = self.amountChevron.bounds;
    }

    self.moneyBag.frame = CGRectMake(kScaleW(291 - 18), kScaleH(173 - kY0), kScaleW(56), kScaleH(51));
}

#pragma mark - Actions

- (void)termCapsuleTap {
    if (self.isMultiTerm && self.onTermCapsuleTapped) self.onTermCapsuleTapped();
}
- (void)amountChevronTap {
    if (self.onAmountChevronTapped) self.onAmountChevronTapped();
}
- (void)amountSubTap {
    if (self.onAmountSubLabelTapped) self.onAmountSubLabelTapped(self.amountSubLabel);
}

@end
