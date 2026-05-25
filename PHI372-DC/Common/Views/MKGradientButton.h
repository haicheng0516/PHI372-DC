//
//  MKGradientButton.h
//  PHI372-DC
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKGradientButton : UIButton

@property (nonatomic, strong) UIColor *startColor;
@property (nonatomic, strong) UIColor *endColor;
@property (nonatomic, assign) CGFloat cornerRadius;

+ (instancetype)buttonWithTitle:(NSString *)title;
+ (instancetype)buttonWithTitle:(NSString *)title fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
