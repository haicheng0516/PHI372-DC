//  MKLoanInfoCell.m
//  PHI372-DC
//  容器 cell, 组装 3 个可复用子组件 + 本页特有 UI (银行卡子卡 / Disclaimer / Radio+Terms / Apply Now).

#import "MKLoanInfoCell.h"
#import "MKLoanProductHeroView.h"
#import "MKDetailRowsView.h"
#import "MKRepaymentPlanButton.h"
#import "MKLoanProductModel.h"
#import "MKConstants.h"

// 白卡 Pencil y=238 (相对 cell 起 y=106 hero), 即 cell 内 local y = 132
static const CGFloat kWhiteCardLocalY = 132.0;

@interface MKLoanInfoCell ()

@property (nonatomic, strong) MKLoanProductHeroView *hero;
@property (nonatomic, strong) UIView *whiteCard;

// 白卡内
@property (nonatomic, strong) UIControl *accountCard;
@property (nonatomic, strong) UILabel *accountTitle;
@property (nonatomic, strong) UILabel *accountValue;
@property (nonatomic, strong) UIImageView *accountArrow;

@property (nonatomic, strong) MKDetailRowsView *detailRows;
@property (nonatomic, strong) MKRepaymentPlanButton *repaymentBtn;
@property (nonatomic, strong) UILabel *disclaimerLabel;

@property (nonatomic, strong) UIControl *radio;
@property (nonatomic, strong) UIView *radioRing;
@property (nonatomic, strong) UIView *radioMark;
@property (nonatomic, strong) UILabel *termsLabel;
@property (nonatomic, strong) UIControl *applyBtn;

@end

@implementation MKLoanInfoCell

+ (CGFloat)cellHeight {
    return kScaleH(685);   // Apply Now bottom local y=655 + 30 留白
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = kColorBackground;
        self.backgroundColor = kColorBackground;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self buildHero];
        [self buildWhiteCard];
    }
    return self;
}

#pragma mark - Build

- (void)buildHero {
    self.hero = [[MKLoanProductHeroView alloc] initWithVariant:MKHeroVariantFull];
    [self.contentView addSubview:self.hero];

    __weak typeof(self) wself = self;
    self.hero.onTermCapsuleTapped = ^{ if (wself.onTermCapsuleTapped) wself.onTermCapsuleTapped(); };
    self.hero.onAmountChevronTapped = ^{ if (wself.onAmountChevronTapped) wself.onAmountChevronTapped(); };
    self.hero.onAmountSubLabelTapped = ^(UIView *anchor) {
        if (wself.onAmountSubLabelTapped) wself.onAmountSubLabelTapped(anchor);
    };
}

- (void)buildWhiteCard {
    // 奶白大卡 (Pencil HqbxM 339×552 r24 fill #E9E9E4)
    self.whiteCard = [UIView new];
    self.whiteCard.backgroundColor = kColorCardSecondary;
    self.whiteCard.layer.cornerRadius = kScaleH(24);
    self.whiteCard.clipsToBounds = YES;
    [self.contentView addSubview:self.whiteCard];

    [self buildAccountCard];
    [self buildDetailRows];
    [self buildRepaymentBtn];
    [self buildDisclaimer];
    [self buildTermsBar];
}

