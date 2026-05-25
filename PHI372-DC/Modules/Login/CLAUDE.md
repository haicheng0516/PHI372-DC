# CLAUDE.md — Login

## VC

`MKSignInViewController` — 手机号 + OTP 登录(无独立注册流程,首次手机号即注册)

## 约定

- 手机号校验走 `Common/NetWorkTool/MKPhoneValidator`,**不要正则散写**
- OTP 校验走 `Common/NetWorkTool/MKOTPValidator`
- 登录成功后写入 `MKLoginManager`,后续接口公参自动带 token
- 协议勾选用 `Assets.xcassets/mk_check_off` / `mk_check_on` 切图

## 登录后路由

后端返回的用户状态决定下一步:

- 未 KYC → push KYC 第 1 步 (`MKKYCPersonalViewController`)
- 已 KYC 无单 → Home
- 已 KYC 有未完订单 → 走 `MKReloanFlowHandler` 决定

不要在 SignIn VC 里硬编码上述判断,交给 `MKLoginManager` / `MKReloanFlowHandler`。
