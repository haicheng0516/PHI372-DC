# CLAUDE.md — Product(产品申请页)

## VC

| VC | 职责 |
|---|---|
| `MKProductApplyViewController` | **单 VC + `selectionMode` flag** 同时承载多金额/单金额两种态;`initWithTermData:mode:` 构造,Home/复借统一通过它接入 Apply |

## selectionMode 两种态

| Mode | 含义 | UI 差异 |
|---|---|---|
| `MKLoanAmountSelectionModeMultiple` | `amountDetailList.count > 1` | Hero amount 右侧 chevron + 点击弹 amount picker |
| `MKLoanAmountSelectionModeSingle` | `amountDetailList.count == 1` | Hero amount 静态文本,无 chevron;只能选 term |

由 Home/复借在 push 前根据 `termV3` 返回的 list 长度自行判定,不在 Product 内做。

## 关键规则

- **切 amount 自动重置 term**(不同金额可选期限不同,旧 term 不一定还可选)
- **term chevron 独立按 `currentAmount.termDetailList.count > 1` 显隐**(单一期限不显示 chevron,也不可点)
- **5 行明细**(本金/期限/利息/服务费/到手):
  - 千分位走 `Common/Category/NSString+MKAmount.mk_formattedPesoAmount`
  - 服务费 fee **取整**(不保留小数)
- amount/term 选择走 `Common/Views/MKBottomSheetView` 对应枚举,**不要新建 picker**

## 接口

| 路径 | 用途 |
|---|---|
| `/app/v3/payAccountInfo/list` | 获取用户已绑的支付账户(进入 Apply 时拉,确定有可收款账户才能下单) |

主 termV3 接口在 Home 入口(`/app/v3/product/termV3`)已请求过, Product 仅消费 `termData`。

## UI 铁律

- 所有坐标 / 字号 / 颜色取自 Pencil 节点(`b4hMw0` 多金额态 / `LbSVz` 单金额态)
- Hero 卡走 `View/MKLoanProductHeroView`(带 Full / Compact 两种变体)
- 产品 logo 走 `Common/Category/UIImageView+MKProductLogo mk_setProductLogoURL:fallbackColor:`(失败保留主色色块,不要白方块)
- 5 行明细单元走 `View/MKDetailRow` + `View/MKDetailRowsView` 拼装
- Repayment plan 按钮走 `View/MKRepaymentPlanButton` + `View/MKRepaymentPlanCell`
- 底部固定 Apply 区走 `View/MKLoanApplyBottomBar`
- Disclaimer 灰字走 `View/MKFeedbackDescCell`
- Loan info 头部走 `View/MKLoanInfoCell`

## 提交后

提交成功 → push 订单详情(`Order/MKOrderDetailViewController initWithOrderId:`)由 status 决定后续 UI,**不要在 Product 模块写订单后续 UI**。

## 验收铁律

申请页改动**必须 idb e2e 跑** [[feedback-test-apply-flow-e2e]]:

1. 点 Apply Now
2. 走完授权(系统定位弹 → 通讯录弹 → 二次自定义弹)
3. 看到 Success(push Order detail)

`xcodebuild` 通过 ≠ 完成。

## 跨模块依赖

- → `Common/Manager/MKSeamlessOrderManager`(提交时调度授权 + 提交)
- → `Common/Manager/MKReloanFlowHandler`(复借决策)
- → `Common/Manager/MKRejectFlowCoordinator`(termV3 错误码 6234303 触发拒量 H5,走 1 行 `if (code == 6234303 && [Coord presentRejectH5FromVC:self]) return;`)
- → `Order/MKOrderDetailViewController`(提交成功后 push)
- → `KYC/*`(若用户未 KYC, SeamlessOrderManager 会反向 push KYC 第 1 步)

## 新项目接入提示

- Hero 卡的 amountSubLabel 文案(如 "Loan amount" / "可借金额")每个项目按 Pencil 改
- Disclaimer 文案、Repayment plan 文案以本项目 Pencil/产品给的版本为准, 不要带任何上一个项目的副本
- amount/term picker 弹窗类型(`MKBottomSheetTypeAmountPicker` / `MKBottomSheetTypeTermPicker`)已封装, 直接调