- (void)buildAccountCard {
    self.accountCard = [UIControl new];
    self.accountCard.backgroundColor = kColorBackground;
    self.accountCard.layer.cornerRadius = kScaleH(14);
    [self.accountCard addTarget:self action:@selector(accountTap) forControlEvents:UIControlEventTouchUpInside];
    [self.whiteCard addSubview:self.accountCard];

    self.accountTitle = [UILabel new];
    self.accountTitle.text = @"Select receiving account";
    self.accountTitle.font = kFontRegular(14);
    self.accountTitle.textColor = MKHexColor(0x999999);
    [self.accountCard addSubview:self.accountTitle];

    self.accountValue = [UILabel new];
    self.accountValue.text = @"Please choose";
    self.accountValue.font = kFontRegular(15);
    self.accountValue.textColor = kColorTextSecondary;
    [self.accountCard addSubview:self.accountValue];

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
    UIImage *rArrow = [[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.accountArrow = [[UIImageView alloc] initWithImage:rArrow];
    self.accountArrow.tintColor = kColorWhite;
    self.accountArrow.backgroundColor = kColorPrimary;
    self.accountArrow.contentMode = UIViewContentModeCenter;
    self.accountArrow.layer.cornerRadius = kScaleW(10);
    [self.accountCard addSubview:self.accountArrow];
}

- (void)buildDetailRows {
    NSArray *configs = @[
        @{ @"label": @"Amount received", @"hasInfo": @YES },
        @{ @"label": @"Interest", @"hasInfo": @YES },
        @{ @"label": @"Service fee", @"hasInfo": @YES },
        @{ @"label": @"Date of application", @"hasInfo": @NO },
        @{ @"label": @"Due date", @"hasInfo": @NO },
    ];
    self.detailRows = [[MKDetailRowsView alloc] initWithRowConfigs:configs];
    __weak typeof(self) wself = self;
    self.detailRows.onInfoTapped = ^(NSInteger row, UIView *anchor) {
        if (wself.onAmountInfoTapped) wself.onAmountInfoTapped(row, anchor);
    };
    [self.whiteCard addSubview:self.detailRows];
}

- (void)buildRepaymentBtn {
    self.repaymentBtn = [[MKRepaymentPlanButton alloc] init];
    [self.repaymentBtn addTarget:self action:@selector(repaymentTap) forControlEvents:UIControlEventTouchUpInside];
    [self.whiteCard addSubview:self.repaymentBtn];
}

- (void)buildDisclaimer {
    self.disclaimerLabel = [UILabel new];
    self.disclaimerLabel.text = @"The results of your credit assessment will determine your loan limit; having good credit can provide you with greater borrowing power.";
    self.disclaimerLabel.font = kFontRegular(14);
    self.disclaimerLabel.textColor = MKHexColor(0x999999);
    self.disclaimerLabel.numberOfLines = 0;
    [self.whiteCard addSubview:self.disclaimerLabel];
}

- (void)buildTermsBar {
    self.radio = [UIControl new];
    [self.radio addTarget:self action:@selector(toggleTerms) forControlEvents:UIControlEventTouchUpInside];
    [self.whiteCard addSubview:self.radio];

    self.radioRing = [UIView new];
    self.radioRing.layer.cornerRadius = kScaleW(8);
    self.radioRing.layer.borderWidth = 1;
    self.radioRing.layer.borderColor = kColorPrimary.CGColor;
    self.radioRing.userInteractionEnabled = NO;
    [self.radio addSubview:self.radioRing];

    self.radioMark = [UIView new];
    self.radioMark.backgroundColor = kColorPrimary;
    self.radioMark.layer.cornerRadius = kScaleW(4);
    self.radioMark.userInteractionEnabled = NO;
    self.radioMark.hidden = NO;   // 默认选中
    _termsAccepted = YES;
    [self.radioRing addSubview:self.radioMark];

    self.termsLabel = [UILabel new];
    self.termsLabel.numberOfLines = 0;
    [self updateTermsLabelText];
    [self.whiteCard addSubview:self.termsLabel];

    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(termsLinkTap)];
    [self.termsLabel addGestureRecognizer:tg];
    self.termsLabel.userInteractionEnabled = YES;

    self.applyBtn = [UIControl new];
    self.applyBtn.backgroundColor = kColorPrimary;
    self.applyBtn.layer.cornerRadius = kScaleH(28);
    [self.applyBtn addTarget:self action:@selector(applyTap) forControlEvents:UIControlEventTouchUpInside];
    [self.whiteCard addSubview:self.applyBtn];

    UILabel *applyText = [UILabel new];
    applyText.text = @"Apply Now";
    applyText.font = kFontButtonLarge;
    applyText.textColor = kColorWhite;
    applyText.textAlignment = NSTextAlignmentCenter;
    applyText.tag = 1801;
    [self.applyBtn addSubview:applyText];
}

- (void)updateTermsLabelText {
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"I have read and agreed with the Terms of the loans"
                                                                            attributes:@{ NSFontAttributeName: kFontRegular(14),
                                                                                          NSForegroundColorAttributeName: MKHexColor(0x999999) }];
    NSRange linkRange = [str.string rangeOfString:@"Terms of the loans"];
    if (linkRange.location != NSNotFound) {
        [str addAttribute:NSForegroundColorAttributeName value:kColorPrimary range:linkRange];
        [str addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:linkRange];
    }
    self.termsLabel.attributedText = str;
}

#pragma mark - Configure

