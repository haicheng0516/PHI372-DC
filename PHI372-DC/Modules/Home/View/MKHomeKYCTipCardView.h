//
//  MKHomeKYCTipCardView.h
//  PHI372-DC
//
//  首页 KYC 前提示卡片 — 米色卡片 + 黄色 hint icon + 提示文本
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeKYCTipCardView : UIView
/// 提示文本(可改, 接口返回, 长度不固定): "Please complete the KYC certifcation before using our loan service."
@property (nonatomic, copy) NSString *tipText;

/// 按文本+卡片总宽计算所需高度 (含 padding); 用于父容器在加 cell 前布局
+ (CGFloat)heightForText:(NSString *)text cardWidth:(CGFloat)cardWidth;
@end

NS_ASSUME_NONNULL_END
