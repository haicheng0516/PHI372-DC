//
//  MKSignInCardView.h
//
//  Sign in 页核心卡片 — 包含胶囊标题/欢迎语/手机号/OTP/协议/Sign in 按钮
//  对应 Figma 3:1743 中 card 节点(18,103, 339x512)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKSignInCardView : UIView

/// 当前手机号 (绑定 UITextField,可用于 VC 取值)
@property (nonatomic, copy, readonly, nullable) NSString *mobile;
/// 当前 OTP
@property (nonatomic, copy, readonly, nullable) NSString *otp;
/// 协议是否勾选
@property (nonatomic, assign, readonly) BOOL agreementChecked;

@property (nonatomic, copy, nullable) void (^onGetOTPTapped)(void);
@property (nonatomic, copy, nullable) void (^onSignInTapped)(void);
@property (nonatomic, copy, nullable) void (^onAgreementCheckToggled)(BOOL checked);

/// 启动 N 秒倒计时, 按钮 disable + 显示 "Ns"
- (void)startOTPCountdown:(NSInteger)seconds;
/// 强制重置按钮回 "Get OTP"
- (void)resetOTPButton;

@end

NS_ASSUME_NONNULL_END
