# CLAUDE.md — Order(订单)

## VC

| VC | 职责 |
|---|---|
| `MKOrderListViewController` | 列表页;**4 个 section 桶,默认全部展开**;cell 点击按 status 分发到详情或拒量 H5 |
| `MKOrderDetailViewController` | **单 VC + orderStatus 整数驱动 UI**。**绝对不要再拆出** Reviewing / WaitRepay / PendingWithdraw / Overdue 等多 VC |
| `MKOrderRepayViewController` | 还款页(Bill / Dragonpay 引导) |
| `MKOrderSubmitViewController` | 提交申请页(列表"已提交申请"分支的占位/详情) |

## Status 桶(`Model/MKOrderStatusMapper`)

| Section | orderStatus | UI chip 文案 | chip 色 |
|---|---|---|---|
| Submit Application | `10` `20` `32` `36` | Unfinished / To be withdrawn / Change bank account | `#532C6E` / `#0A7F93` / `#6E1758` |
| Processing | `30` `50` | Under review / Loan processing | `#11722E` / `#527217` |
| Pending Repayment | `60` `61` `63` | Pending Repayment / Overdue | (实际色见 Mapper) |
| Completed | `31` `70` `71` `99` | Reject / Pay off / Cancel | (实际色见 Mapper) |

**改 chip 文案 / 色都必须改 Mapper, 不在 VC 散写 if/else**。

## 详情页规则(单 VC 多状态)

`MKOrderDetailViewController` 由 `orderStatus` 驱动**所有**UI 差异:

| 维度 | 规则 |
|---|---|
| 卡片底色 | `30` 审核 `#11722E` / `60+` 待还 `#AF5D00` / `32` 待提 `#0A7F93` / `61` 逾期 `#A0721B` / `36` 改卡 `#6E1758` |
| 右上状态文案 | 同 Mapper |
| 明细行数 | 审核中(`30`) / 待提现(`32`) → 5 行;待还款(`60+`) / 逾期(`61`) → 10 行 |
| 字段显隐 | `payoutDate` 存在 → 隐藏申请时间, 仅显放款时间;减免 / 已还无值则隐藏;`Amount Due` 仅 `60/61/63` 显, 70 结清不显;`Deferment charge` 仅 `61` + 有值显 |
| 底部按钮 | `32` Withdraw / `60+61+63` Repay (+Defer if 61) / `10/20` Continue → 触发 `performDataCapture` / `36` Modify Bank Card / 其他 None |
| status==32 额外 | chain `/app/v3/order/withdrawn/detail` 拉 amountDetailList(可选金额 + 期限) → Hero 紧凑卡 + amount/term 可选 |

底部按钮 mode 由 `MKOrderDetailBottomBar +modeForOrderStatus:` 集中推导, **不在 VC 散写**。

字段显隐由 `buildRowsForStatus:info:` 集中产出, **不在 cell 散判 nil/空**。

行隐藏时详情卡**自动收缩高度**(`relayoutBody`)。

## 接口

| 路径 | 用途 |
|---|---|
| `/app/v3/order/list` | 列表数据 |
| `/app/v3/order/detail` | 详情数据(`Model/MKOrderDetailModel`) |
| `/app/v3/order/withdrawn/detail` | `status==32` 时拉可选金额+期限(`Model/MKWithdrawnDetailModel`) |
| `/app/v3/order/...repay` | 还款相关 |

详情页支持**特殊 orderId `@"1"`**:后端识别为"按 productId 取最新订单",前端 push 时通过 `vc.productId = ...` 透传:

```objc
MKOrderDetailViewController *vc = [[MKOrderDetailViewController alloc] initWithOrderId:@"1"];
vc.productId = productId;
[nav pushViewController:vc animated:YES];
```

## 列表页拒量触发

cell 点击且 `orderStatus == 31`(已拒)→ 走拒量 H5,**优先于**详情页:

```objc
if (m.orderStatus == 31 && [MKRejectFlowCoordinator presentRejectH5FromVC:self]) return;
MKOrderDetailViewController *detail = [[MKOrderDetailViewController alloc] initWithOrderId:m.orderId];
detail.productId = m.productId;
[self.navigationController pushViewController:detail animated:YES];
```

## UI 铁律

- UI **以 Pencil 为准**, PRD 提到但 Pencil 没画的字段**不要加**(避免凭空脑补)
- 主色: 顶部绿 `kColorPrimary`(`#385330`),详情卡 `kColorCardSecondary`(`#E9E9E4`),分割线 `#D1D1CF`
- 黄色 Repayment plan 横条与 hero 底部 56pt 重叠(设计约束 y=227, hero y=112..283)
- Hero 紧凑卡走 `Common/Views/MKLoanProductHeroView configureCompactAppName:termText:amountText:statusText:`(布局在 View 类的 `layoutCompact`)
- 列表 accordion 收缩高 57,展开高 `48 + 131 * N`(N=子卡数)

## 入口

- 列表点 cell → `MKOrderDetailViewController initWithOrderId:`
- Home 提现拦截 → 同上(`initWithOrderId:@"1"` + `productId`),**不要弹独立 Withdraw VC**
- Profile 快捷入口 → `MKOrderListViewController`(若菜单含此项)

## 跨模块依赖

- → `Common/Manager/MKRejectFlowCoordinator`(列表 cell `status==31` 触发拒量)
- → `Common/Views/MKLoanProductHeroView`(详情页 Hero 紧凑卡 — 此 View 物理位置在 `Product/View/` 但跨模块用, 不要复制)
- ← `Home/MKHomeViewController`(提示卡点击 / 提现拦截 push)
- ← `Profile/MKProfileViewController`(若含订单快捷入口)
- ← `Product/MKProductApplyViewController`(提交成功后 push)

## 新项目接入提示

- chip 颜色映射(`MKOrderStatusMapper.colorForStatus:`)按本项目 Pencil 调
- 字段显隐规则跨项目通用(基于 `orderStatus` 整数), 后端语义一致就不要改
- 黄条/Hero 重叠的 56pt 量按本项目 Pencil 复核, 不沿用旧值
