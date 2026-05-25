//
//  MKGradientButton.m
//  PHI372-DC
//

#import "MKGradientButton.h"
#import "MKConstants.h"

@interface MKGradientButton ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation MKGradientButton

+ (instancetype)buttonWithTitle:(NSString *)title {
    return [self buttonWithTitle:title fontSize:16];
}

+ (instancetype)buttonWithTitle:(NSString *)title fontSize:(CGFloat)fontSize {
    MKGradientButton *btn = [MKGradientButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:kColorWhite forState:UIControlStateNormal];
    btn.titleLabel.font = kFontSemibold(fontSize);
    btn.startColor = kColorPrimary;
    btn.endColor = kColorPrimaryDark;
    btn.cornerRadius = 24;
    return btn;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
    self.gradientLayer.cornerRadius = self.cornerRadius;
    self.layer.cornerRadius = self.cornerRadius;
    self.clipsToBounds = YES;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[
            (__bridge id)(self.startColor ?: kColorPrimary).CGColor,
            (__bridge id)(self.endColor ?: kColorPrimaryDark).CGColor
        ];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 0);
        [self.layer insertSublayer:_gradientLayer atIndex:0];
    }
    return _gradientLayer;
}

- (void)setStartColor:(UIColor *)startColor {
    _startColor = startColor;
    _gradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)(self.endColor ?: kColorPrimaryDark).CGColor];
}

- (void)setEndColor:(UIColor *)endColor {
    _endColor = endColor;
    _gradientLayer.colors = @[(__bridge id)(self.startColor ?: kColorPrimary).CGColor, (__bridge id)endColor.CGColor];
}

@end
