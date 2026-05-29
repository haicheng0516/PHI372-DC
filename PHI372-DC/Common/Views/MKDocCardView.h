//
//  MKDocCardView.h
//  Figma 3:1257 / 3:1296 / 3:1313 Doc 卡片 (灰底 r=14 文本卡)
//
//  布局:
//    339×N (宽 339, 高度按文本)
//    背景 #E9E9E4, 圆角 14
//    可选小节标题 (PingFang SC 600 14pt #000)
//    正文段落 (PingFang SC 400 14pt #666666 lh ~1.5)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKDocCardView : UIView
- (instancetype)initWithSectionTitle:(nullable NSString *)sectionTitle body:(NSString *)body;
+ (CGFloat)heightForSectionTitle:(nullable NSString *)sectionTitle body:(NSString *)body;
@end

NS_ASSUME_NONNULL_END
