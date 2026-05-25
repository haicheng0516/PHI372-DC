//
//  MKResultView.m
//

#import "MKResultView.h"
#import "MKConstants.h"

@interface MKResultView ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *primaryButton;
@property (nonatomic, strong) UIButton *secondaryButton;
@end

@implementation MKResultView

- (instancetype)initWithKind:(MKResultKind)kind
                       title:(NSString *)title
                    subtitle:(NSString *)subtitle
                primaryTitle:(NSString *)primaryTitle
              secondaryTitle:(NSString *)secondaryTitle {
    if (self = [super init]) {
        self.backgroundColor = kColorBackground;

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:64 weight:UIImageSymbolWeightRegular];
        NSString *symbol; UIColor *tint;
        switch (kind) {
            case MKResultKindSuccess: symbol = @"checkmark.circle.fill"; tint = kColorPrimary; break;
            case MKResultKindFailure: symbol = @"xmark.circle.fill";     tint = kColorError;   break;
            case MKResultKindHint:    symbol = @"exclamationmark.circle.fill"; tint = MKHexColor(0xEB8A54); break;
        }
        _iconView.image = [[UIImage systemImageNamed:symbol withConfiguration:cfg]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _iconView.tintColor = tint;
        [self addSubview:_iconView];

        _titleLabel = [UILabel new];
        _titleLabel.text = title;
        _titleLabel.font = kFontSemibold(22);
        _titleLabel.textColor = MKHexColor(0x171718);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];

        _subtitleLabel = [UILabel new];
        _subtitleLabel.text = subtitle;
        _subtitleLabel.font = kFontRegular(14);
        _subtitleLabel.textColor = MKHexColor(0x666666);
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 0;
        [self addSubview:_subtitleLabel];

        _primaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _primaryButton.backgroundColor = kColorPrimary;
        _primaryButton.layer.cornerRadius = kScaleH(28);
        [_primaryButton setTitle:primaryTitle forState:UIControlStateNormal];
        [_primaryButton setTitleColor:kColorWhite forState:UIControlStateNormal];
        _primaryButton.titleLabel.font = kFontSemibold(16);
        [_primaryButton addTarget:self action:@selector(primaryTap) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_primaryButton];

        if (secondaryTitle.length) {
            _secondaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _secondaryButton.backgroundColor = MKHexColor(0xE9E9E4);
            _secondaryButton.layer.cornerRadius = kScaleH(28);
            [_secondaryButton setTitle:secondaryTitle forState:UIControlStateNormal];
            [_secondaryButton setTitleColor:MKHexColor(0x171718) forState:UIControlStateNormal];
            _secondaryButton.titleLabel.font = kFontSemibold(16);
            [_secondaryButton addTarget:self action:@selector(secondaryTap) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_secondaryButton];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat iconSize = kScaleW(96);
    self.iconView.frame = CGRectMake((W - iconSize) * 0.5, kScaleH(80), iconSize, iconSize);
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.iconView.frame) + kScaleH(24), W, kScaleH(30));

    CGFloat subWidth = W - kScaleW(80);
    CGSize fit = [self.subtitleLabel sizeThatFits:CGSizeMake(subWidth, CGFLOAT_MAX)];
    self.subtitleLabel.frame = CGRectMake(kScaleW(40), CGRectGetMaxY(self.titleLabel.frame) + kScaleH(12),
                                            subWidth, fit.height);

    CGFloat btnW = kScaleW(303);
    CGFloat btnX = (W - btnW) * 0.5;
    CGFloat btnY = self.bounds.size.height - kScaleH(56) - kBottomSafeHeight - kScaleH(24);
    if (self.secondaryButton) {
        self.secondaryButton.frame = CGRectMake(btnX, btnY, btnW, kScaleH(56));
        btnY -= kScaleH(56) + kScaleH(12);
    }
    self.primaryButton.frame = CGRectMake(btnX, btnY, btnW, kScaleH(56));
}

- (void)primaryTap   { if (self.onPrimaryTapped)   self.onPrimaryTapped(); }
- (void)secondaryTap { if (self.onSecondaryTapped) self.onSecondaryTapped(); }
@end
