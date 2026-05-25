//
//  MKLoanApplyBottomBar.m
//  PHI372-DC
//

#import "MKLoanApplyBottomBar.h"
#import "MKConstants.h"

// Pencil: radio y=662, apply y=705+56=761 → 跨度 99pt. 加上 上 16/下 16 padding ≈ 131pt (不含 safeArea)
static const CGFloat kBarContentTopY = 16.0;
static const CGFloat kRadioRelY = 6.0;   // Pencil 662 - 区域起 656 = 6
static const CGFloat kTermsRelY = 0.0;
static const CGFloat kApplyRelY = 49.0;  // Pencil 705 - 区域起 656 = 49

@interface MKLoanApplyBottomBar ()
@property (nonatomic, strong) UIControl *radio;
@property (nonatomic, strong) UIView *radioRing;
@property (nonatomic, strong) UIView *radioMark;
@property (nonatomic, strong) UILabel *termsLabel;
@property (nonatomic, strong) UIControl *applyBtn;
@end

@implementation MKLoanApplyBottomBar

+ (CGFloat)barHeight {
    return kScaleH(kBarContentTopY + kApplyRelY + 56 + 16);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = kColorBackground;
        [self build];
    }
    return self;
}

- (void)build {
    // Radio
    _radio = [UIControl new];
    [_radio addTarget:self action:@selector(toggleTerms) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_radio];

    _radioRing = [[UIView alloc] init];
    _radioRing.layer.cornerRadius = kScaleW(8);
    _radioRing.layer.borderWidth = 1;
    _radioRing.layer.borderColor = kColorPrimary.CGColor;
    _radioRing.userInteractionEnabled = NO;
    [_radio addSubview:_radioRing];

    _radioMark = [[UIView alloc] init];
    _radioMark.backgroundColor = kColorPrimary;
    _radioMark.layer.cornerRadius = kScaleW(4);
    _radioMark.userInteractionEnabled = NO;
    _radioMark.hidden = YES;
    [_radioRing addSubview:_radioMark];

    // Terms (整段 label, 内有可点击的 Terms 链接)
    _termsLabel = [UILabel new];
    _termsLabel.numberOfLines = 0;
    [self updateTermsLabel];
    [self addSubview:_termsLabel];

    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(termsTap)];
    [_termsLabel addGestureRecognizer:tg];
    _termsLabel.userInteractionEnabled = YES;

    // Apply Now
    _applyBtn = [UIControl new];
    _applyBtn.backgroundColor = kColorPrimary;
    _applyBtn.layer.cornerRadius = kScaleH(28);
    [_applyBtn addTarget:self action:@selector(applyTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_applyBtn];

    UILabel *applyLabel = [UILabel new];
    applyLabel.text = @"Apply Now";
    applyLabel.font = kFontButtonLarge;
    applyLabel.textColor = kColorWhite;
    applyLabel.textAlignment = NSTextAlignmentCenter;
    applyLabel.tag = 701;
    [_applyBtn addSubview:applyLabel];
}

- (void)updateTermsLabel {
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"I have read and agreed with the Terms of the loans"
                                                                              attributes:@{ NSFontAttributeName: kFontRegular(12),
                                                                                            NSForegroundColorAttributeName: MKHexColor(0x999999) }];
    NSRange linkRange = [str.string rangeOfString:@"Terms of the loans"];
    if (linkRange.location != NSNotFound) {
        [str addAttribute:NSForegroundColorAttributeName value:kColorPrimary range:linkRange];
        [str addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:linkRange];
    }
    self.termsLabel.attributedText = str;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat topPad = kScaleH(kBarContentTopY);

    self.radio.frame = CGRectMake(kScaleW(36), topPad + kScaleH(kRadioRelY),
                                  kScaleW(16), kScaleW(16));
    self.radioRing.frame = self.radio.bounds;
    CGFloat ms = kScaleW(8);
    self.radioMark.frame = CGRectMake((self.radio.bounds.size.width - ms) * 0.5,
                                      (self.radio.bounds.size.height - ms) * 0.5,
                                      ms, ms);

    self.termsLabel.frame = CGRectMake(kScaleW(58), topPad + kScaleH(kTermsRelY),
                                       kScaleW(280), kScaleH(36));

    self.applyBtn.frame = CGRectMake(kScaleW(36), topPad + kScaleH(kApplyRelY),
                                     kScaleW(303), kScaleH(56));
    UILabel *al = (UILabel *)[self.applyBtn viewWithTag:701];
    al.frame = self.applyBtn.bounds;
}

- (void)setTermsAccepted:(BOOL)termsAccepted {
    _termsAccepted = termsAccepted;
    self.radioMark.hidden = !termsAccepted;
}

#pragma mark - Actions

- (void)toggleTerms {
    self.termsAccepted = !self.termsAccepted;
    if (self.onCheckboxTapped) self.onCheckboxTapped();
}

- (void)termsTap { if (self.onTermsTapped) self.onTermsTapped(); }

- (void)applyTap { if (self.onApplyTapped) self.onApplyTapped(); }

@end
