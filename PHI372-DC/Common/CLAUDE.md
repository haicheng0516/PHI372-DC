# CLAUDE.md — Common(共享基础)

跨模块通用代码。**写任何新 manager / 弹窗 / 通用 View 前,先在这里 grep,90% 已经有了**。

## 必先复用(禁止平行实现)

| 需求 | 用现成的 | 不要 |
|---|---|---|
| 弹窗 / 选择器 / Alert | `Views/MKBottomSheetView` 枚举(22+ 类) | 新建独立 picker / alert |
| 订单状态机(首单+复借通用) | `Manager/MKSeamlessOrderManager` | 自己写一遍 |
| 复借决策 | `Manager/MKReloanFlowHandler` | 在 VC 里写 status 判断 |
| 网络请求(签名/加密/公参在内) | `NetWorkTool/MKNetworkManager` + `MKCommonParams` | 裸 `NSURLSession` |
| 金额格式化(千分位/取整) | `Category/NSString+MKAmount` | 自己写 `NSNumberFormatter` |
| 登录态 / 用户信息 | `Manager/MKLoginManager` + `NetWorkTool/MKLoginUserInfo` | 散落到 NSUserDefaults |
| 颜色/字体/scale | `Macros/MKConstants.h` | 硬编码 hex / size |
| 银行卡 UI | `Views/MKBankCardView` | 自定义 view |
| 表单输入项 | `Views/MKFormField` | 拼 `UITextField + UILabel` |
| Toast / 结果页 | `Views/MKToastView` `Views/MKResultView` | SVProgressHUD 滥用 |
| 协议/帮助页 | `Views/MKWebViewViewController` | 直接拉 WKWebView |

## 改 Common 的风险

Common 跨所有模块,改一个接口可能 break N 个模块。

- 新增方法 **优先**(向后兼容)
- 改既有签名前 `grep -r 'methodName' PHI372-DC/Modules` 确认全部引用
- 删除方法前同上,确认零引用

## 子目录索引

| 子目录 | 关键类 |
|---|---|
| `Base/` | `MKBaseViewController`, `MKBaseTableViewCell`, `MKNavigationController`, `MKDocPageViewController` |
| `Category/` | `NSString+MKAmount`, `UIImage+MKOrientation`, `NSString+MKEncrypt`(在 NetWorkTool 里) |
| `Macros/` | `MKConstants.h` — 颜色 / 字体 / scale 宏 / 通用常量 |
| `Manager/` | `MKLoginManager`, `MKDeviceTool`, `MKSeamlessOrderManager`, `MKReloanFlowHandler` |
| `NetWorkTool/` | `MKNetworkManager`, `MKEncryptManager`, `MKCommonParams`, `MKLoginResponse`, `MKLoginUserInfo`, `MKOTPValidator`, `MKPhoneValidator` |
| `Views/` | 22+ 通用 UI 组件(详见 [CODE_MAP.md](../../CODE_MAP.md)) |
