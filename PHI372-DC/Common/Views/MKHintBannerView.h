//
//  MKHintBannerView.h
//  Figma 通用 Hint 卡 (Bank list / Feedback / Contact / KYC 上传 / Repayment Instructions 等)
//
//  尺寸: 339×N (height 自适应), x=18 居中
//  背景 #E9E9E4, 圆角 14
//  内含: 24×24 hint icon (左上) + N 行说明文字 (PingFang SC 14, #999999)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKHintBannerView : UIView
- (instancetype)initWithText:(NSString *)text;
/// 根据文本预估高度 (含上下 padding)
+ (CGFloat)heightForText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
