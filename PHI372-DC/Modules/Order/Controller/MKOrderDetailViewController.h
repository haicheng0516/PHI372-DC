//  MKOrderDetailViewController.h
//  PHI372-DC — 统一订单详情页
//  同一 VC, 通过 orderStatus 驱动:
//    - 卡片底色 (#11722E 审核 / #AF5D00 待还 / #0A7F93 待提 / #A0721B 逾期 / #6E1758 改卡 / ...)
//    - 右上状态文案
//    - 明细行字段数 (审核中/待提现 5 行, 待还款/逾期 10 行)
//    - 底部按钮 (None / Withdraw / Repay+Defer / Repay / Modify Bank Card)
//    - status==32 时拉 /app/v3/order/withdrawn/detail, 启用金额+期限可选

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKOrderDetailViewController : MKBaseViewController

/// 必传: 订单 ID
- (instancetype)initWithOrderId:(NSString *)orderId;

/// 可选: 产品 ID (api 需要时附带)
@property (nonatomic, copy, nullable) NSString *productId;

@end

NS_ASSUME_NONNULL_END
