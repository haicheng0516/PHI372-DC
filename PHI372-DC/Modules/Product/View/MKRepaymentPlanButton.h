//
//  MKRepaymentPlanButton.h
//  PHI372-DC
//
//  黄绿色 Repayment plan 按钮 (#BBCB2F, 303×56, r28).
//  Pencil 用例: b4hMw0 (产品申请-多), hv74X (待还款详情).
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKRepaymentPlanButton : UIControl

/// 按钮文案 (默认 "Repayment plan")
@property (nonatomic, copy) NSString *title;

+ (CGFloat)buttonHeight;

@end

NS_ASSUME_NONNULL_END
