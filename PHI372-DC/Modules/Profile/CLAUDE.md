# CLAUDE.md — Profile(个人中心)

## VC

| VC | 职责 | 基类 |
|---|---|---|
| `MKProfileViewController` | 主入口(头像 + 菜单列表) | `MKBaseViewController` |
| `MKProfileFeedbackViewController` | 意见反馈表单 | `MKBaseViewController` |
| `MKProfileOfficialReloanViewController` | 官网/复借入口(跳 WebView 或外部浏览器) | `MKBaseViewController` |
| `MKProfileAboutViewController` | 关于我们(Doc 卡列表) | `MKDocPageViewController` |
| `MKProfileAgreementViewController` | 协议列表(隐私/服务/许可…) | `MKDocPageViewController` |
| `MKProfileContactViewController` | 联系客服(联系行列表) | `MKDocPageViewController` |
| `MKProfileRepaymentInfoViewController` | 还款须知(Doc 卡列表) | `MKDocPageViewController` |

## 必须复用

| 需求 | 用 |
|---|---|
| Doc 页骨架(灰底 r=14 文本卡) | `Common/Base/MKDocPageViewController`,5 个 VC 都继承它,只配数据不写 UI |
| 联系方式 row | `Common/Views/MKContactRowCell` |
| 静态 URL(隐私/服务/官网/客服邮箱) | 都从 `Common/Manager/MKAppConfigManager.sharedManager.currentAppConfig` 取(`policyHref` / `agreementHref` / `conditionsHref` / `officialWebsiteUrl` / `appEmail`) |
| 头像 + 菜单 row UI | 走 Pencil 节点数据,主入口 VC 内手写 |
| 反馈表单提交 | 走 `MKNetworkManager` `/app/v3/feedback/...`,文件附件走 `uploadFile:` |

## 主入口路由规则

`MKProfileViewController` 菜单项点击走 NSIndexPath switch,**不要在 cell 里写跳转**。常见 row 类型:

- About / Privacy / Agreement / Help 等静态 → push 对应 Doc VC
- 联系客服 → push `MKProfileContactViewController`
- 反馈 → push `MKProfileFeedbackViewController`
- 官网复借 → push `MKProfileOfficialReloanViewController`
- 注销账号 → 弹 `MKBottomSheetView` 确认 + 走注销接口

## AppConfig 依赖

Profile 多页面**强依赖** `MKAppConfigManager.currentAppConfig` 的 URL 字段:

- 任意 Profile VC 进入前若 `hasAppConfig == NO` → 主动 `loadConfigWithCompletion:` 拉一次再渲染
- 不要假设 Home 已经拉过(用户可能直接从 KYC 完成深链进 Profile)

## UI 铁律

- 主入口顶部 hero 区: Pencil 出色 + 头像位置
- Doc 页统一卡片配色: 灰底 `kColorCardSecondary` + 圆角 14
- 客服邮箱长按可复制(`UIPasteboard`)
- 反馈表单 send 成功 → push `MKResultView` 通用结果页, 不要单独画

## 资源

- `mk_me_header_bg.imageset` 个人中心顶部背景
- `mk_money_bag` `mk_signin_shield` 等菜单图标

## 跨模块依赖

- → `Common`(全部 Doc 基类 + AppConfig + WebView + Bottom sheet 弹窗 + Result view)
- → `KYC/MKKYCBankCardEditViewController`(若菜单里有"更换银行卡"入口)
- → `Order/MKOrderListViewController`(若菜单里有"我的订单"快捷入口)
- 跨模块 push 仅创建对方 VC, 不读对方内部 model

## 新项目接入提示

- **必检** AppConfig URL 字段:上线前 `policyHref` / `agreementHref` / `appEmail` / `officialWebsiteUrl` 都要由后端按本项目配齐, 前端不写死
- 反馈接口路径、注销接口路径每个项目可能不同, 改 Feedback VC 顶部接口常量即可
- Doc 页内容(关于我们/还款须知 文本)走 AppConfig 或独立 doc 接口, **不要硬编码段落到代码**
