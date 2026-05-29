//
//  MKDetailRow.h
//
//  单行明细 (左灰文 label [+ ⓘ icon] + 右深色值)
//  跨 5 个页面使用 (产品申请-多/单, 订单审核中, 待提现, 待还款), 像素级一致
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKDetailRow : UIView

/// 行高 (设计稿 20pt + 上下间距由容器决定)
+ (CGFloat)rowHeight;

/// 创建一行
/// @param label 左侧文案 (e.g. "Amount received")
/// @param hasInfoIcon 是否显示 ⓘ 图标 (前 3 行有, 后 2 行无)
- (instancetype)initWithLabel:(NSString *)label hasInfoIcon:(BOOL)hasInfoIcon;

/// 右侧值 (e.g. "9,900")
@property (nonatomic, copy) NSString *value;

/// 点击 ⓘ 图标回调
@property (nonatomic, copy, nullable) void(^onInfoTapped)(UIView *anchor);

@end

NS_ASSUME_NONNULL_END
