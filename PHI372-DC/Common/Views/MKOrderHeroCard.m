//
//  MKOrderHeroCard.m
//

#import "MKOrderHeroCard.h"
#import "MKConstants.h"

@interface MKOrderHeroCard ()
@property (nonatomic, strong) UIView *iconBox;
@property (nonatomic, strong) UILabel *appLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UIView *termPill;
@property (nonatomic, strong) UILabel *termLabel;
@end

@implementation MKOrderHeroCard

+ (CGFloat)cardHeight { return kScaleH(171); }

- (instancetype)initWithState:(MKOrderHeroState)state {
    if (self = [super init]) {
        self.layer.cornerRadius = kScaleH(14);
        self.clipsToBounds = YES;
        switch (state) {
            case MKOrderHeroStateReviewing:     self.backgroundColor = MKHexColor(0x11722E); break;
            case MKOrderHeroStateWithdraw:      self.backgroundColor = MKHexColor(0xFB8E11); break;
            case MKOrderHeroStatePendingRepay:  self.backgroundColor = MKHexColor(0xAF5D00); break;
            case MKOrderHeroStateCustom:        self.backgroundColor = kColorPrimary; break;
        }

        _iconBox = [UIView new];
        _iconBox.backgroundColor = kColorWhite;
        _iconBox.layer.cornerRadius = kScaleH(7);
        [self addSubview:_iconBox];

        _appLabel = [UILabel new];
        _appLabel.font = kFontRegular(14);
        _appLabel.textColor = kColorWhite;
        [self addSubview:_appLabel];

        _statusLabel = [UILabel new];
        _statusLabel.font = kFontRegular(14);
        _statusLabel.textColor = kColorWhite;
        _statusLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_statusLabel];

        _amountLabel = [UILabel new];
        _amountLabel.font = [UIFont systemFontOfSize:kScaleW(28) weight:UIFontWeightBold];
        _amountLabel.textColor = kColorWhite;
        [self addSubview:_amountLabel];

        _termPill = [UIView new];
        _termPill.backgroundColor = MKHexColor(0x252F2C);
        _termPill.layer.cornerRadius = kScaleH(17.5);
        [self addSubview:_termPill];

        _termLabel = [UILabel new];
        _termLabel.font = kFontRegular(14);
        _termLabel.textColor = kColorWhite;
        _termLabel.textAlignment = NSTextAlignmentCenter;
        [_termPill addSubview:_termLabel];
    }
    return self;
}

- (void)setAppName:(NSString *)name      { self.appLabel.text = name; [self setNeedsLayout]; }
- (void)setStatusText:(NSString *)text   { self.statusLabel.text = text; [self setNeedsLayout]; }
- (void)setAmount:(NSString *)amount     { self.amountLabel.text = amount; [self setNeedsLayout]; }
- (void)setTermText:(NSString *)term     { self.termLabel.text = term; [self setNeedsLayout]; }
- (void)setCustomColor:(UIColor *)color  { self.backgroundColor = color; }

- (void)layoutSubviews {
    [super layoutSubviews];
    // figma: hero (18,112) 339×171. 子坐标减去 hero.origin
    CGFloat W = self.bounds.size.width;
    // White icon (34-18, 126-112) = (16, 14) 24×24
    self.iconBox.frame    = CGRectMake(kScaleW(16), kScaleH(14), kScaleW(24), kScaleW(24));
    // APPname (67-18, 131-112) = (49, 19)
    self.appLabel.frame   = CGRectMake(kScaleW(49), kScaleH(19), kScaleW(140), kScaleH(20));
    // Status right side (top) ~y=19, right 16
    self.statusLabel.frame = CGRectMake(W * 0.4, kScaleH(19), W * 0.6 - kScaleW(16), kScaleH(20));
    // ₱amount (34-18, 164-112) = (16, 52) 97×42
    self.amountLabel.frame = CGRectMake(kScaleW(16), kScaleH(52), kScaleW(200), kScaleH(42));
    // 180 Days pill (254-18, 168-112) = (236, 56) 90×35
    self.termPill.frame    = CGRectMake(W - kScaleW(16) - kScaleW(90), kScaleH(56), kScaleW(90), kScaleH(35));
    self.termLabel.frame   = self.termPill.bounds;
}

@end
