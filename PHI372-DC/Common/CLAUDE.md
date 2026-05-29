# CLAUDE.md — Common(共享基础)

跨模块通用代码。**写任何新 manager / 弹窗 / 通用 View 前,先在这里 grep,90% 已经有了**。

---

## 必先复用(禁止平行实现)

按"业务需求 → 现成方案"分组。任何新需求先在这张表里找,有现成的就不要再造。

### 网络 / 配置 / 环境

| 需求 | 用现成的 | 不要 |
|---|---|---|
| 网络请求(签名/加密/UA/公参/错误码拦截全内置) | `NetWorkTool/MKNetworkManager` `post:params:success:failure:` | 裸 `NSURLSession` / 跳过签名 |
| 接口签名 / HMAC | `NetWorkTool/MKEncryptManager generateRequestBody:` | 自己拼 sign / 写 md5 |
| 公共参数(appId/salt/deviceId/version/语言等) | `NetWorkTool/MKCommonParams.shared` | 散落多份 |
| 项目专属环境值(appId/salt/baseURL/merchantId) | `NetWorkTool/MKAppEnvironment` 读 Info.plist | 写死字符串在源码 |
| App 全局配置(rejectH5/feedbackGuidance/policyHref 等) | `Manager/MKAppConfigManager.sharedManager.currentAppConfig` | 各模块自己请求 |

### 用户态 / 登录

| 需求 | 用现成的 | 不要 |
|---|---|---|
| 登录态 / token / 用户信息 | `Manager/MKLoginManager` + `NetWorkTool/MKLoginUserInfo` | 散落到 `NSUserDefaults` |
| 手机号格式校验 | `NetWorkTool/MKPhoneValidator` | 自己写正则 |
| OTP 验证码校验 | `NetWorkTool/MKOTPValidator` | 自己处理倒计时 |
| 设备指纹 | `Manager/MKDeviceTool` | 自己读 IDFV/UUID |

### 订单 / 申请流

| 需求 | 用现成的 | 不要 |
|---|---|---|
| 订单状态机(首单+复借通用) | `Manager/MKSeamlessOrderManager` | 自己写一遍 |
| 复借决策(弹窗 + termV3 + seamless) | `Manager/MKReloanFlowHandler` | 在 VC 里写 status 判断 |
| 拒量输出(4 触发点判定 + 跳 H5) | `Manager/MKRejectFlowCoordinator presentRejectH5FromVC:` | 自己拼 H5 / 重复判定 |

### 推送 / 埋点 / 评分

| 需求 | 用现成的 | 不要 |
|---|---|---|
| 推送接入(Firebase + APNs + UNNotification delegate) | `Manager/MKPushBootstrap` + AppDelegate 3 行转发 | AppDelegate 散落 80 行 boilerplate |
| 通知权限申请(系统弹窗 + 二次自定义) | `Manager/MKNotificationPermissionCoordinator` | 自己调 `UNUserNotificationCenter` |
| FCM token 拉取 + 上报 | `Manager/MKFCMTokenManager` | 自己监听 token refresh |
| 埋点上报 | `Manager/MKEventTrackingService recordEventWithCode:` | 自己 POST `/app/v3/bury/record` |
| 好评引导弹窗 + 一次性守卫 | `Manager/MKRatingPromptManager` + `SKStoreReviewController` | 自己写一次性 flag |

### UI 组件

| 需求 | 用现成的 | 不要 |
|---|---|---|
| 弹窗 / 选择器 / Alert | `Views/MKBottomSheetView` 枚举(22+ 类) | 新建独立 picker / alert |
| 银行卡 UI | `Views/MKBankCardView` | 自定义 view |
| 表单输入项(label+输入+错误提示) | `Views/MKFormField` | 拼 `UITextField + UILabel` |
| Toast / 结果页 | `Views/MKToastView` `Views/MKResultView` | 滥用 `SVProgressHUD` |
| 通用 WebView(协议/帮助页) | `Views/MKWebViewViewController` | 直接拉 `WKWebView` |
| 拒量 H5 容器(双向 JS 桥 + 注入用户信息) | `Views/MKRejectWebViewController` | 自己接 `WKScriptMessageHandler` |
| 产品 logo 加载 + 失败兜底色块 | `Category/UIImageView+MKProductLogo` `mk_setProductLogoURL:fallbackColor:` | `sd_setImageWithURL` 内联 + 自己写兜底 |
| 金额格式化(千分位 / 取整 / Peso 符号) | `Category/NSString+MKAmount` `mk_formattedPesoAmount` | 自己写 `NSNumberFormatter` |
| 颜色 / 字体 / scale 宏 / hex / 主色 | `Macros/MKConstants.h` | 硬编码 hex / size / fontSize |
| Hint 卡 / Doc 卡 / 联系行 / 渐变背景 / 按钮 | `Views/MKHintBannerView` `MKDocCardView` `MKContactRowCell` `MKGradientBackgroundView` `MKGradientButton` `MKActionButton` | 自定义 view |
| 订单 Hero 卡 / 订单明细卡 | `Views/MKOrderHeroCard` `MKOrderDetailCard` | 自定义 card |

