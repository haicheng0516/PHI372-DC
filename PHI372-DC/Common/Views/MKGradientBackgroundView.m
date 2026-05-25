//
//  MKGradientBackgroundView.m
//  PHI372-DC
//

#import "MKGradientBackgroundView.h"
#import "MKConstants.h"

@interface MKGradientBackgroundView ()
@property (nonatomic, strong) CAGradientLayer *gradLayer;
@end

@implementation MKGradientBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _topColor       = kColorPrimary;
        _bottomColor    = kColorBackground;
        _startLocation  = 0.0;
        _endLocation    = 0.27;

        _gradLayer = [CAGradientLayer layer];
        _gradLayer.startPoint = CGPointMake(0.5, 0);
        _gradLayer.endPoint   = CGPointMake(0.5, 1);
        [self.layer addSublayer:_gradLayer];
        [self refresh];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradLayer.frame = self.bounds;
}

- (void)setTopColor:(UIColor *)c       { _topColor = c;       [self refresh]; }
- (void)setBottomColor:(UIColor *)c    { _bottomColor = c;    [self refresh]; }
- (void)setStartLocation:(CGFloat)v    { _startLocation = v;  [self refresh]; }
- (void)setEndLocation:(CGFloat)v      { _endLocation = v;    [self refresh]; }

- (void)refresh {
    self.gradLayer.colors    = @[(id)self.topColor.CGColor, (id)self.bottomColor.CGColor];
    self.gradLayer.locations = @[@(self.startLocation), @(self.endLocation)];
}

@end
