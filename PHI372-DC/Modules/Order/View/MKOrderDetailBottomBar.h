//
//  MKOrderDetailBottomBar.h
//  PHI372-DC — 订单详情底部按钮区
//
//  按 orderStatus 动态显示 4 种形态:
//    None              — 审核中(30) 等无操作状态; bar 不显示
//    PrimaryWithdraw   — 待提现(32)         : "Withdraw"            绿色单按钮
//    RepayAndDefer     — 待还款(60/63)       : "Repay" + "Defer"     绿+浅灰双按钮(垂直)
//    PrimaryRepay      — 逾期(61)            : "Repay"               绿色单按钮
//    PrimaryModifyBank — 待修改银行卡(36)    : "Modify Bank Card"    绿色单按钮
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKOrderDetailBottomBarMode) {
    MKOrderDetailBottomBarModeNone = 0,
    MKOrderDetailBottomBarModePrimaryWithdraw,        // 32 待提现: "Withdraw"
    MKOrderDetailBottomBarModeRepayAndDefer,          // 60/63 待还款: "Repay" + "Defer"
    MKOrderDetailBottomBarModePrimaryRepay,           // 61 逾期: "Repay"
    MKOrderDetailBottomBarModePrimaryModifyBank,      // 36: "Modify Bank Card"
    MKOrderDetailBottomBarModePrimaryDataCapture,     // 10/20: "Submit Information" (当页数据抓取)
};

@interface MKOrderDetailBottomBar : UIView

@property (nonatomic, assign) MKOrderDetailBottomBarMode mode;

/// 主按钮点击 (Withdraw / Repay / Modify Bank Card)
@property (nonatomic, copy, nullable) void(^onPrimaryTapped)(void);
/// 次按钮点击 (Defer) — 仅 RepayAndDefer 形态
@property (nonatomic, copy, nullable) void(^onSecondaryTapped)(void);

/// orderStatus → mode 推导
+ (MKOrderDetailBottomBarMode)modeForOrderStatus:(NSInteger)orderStatus;

/// 当前 mode 下的整体高度 (不含 safeArea)
+ (CGFloat)heightForMode:(MKOrderDetailBottomBarMode)mode;

@end

NS_ASSUME_NONNULL_END