---

## 全局拦截 / 默认行为(看不见但已生效)

这些能力**已在底层自动接管**,业务代码不用关心,但**改之前要懂**:

### 网络层 (`MKNetworkManager`)

- **resultCode 全局拦截**:
  - `2000001 / 2000002 / 2002001` → 自动跳登录
  - `2009006` → 自动拉版本 + 弹强更(走 `MKBottomSheetView`)
  - 业务回调拿到的 success 已是过滤后的
- **User-Agent** 每次请求自动设(从 `MKCommonParams` 拼 appId/version/device/iOS 版本)
- **baseURL** 启动时从 `MKAppEnvironment.baseURL` 读 Info.plist `MKBaseURL`
- **路径以 `http` 开头时**:绕过 baseURL 拼接

### 签名层 (`MKEncryptManager`)

- 所有 `generateRequestBody:` 出来的 body 已自动含:`appId`/`salt`/`deviceId`/`clientVersion`/`os`/`clientLanguage`/`channel`/`sign`(HMAC)
- 业务只需传业务字段,公参和签名由它处理
- **想避开签名**(罕见):直接拿 `MKNetworkManager post:` 但自己拼 body

### 推送层 (`MKPushBootstrap`)

- `setup` 调用后:Firebase init(若 `GoogleService-Info.plist` 在 bundle) + UNUserNotificationCenter delegate 设到自己
- 前台收推送:横幅 + List + 声音(iOS 14+)
- 用户点推送进 App(inactive/background):自动埋 602

### App 配置 (`MKAppConfigManager`)

- 首页 `viewWillAppear` 自动拉 `/app/v3/app/config`
- 任何地方读 `[MKAppConfigManager sharedManager].currentAppConfig.xxx` 即可
- 其他模块要在 config 还没拉时用,调 `loadConfigWithCompletion:` 自取

---

## 改 Common 的风险

Common 跨所有模块,改一个接口可能 break N 个模块。

- **新增方法**最安全(向后兼容)
- 改既有签名前 `grep -r 'methodName' ../Modules` 确认全部引用
- 删除方法前同上,确认零引用
- 改 `Manager/MK*Manager` 任何公共方法 → 必跑订单 e2e(申请/复借/还款都过一遍)
- 改 `Macros/MKConstants.h` 任何颜色/scale → 截图整页比对设计图

---

## 子目录索引(完整清单)

### `Base/` — 基类(VC / Cell / 导航 / Doc 页)

| 类 | 用途 |
|---|---|
| `MKBaseViewController` | 所有业务 VC 的基类。内置 `MKNavBar`,不要用系统 `UINavigationBar`。`navBarStyle` 控制深浅,`navTitle` 设标题。 |
| `MKBaseTableViewCell` | Cell 基类 |
| `MKNavigationController` | 导航栈,统一手势/转场 |
| `MKDocPageViewController` | Doc 页(灰底 r=14 文本卡)基类,Profile/About/Agreement 等用 |

### `Category/` — 三个分类工具

| 类 | 用途 |
|---|---|
| `NSString+MKAmount` | 金额格式化:`mk_formattedPesoAmount` 千分位 + Peso 符号 |
| `UIImage+MKOrientation` | 拍照后的方向修正 |
| `UIImageView+MKProductLogo` | 产品 logo 加载 + 失败兜底色块:`mk_setProductLogoURL:fallbackColor:` |
| `NSString+MKEncrypt` | 加密辅助(物理位置在 NetWorkTool/) |

### `Macros/`

| 文件 | 内容 |
|---|---|
| `MKConstants.h` | 主题色(`kColorPrimary` / `kColorCardSecondary` / `kColorBlack` / `kColorWhite` 等)/ 字体宏(`kFontRegular(n)` `kFontBold(n)` `kFontSemibold(n)`)/ scale 宏(`kScale` / `kScaleW(v)` / `kScaleH(v)` 基于 375 宽设计稿)/ `MKHexColor(0xRRGGBB)` / `MKAppDisplayName()`(读 Info.plist 的 `CFBundleDisplayName`) |

### `Manager/` — 12 个长生命周期服务

