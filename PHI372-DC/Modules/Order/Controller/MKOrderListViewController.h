//
//  MKOrderListViewController.h
//  Figma 3:599 / 3:636 / 3:661 / 3:686 历史订单 (accordion)
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKOrderSectionKind) {
    MKOrderSectionSubmitApplication = 0,   // 已提交申请
    MKOrderSectionPendingRepayment  = 1,   // 待还款
    MKOrderSectionProcessing        = 2,   // 处理中
    MKOrderSectionCompleted         = 3,   // 已完成
};

// 兼容旧调用方
typedef NS_ENUM(NSInteger, MKOrderListTab) {
    MKOrderListTabPending    = MKOrderSectionPendingRepayment,
    MKOrderListTabProcessing = MKOrderSectionProcessing,
    MKOrderListTabCompleted  = MKOrderSectionCompleted,
};

@interface MKOrderListViewController : MKBaseViewController
/// 初始默认展开的 section, 默认 SubmitApplication
- (instancetype)initWithExpandedSection:(MKOrderSectionKind)kind;
/// 兼容旧 API
- (instancetype)initWithTab:(MKOrderListTab)tab;
@end

NS_ASSUME_NONNULL_END