- (void)configureWithProduct:(MKLoanProductModel *)product {
    self.hero.isMultiAmount = product.isMultiAmount;
    self.hero.isMultiTerm = product.isMultiTerm;
    [self.hero setProductLogoURL:product.productLogo];
    [self.hero configureAppName:product.productName
                       termText:product.termText
                     amountText:product.displayAmount
                     subLabel:product.amountSubLabel];

    if (product.bankAccount.length > 0) {
        self.accountValue.text = product.bankAccount;
        self.accountValue.textColor = kColorTextPrimary;
    } else {
        self.accountValue.text = @"Please choose";
        self.accountValue.textColor = kColorTextSecondary;
    }

    [self.detailRows setValues:@[
        product.arrivalAmount ?: @"--",
        product.interestAmount ?: @"--",
        product.feeAmount ?: @"--",
        product.borrowingDate ?: @"--",
        product.repaymentDate ?: @"--"
    ]];

    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    // Hero (Pencil 18,106 339×244, cell local 18,0)
    self.hero.frame = CGRectMake(kScaleW(18), 0, kScaleW(339),
                                  [MKLoanProductHeroView heightForVariant:MKHeroVariantFull]);

    // 奶白大卡
    self.whiteCard.frame = CGRectMake(kScaleW(18), kScaleH(kWhiteCardLocalY),
                                       kScaleW(339), kScaleH(552));

    // 以下都是白卡内坐标 (x' = pencil_x - 18, y' = pencil_y - 238)

    // Account card (Pencil 36,257 303×75)
    self.accountCard.frame = CGRectMake(kScaleW(18), kScaleH(19), kScaleW(303), kScaleH(75));
    self.accountTitle.frame = CGRectMake(kScaleW(11), kScaleH(12), kScaleW(280), kScaleH(20));
    self.accountValue.frame = CGRectMake(kScaleW(11), kScaleH(40), kScaleW(240), kScaleH(20));
    self.accountArrow.frame = CGRectMake(kScaleW(303 - 31), (kScaleH(75) - kScaleW(20)) * 0.5,
                                         kScaleW(20), kScaleW(20));

    // Detail rows (Pencil 36,350~493 303×143)
    self.detailRows.frame = CGRectMake(kScaleW(18), kScaleH(350 - 238),
                                       kScaleW(303),
                                       [MKDetailRowsView viewHeightForCount:5]);

    // Repayment btn (Pencil 36,515 303×56)
    self.repaymentBtn.frame = CGRectMake(kScaleW(18), kScaleH(515 - 238),
                                          kScaleW(303), [MKRepaymentPlanButton buttonHeight]);

    // Disclaimer (Pencil 36,586 303×54)
    self.disclaimerLabel.frame = CGRectMake(kScaleW(18), kScaleH(586 - 238),
                                             kScaleW(303), kScaleH(54));

    // Radio (Pencil 36,664 16×16)
    self.radio.frame = CGRectMake(kScaleW(18), kScaleH(664 - 238), kScaleW(16), kScaleW(16));
    self.radioRing.frame = self.radio.bounds;
    CGFloat ms = kScaleW(8);
    self.radioMark.frame = CGRectMake((self.radio.bounds.size.width - ms) * 0.5,
                                      (self.radio.bounds.size.height - ms) * 0.5,
                                      ms, ms);

    // Terms label (Pencil 58,662 267×36)
    self.termsLabel.frame = CGRectMake(kScaleW(40), kScaleH(662 - 238),
                                        kScaleW(267), kScaleH(36));

    // Apply Now (Pencil 36,705 303×56)
    self.applyBtn.frame = CGRectMake(kScaleW(18), kScaleH(705 - 238),
                                      kScaleW(303), kScaleH(56));
    UILabel *applyText = (UILabel *)[self.applyBtn viewWithTag:1801];
    applyText.frame = self.applyBtn.bounds;
}

#pragma mark - Actions

- (void)accountTap { if (self.onAccountTapped) self.onAccountTapped(); }
- (void)repaymentTap { if (self.onRepaymentPlanTapped) self.onRepaymentPlanTapped(); }
- (void)termsLinkTap { if (self.onTermsLinkTapped) self.onTermsLinkTapped(); }
- (void)applyTap { if (self.onApplyTapped) self.onApplyTapped(); }

- (void)toggleTerms {
    _termsAccepted = !_termsAccepted;
    self.radioMark.hidden = !_termsAccepted;
}

@end
