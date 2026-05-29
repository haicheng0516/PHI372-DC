//
//  MKOrderStatusMapper.h
//  orderStatus → (accordion 桶 / chip 文案 / chip 色)
//
//  桶/chip 映射来自 Pencil 历史订单页面 ccSDx / I504rv / RMW3l / e9Pr2
//

#import <UIKit/UIKit.h>
#import "MKOrderListViewController.h"  // MKOrderSectionKind

@class MKOrderListModel;

NS_ASSUME_NONNULL_BEGIN

@interface MKOrderStatusMapper : NSObject

/// orderStatus → accordion 段; 未知状态返回 -1 (调用方应过滤)
+ (NSInteger)sectionForStatus:(NSInteger)status;

/// orderStatus → chip 文案
+ (NSString *)chipTextForStatus:(NSInteger)status;

/// orderStatus → chip 背景色 (Pencil 设计稿色)
+ (UIColor *)chipColorForStatus:(NSInteger)status;

/// orderStatus → cell 左下日期 label (e.g. "Date of application:" / "Payment date:" / "Repayment date:")
+ (NSString *)dateLabelForStatus:(NSInteger)status;

/// orderStatus + model → cell 右下日期值 (从 model 的 applyDate/dueDate/repayDate 中取对应字段)
+ (NSString *)dateValueForStatus:(NSInteger)status fromModel:(MKOrderListModel *)model;

@end

NS_ASSUME_NONNULL_END