| 类 | 职责 |
|---|---|
| `MKLoginManager` | 登录态(`mobile` / `userId` / `token`),持久化到 keychain |
| `MKDeviceTool` | 设备指纹(IDFV / 系统版本 / 机型) |
| `MKAppConfigManager` | App 全局配置门面,`currentAppConfig.rejectH5` 等都从这取 |
| `MKAppConfigModel` | 配置 model(`rejectH5` / `feedbackGuidance` / `policyHref` / `conditionsHref` / `agreementHref` / `appEmail` / `officialWebsiteUrl` / `dynamicParameter` 等) |
| `MKSeamlessOrderManager` | 订单状态机(首单+复借通用):授权 → 数据采集 → submit;走 NSNotification 通知首页刷新 |
| `MKReloanFlowHandler` | 复借决策:拉 product/state → 弹复借框 → termV3 → 调用 seamless |
| `MKRejectFlowCoordinator` | 拒量调度:`presentRejectH5FromVC:` (host 可空,内部自动找 top VC,返回 BOOL 表示已接管) |
| `MKPushBootstrap` | 推送总线:`setup` + APNs token 转发 + UNUserNotificationCenter delegate |
| `MKFCMTokenManager` | FCM token 拉取 + 上报到 `/app/v3/user/info` |
| `MKNotificationPermissionCoordinator` | 通知权限申请(系统弹 + 二次自定义弹) |
| `MKEventTrackingService` | 埋点:`recordEventWithCode:` POST `/app/v3/bury/record` |
| `MKRatingPromptManager` | 好评引导:一次性 flag + `consumePendingFlag` / `markPromptShown` |

### `NetWorkTool/` — 9 个网络层

| 类 | 职责 |
|---|---|
| `MKNetworkManager` | HTTP POST 入口,内置全局错误码拦截(重登/强更)、UA、baseURL 拼接、文件上传 |
| `MKEncryptManager` | `generateRequestBody:` HMAC 签名 + 公参注入 |
| `MKCommonParams` | 公共参数单例(appId/salt/deviceId/version/语言等),启动时从 `MKAppEnvironment` 取 |
| `MKAppEnvironment` | 项目专属配置读取:`appId` / `salt` / `baseURL` / `merchantId` 全从 Info.plist 读 |
| `MKLoginResponse` | 登录接口响应包装 |
| `MKLoginUserInfo` | 用户态 model |
| `MKOTPValidator` | OTP 校验 + 倒计时 |
| `MKPhoneValidator` | 手机号格式校验 |
| `NSString+MKEncrypt` | 加密辅助分类(md5/hmac 等) |

### `Views/` — 17 个通用 UI

| 类 | 用途 |
|---|---|
| `MKBottomSheetView` | **22+ 弹窗枚举库**(picker / alert / 复借 / 强更 / 好评 / 拒绝原因等),所有弹窗走它 |
| `MKNavBar` | 自定义导航栏,`MKBaseViewController` 内置 |
| `MKActionButton` | 主按钮 |
| `MKGradientButton` `MKGradientBackgroundView` | 渐变按钮 / 渐变背景 |
| `MKBankCardView` | 银行卡 UI |
| `MKFormField` | 表单输入项(label + input + 错误提示) |
| `MKHintBannerView` | Hint 横幅卡 |
| `MKDocCardView` | Doc 文本卡 |
| `MKContactRowCell` | 联系方式 row |
| `MKPickerView` | 选择器底层 |
| `MKOrderHeroCard` | 订单 Hero 卡(状态色切换) |
| `MKOrderDetailCard` | 订单明细卡(灰底 + N 行 label/value) |
| `MKToastView` | Toast |
| `MKResultView` | 结果页(申请成功/失败/好评成功/注销成功) |
| `MKWebViewViewController` | 通用 WebView(协议页/帮助页) |
| `MKRejectWebViewController` | 拒量 H5 容器(双向 JS 桥 + 注入 appId/salt/mobile/userId/token/baseUrl) |

---

## 模板复用接入(下个项目克隆后)

1. **改 Info.plist 4 个键** — 不改源码:
   ```
   MKAppID       = <新项目 appId>
   MKSalt        = <新项目 HMAC salt>
   MKBaseURL     = <新项目接口域名>
   MKMerchantID  = <新项目商户号>
   ```
2. **改 `CFBundleDisplayName` + Bundle Identifier**
3. **接 push(可选)**:把 `GoogleService-Info.plist` 拖进 bundle, AppDelegate 已是 3 行转发不需要改
4. **改 `Macros/MKConstants.h` 主题色**:`kColorPrimary` 等改成新设计稿色值
5. **(如换前缀)** `MK` → 项目前缀: `grep -rl '\bMK[A-Z]' . | xargs sed -i '' 's/MK\([A-Z]\)/XQ\1/g'` (示例,实际按映射表)

Common 内业务接口、签名机制、错误码拦截、推送链路、订单状态机全部开箱即用。
