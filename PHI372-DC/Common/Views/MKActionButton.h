//
//  MKActionButton.h
//  主操作按钮 - 纯色 #5B662D, 高64, 圆角20
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKActionButton : UIButton

/// 创建主按钮（自动设置样式：#5B662D, h=64, r=20, 白色bold16文字）
+ (instancetype)buttonWithTitle:(NSString *)title;

/// 添加到父视图并固定在底部（距底部 safeArea + 20pt）
- (void)pinToBottomOfView:(UIView *)superview;

/// 添加到父视图指定Y位置，宽度 = superview.width - 40
- (void)addToView:(UIView *)superview atY:(CGFloat)y;

@end

NS_ASSUME_NONNULL_END
