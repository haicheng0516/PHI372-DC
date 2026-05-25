# CLAUDE.md — Product(产品申请)

## VC

`MKProductApplyViewController` — **单 VC + `selectionMode` flag**(amount/term)

## 规则

- 切 amount 自动重置 term(因为不同金额可选期限不同)
- term 右箭头独立按 `termList.count > 1` 显隐(单一期限不显示 chevron)
- 5 行明细:**千分位 + fee 取整**(走 `NSString+MKAmount`)
- amount/term 选择走 `MKBottomSheetView`(对应枚举,不要新建 picker)

## 验收铁律

申请页改动**必须 idb e2e 跑**:

1. 点 Apply Now
2. 走完授权(定位 → 通讯录)
3. 看到 Success

`xcodebuild` 通过 ≠ 完成。

## 提交后

提交成功 → push 订单详情(`MKOrderDetailViewController(orderId:)`)由 status 决定后续 UI,不要在 Product 模块写订单后续 UI。

## 跨模块依赖

- 状态机: `Common/Manager/MKSeamlessOrderManager`(提交时调度授权+提交)
- 复借: `Common/Manager/MKReloanFlowHandler`(决定是否跳 KYC)
