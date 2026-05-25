//
//  MKKYCBankCardEditViewController.h
//  PHI372-DC
//
//  KYC-修改银行卡 — Figma 3:1012
//

#import "MKKYCBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCBankCardEditViewController : MKKYCBaseViewController

/// 编辑模式必填: 选中银行卡的 bankCardBindId, 用于 /payAccountInfo/list 拉详情 + /update 时附带 recordId.
@property (nonatomic, assign) NSInteger bankCardBindId;

@end

NS_ASSUME_NONNULL_END
