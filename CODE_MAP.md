# CODE_MAP — PHI372-DC

> 每个任务启动前先扫这个表,找到目标目录,然后读那个目录的 CLAUDE.md。

## 根目录

| 路径 | 用途 |
|---|---|
| `CLAUDE.md` | 全局指针 + 陷阱(必读) |
| `CODE_MAP.md` | 本文件(目录索引) |
| `Podfile` `Podfile.lock` `Pods/` | CocoaPods 依赖 |
| `PHI372-DC.xcodeproj/` | Xcode 工程 |
| `PHI372-DC.xcworkspace/` | Xcode workspace(实际开发入口) |

## App 源码 `PHI372-DC/`

| 路径 | 用途 | 本地 CLAUDE.md |
|---|---|---|
| `AppDelegate.*` `SceneDelegate.*` `main.m` | App 生命周期入口 | [PHI372-DC/CLAUDE.md](./PHI372-DC/CLAUDE.md) |
| `Info.plist` | 启动配置 + 权限文案 + 应用名 | ↑ |
| `Assets.xcassets/` | 所有图片资源(`mk_xxx` 命名) | ↑ |
| `Base.lproj/LaunchScreen.storyboard` | 启动屏(Se_bg 全屏 + 右下角 logo + APP name) | — |
| `Common/` | 跨模块共享代码 | [Common/CLAUDE.md](./PHI372-DC/Common/CLAUDE.md) |
| `Modules/` | 业务功能模块 | [Modules/CLAUDE.md](./PHI372-DC/Modules/CLAUDE.md) |

## 通用基础 `PHI372-DC/Common/`

| 子目录 | 关键类 | 用途 |
|---|---|---|
| `Base/` | `MKBaseViewController` `MKBaseTableViewCell` `MKNavigationController` `MKDocPageViewController` | 所有 VC/Cell 的基类 + 导航栈 |
| `Category/` | `NSString+MKAmount` `UIImage+MKOrientation` | 金额千分位/取整,图片方向 |
| `Macros/` | `MKConstants.h` | 颜色 + 字体 + scale 宏(`kScale/kScaleW/kScaleH/kFontXxx/MKHexColor`) |
| `Manager/` | `MKLoginManager` `MKDeviceTool` `MKSeamlessOrderManager` `MKReloanFlowHandler` | 登录态/设备指纹/订单状态机/复借决策 |
| `NetWorkTool/` | `MKNetworkManager` `MKEncryptManager` `MKCommonParams` `MKLoginUserInfo` `MKOTPValidator` `MKPhoneValidator` `NSString+MKEncrypt` | 网络/加密/公参/用户态/校验 |
| `Views/` | `MKBottomSheetView`(22+ 弹窗枚举) `MKNavBar` `MKActionButton` `MKHintBannerView` `MKPickerView` `MKOrderHeroCard` `MKOrderDetailCard` `MKBankCardView` `MKFormField` `MKToastView` `MKResultView` `MKWebViewViewController` `MKContactRowCell` `MKDocCardView` `MKGradientButton` `MKGradientBackgroundView` | 跨模块通用 UI 组件 |

## 业务模块 `PHI372-DC/Modules/`

> 每个模块按 `Cell/Controller/Model/View` 四目录组织。

| 模块 | 功能 | 关键 VC | 本地 CLAUDE.md |
|---|---|---|---|
| `Login/` | 登录/注册 | `MKSignInViewController` | [Login/CLAUDE.md](./PHI372-DC/Modules/Login/CLAUDE.md) |
| `KYC/` | 实名认证(Personal/ID/IDCamera/Liveness/Finance/Contact/Payment/BankCardEdit) | `MKKYCBaseViewController` + 子 VC | [KYC/CLAUDE.md](./PHI372-DC/Modules/KYC/CLAUDE.md) |
| `Home/` | 首页 banner + 产品入口,换绑银行卡 | `MKHomeViewController` `MKHomeBankCardViewController` | [Home/CLAUDE.md](./PHI372-DC/Modules/Home/CLAUDE.md) |
| `Product/` | 产品申请页 | `MKProductApplyViewController` | [Product/CLAUDE.md](./PHI372-DC/Modules/Product/CLAUDE.md) |
| `Order/` | 订单列表 + 详情(单 VC 多状态) + 还款 + 提交 | `MKOrderListViewController` `MKOrderDetailViewController` `MKOrderRepayViewController` `MKOrderSubmitViewController` | [Order/CLAUDE.md](./PHI372-DC/Modules/Order/CLAUDE.md) |
| `Profile/` | 个人中心(About/Agreement/Contact/Feedback/OfficialReloan/RepaymentInfo) | `MKProfileViewController` + 子 VC | [Profile/CLAUDE.md](./PHI372-DC/Modules/Profile/CLAUDE.md) |
| `Misc/` | 占位空页 | `MKEmptyViewController` | — |
| `Debug/` | 调试入口(弹窗 gallery) | `MKDialogGalleryViewController` | — |

## 跨目录约定

- 所有图片资源走 `Assets.xcassets`,命名前缀 `mk_`。**不要在工程根目录散放 png**
- 颜色 / 字体 / scale 一律从 `Common/Macros/MKConstants.h` 取
- 网络请求一律走 `MKNetworkManager`(签名/加密/公参已内置)
- 弹窗/选择器一律走 `MKBottomSheetView` 枚举,**禁止新建独立 picker/alert**
- 新增模块时:(1) 建 `Cell/Controller/Model/View` 四个目录,(2) 在新模块根放 `CLAUDE.md`,(3) 更新本文件
