//
//  MKGradientBackgroundView.h
//
//  通用顶部渐变背景 — Login / Home / 订单详情 等多页面共用
//  Figma 默认: #385330 (27%) → #F8F8F7 (53%), 0→484pt
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKGradientBackgroundView : UIView

/// 顶色 (默认 kColorPrimary)
@property (nonatomic, strong) UIColor *topColor;
/// 底色 (默认 kColorBackground)
@property (nonatomic, strong) UIColor *bottomColor;
/// 渐变开始位置, 0-1 (默认 0.27)
@property (nonatomic, assign) CGFloat startLocation;
/// 渐变结束位置, 0-1 (默认 0.53)
@property (nonatomic, assign) CGFloat endLocation;

@end

NS_ASSUME_NONNULL_END
