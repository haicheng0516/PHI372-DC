# CLAUDE.md — Login(登录/注册)

## VC

| VC | 职责 |
|---|---|
| `MKSignInViewController` | 手机号 + OTP 一站式(无独立注册流程,首次手机号即注册);同一 VC 切两种数据态(输入前 / 输入后) |

## 必须复用

| 需求 | 用 |
|---|---|
| 手机号格式校验 | `Common/NetWorkTool/MKPhoneValidator`,不要正则散写 |
| OTP 倒计时 + 校验 | `Common/NetWorkTool/MKOTPValidator` |
| 登录态持久化 | `Common/Manager/MKLoginManager`(自动写 keychain,后续接口公参带 token) |
| 协议页跳转 | `Common/Views/MKWebViewViewController` + AppConfig 取 URL |
| Sign-in 卡片 UI | `View/MKSignInCardView`(本模块) |

## 接口

| 路径 | 用途 |
|---|---|
| `/sms/sendVerifySms` | 发送 OTP |
| `/auth/registerOrLogin` | 提交手机+OTP, 返回 token/userInfo |

`Common/NetWorkTool/MKLoginResponse` 是返回包装,`MKLoginUserInfo` 是用户态 model。

## 登录后路由

后端返回的 `userStatus` 决定下一步,**不要在 SignIn VC 里硬编码判断**,交给 `MKLoginManager` + `MKReloanFlowHandler`:

- `10` 未 KYC → push KYC 第 1 步(`MKKYCPersonalViewController`)
- `100` / `20` 已 KYC 无单 → Home
- `30+` 已 KYC 有未完订单 → 走 `MKReloanFlowHandler` 决定弹复借/进详情/拒量等

## UI 铁律

- 所有坐标 / 字号 / 颜色取自 Pencil 节点(Sign-in 卡:输入前 + 输入后两种态切换,共用同一 VC)
- 协议勾选用 `Assets.xcassets/mk_check_off` + `mk_check_on` 切图,不要 draw rect
- 主按钮走 `Common/Views/MKActionButton`,颜色取 `kColorPrimary`
- 错误提示走 toast(`Common/Views/MKToastView`)或 `SVProgressHUD showErrorWithStatus:`,不要弹 alert

## 跨模块依赖

- → `Common`(几乎全部:登录管理 / 网络 / OTP / 公参 / 弹窗 / WebView)
- → `KYC/MKKYCPersonalViewController`(首次登录 push 它)
- → `Home/MKHomeViewController`(老用户登录 push 它)

被谁依赖:

- `Common/NetWorkTool/MKNetworkManager` 全局拦截 `2000001 / 2000002 / 2002001` → 自动 present `MKSignInViewController`(强制重登场景)

## 新项目接入提示

无定制点。Common 网络层 + LoginManager 跑通后, 改改 `MKSignInCardView` 的 UI 主色就能用。
