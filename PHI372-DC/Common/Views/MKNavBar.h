//
//  MKNavBar.h
//  PHI372-DC
//  自定义导航栏组件
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKNavBarTheme) {
    MKNavBarThemeDark,        // 绿色标题 + 黑色箭头（默认，用于大多数子页面）
    MKNavBarThemeLight,       // 白色标题 + 白色箭头（KYC、产品申请等深色背景页）
    MKNavBarThemeTransparent, // 无标题无按钮（首页等自定义页面）
};

@interface MKNavBar : UIView

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, assign) MKNavBarTheme theme;

/// 导航栏总高度（状态栏 + 44）
@property (nonatomic, assign, readonly) CGFloat barHeight;

- (void)setTitle:(NSString *)title;
- (void)setTitle:(NSString *)title color:(nullable UIColor *)color;
- (void)showBackButton;
- (void)hideBackButton;
- (void)setBackAction:(void(^)(void))action;

@end

NS_ASSUME_NONNULL_END
