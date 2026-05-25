//
//  MKOrderDetailBottomBar.m
//

#import "MKOrderDetailBottomBar.h"
#import "MKConstants.h"

static const CGFloat kBtnW = 303;
static const CGFloat kBtnH = 56;
static const CGFloat kBtnGap = 12;
static const CGFloat kBarPadTop = 16;
static const CGFloat kBarPadBot = 16;

@interface MKOrderDetailBottomBar ()
@property (nonatomic, strong) UIButton *primaryBtn;
@property (nonatomic, strong) UIButton *secondaryBtn;
@end

@implementation MKOrderDetailBottomBar

+ (MKOrderDetailBottomBarMode)modeForOrderStatus:(NSInteger)orderStatus {
    switch (orderStatus) {
        case 32: return MKOrderDetailBottomBarModePrimaryWithdraw;
        case 60: case 63: return MKOrderDetailBottomBarModeRepayAndDefer;
        case 61: return MKOrderDetailBottomBarModePrimaryRepay;
        case 36: return MKOrderDetailBottomBarModePrimaryModifyBank;
        default: return MKOrderDetailBottomBarModeNone;
    }
}

+ (CGFloat)heightForMode:(MKOrderDetailBottomBarMode)mode {
    switch (mode) {
        case MKOrderDetailBottomBarModeNone:
            return 0;
        case MKOrderDetailBottomBarModeRepayAndDefer:
            return kScaleH(kBarPadTop) + kScaleH(kBtnH) + kScaleH(kBtnGap) + kScaleH(kBtnH) + kScaleH(kBarPadBot);
        default:
            return kScaleH(kBarPadTop) + kScaleH(kBtnH) + kScaleH(kBarPadBot);
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = kColorBackground;
        _primaryBtn = [self makeButton];
        _secondaryBtn = [self makeButton];
        [_primaryBtn addTarget:self action:@selector(primaryTapped) forControlEvents:UIControlEventTouchUpInside];
        [_secondaryBtn addTarget:self action:@selector(secondaryTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_primaryBtn];
        [self addSubview:_secondaryBtn];
        _primaryBtn.hidden = YES;
        _secondaryBtn.hidden = YES;
    }
    return self;
}

- (UIButton *)makeButton {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.layer.cornerRadius = kScaleH(kBtnH * 0.5);
    b.titleLabel.font = kFontSemibold(16);  // Poppins 16 weight 600
    return b;
}

- (void)setMode:(MKOrderDetailBottomBarMode)mode {
    _mode = mode;
    switch (mode) {
        case MKOrderDetailBottomBarModeNone:
            _primaryBtn.hidden = YES;
            _secondaryBtn.hidden = YES;
            break;
        case MKOrderDetailBottomBarModePrimaryWithdraw:
            [_primaryBtn setTitle:@"Withdraw" forState:UIControlStateNormal];
            [self stylePrimary:_primaryBtn];
            _primaryBtn.hidden = NO;
            _secondaryBtn.hidden = YES;
            break;
        case MKOrderDetailBottomBarModePrimaryRepay:
            [_primaryBtn setTitle:@"Repay" forState:UIControlStateNormal];
            [self stylePrimary:_primaryBtn];
            _primaryBtn.hidden = NO;
            _secondaryBtn.hidden = YES;
            break;
        case MKOrderDetailBottomBarModePrimaryModifyBank:
            [_primaryBtn setTitle:@"Modify Bank Card" forState:UIControlStateNormal];
            [self stylePrimary:_primaryBtn];
            _primaryBtn.hidden = NO;
            _secondaryBtn.hidden = YES;
            break;
        case MKOrderDetailBottomBarModeRepayAndDefer:
            [_primaryBtn setTitle:@"Repay" forState:UIControlStateNormal];
            [_secondaryBtn setTitle:@"Defer" forState:UIControlStateNormal];
            [self stylePrimary:_primaryBtn];
            [self styleSecondary:_secondaryBtn];
            _primaryBtn.hidden = NO;
            _secondaryBtn.hidden = NO;
            break;
    }
    [self setNeedsLayout];
}

- (void)stylePrimary:(UIButton *)b {
    b.backgroundColor = MKHexColor(0x385330);
    [b setTitleColor:kColorWhite forState:UIControlStateNormal];
}

- (void)styleSecondary:(UIButton *)b {
    b.backgroundColor = MKHexColor(0xE9E9E4);
    [b setTitleColor:MKHexColor(0x385330) forState:UIControlStateNormal];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat btnW = kScaleW(kBtnW);
    CGFloat btnH = kScaleH(kBtnH);
    CGFloat x = (w - btnW) * 0.5;
    CGFloat y = kScaleH(kBarPadTop);
    _primaryBtn.frame = CGRectMake(x, y, btnW, btnH);
    y += btnH + kScaleH(kBtnGap);
    _secondaryBtn.frame = CGRectMake(x, y, btnW, btnH);
}

- (void)primaryTapped { if (self.onPrimaryTapped) self.onPrimaryTapped(); }
- (void)secondaryTapped { if (self.onSecondaryTapped) self.onSecondaryTapped(); }

@end
