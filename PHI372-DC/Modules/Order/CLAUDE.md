# CLAUDE.md — Order(订单)

## 关键 VC

| VC | 职责 |
|---|---|
| `MKOrderListViewController` | 列表页,按 orderStatus 分 4 个 section,**默认全部展开** |
| `MKOrderDetailViewController` | **单 VC + orderStatus 驱动 UI**。绝对不要再拆出 Reviewing/WaitRepay/PendingWithdraw 等多 VC |
| `MKOrderRepayViewController` | 还款页 |
| `MKOrderSubmitViewController` | 提交申请页 |

## Status 桶(`Model/MKOrderStatusMapper`)

| Section | orderStatus |
|---|---|
| Submit Application | 10, 20, 32, 36 |
| Pending Repayment | 60, 61, 63 |
| Processing | 30, 50 |
| Completed | 31, 70, 71, 99 |

## 详情页规则

- **status==32(待提现)**: chain `/app/v3/order/withdrawn/detail` 拿可选金额/期限,UI 走 hero 紧凑卡 + 期限/金额可选
- 字段显隐按 status 决定 → 见 `MKOrderDetailViewController.buildRowsForStatus:info:`
- 行隐藏时 detail 卡片**高度自适应**(`relayoutBody`)
- 底部按钮 mode 由 `MKOrderDetailBottomBar +modeForOrderStatus:` 推导,不要在 VC 里散写 if/else

## UI 铁律

- UI 以 **Pencil 为准**。PRD 提到但 Pencil 没画的字段**不要加**
- 主色: 顶部绿 `#385330`,详情卡 `#E9E9E4`,分割线 `#D1D1CF`
- 黄色 Repayment plan 横条与 hero 底部 56px 重叠(y=227,hero y=112..283)

## Hero 紧凑卡(`Common/Views/MKLoanProductHeroView`)

详情页用 `configureCompactAppName:termText:amountText:statusText:`,坐标见 View 类的 `layoutCompact`。

## 入口

- 列表点 cell → `MKOrderDetailViewController initWithOrderId:`
- Home 提现拦截 → 同上(**不要弹独立 VC**)
