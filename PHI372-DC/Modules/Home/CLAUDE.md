# CLAUDE.md — Home(首页)

## VC

| VC | 职责 |
|---|---|
| `MKHomeViewController` | 主首页:**单 VC 多状态**;按 `/user/suphome` 的 `userStatus` 切两种态 |
| `MKHomeBankCardViewController` | 换绑银行卡(用户主动入口) |

## userStatus 切态

| userStatus | UI | 备注 |
|---|---|---|
| `10` | 装饰图 + 底部 Apply Now | 未 KYC;点 Apply → 走 KYC 流程 |
| `100 / 20` | 装饰图 + 产品列表(suphome 决定提示文案) | 无单/审核中;不允许进订单列表 |
| `51` | 装饰图 + 提示条点击 → 触发拒量 H5 | 已拒;走 `MKRejectFlowCoordinator presentRejectH5FromVC:` |
| 其他(`30+ / 60+` 等) | 产品列表 + 顶部提示条 | 有进行中订单;提示条点击 push `MKOrderListViewController` |

## 启动接口序列(`viewWillAppear` 触发 5 个)

| 顺序 | 路径 | 用途 |
|---|---|---|
| 1 | `/app/v3/app/version` | 强更检查(失败码 `2009006` → 弹强更框) |
| 2 | `/app/v3/app/config` | 拉全局配置(rejectH5 / feedbackGuidance / 协议链接等) |
| 3 | `/app/v3/user/suphome` | 拉首页态(`userStatus` / `appUserType` / `promptCopy` / `withdrawalOrderId`) |
| 4 | `/app/v3/product/list` | 产品卡列表 |
| 5 | `/app/v3/user/info` | 用户基本信息(name / phone) |

进入 Apply 时另外:

| 路径 | 用途 |
|---|---|
| `/app/v3/product/termV3` | 拿产品的 amount / term 列表后 push `MKProductApplyViewController` |
| `/app/v3/kyc/four/status` | 若未 KYC, 进入 KYC 之前先查状态 |
| `/app/v3/product/state` | 复借提示卡的产品状态(loanAmount / productName / logo) |

## 弹窗优先级队列

启动后弹窗冲突走 `pendingAlertQueue`,优先级:

1. **强更框**(任意接口返回 `resultCode == 2009006` 或 `/app/version` 返回需更新) — 最高
2. **提现拦截**(若 suphome 返回 `withdrawalOrderId.length > 0` 即 `status == 32`) — 弹一次性"您有待提现订单"框, Know More 直跳 `MKOrderDetailViewController initWithOrderId:`
3. **复借提示**(`MKReloanFlowHandler requestProductStateAndShowTipWithProductId:sheetType:`) — 一次启动只弹一次, 用 `sHasShownReloanTipThisLaunch` 守卫

冲突时 `flushPendingAlertsIfNeeded` 按优先级 dispatch。

## 好评引导

从下单成功页 pop 回 Home 时(`viewDidAppear`),调 `MKRatingPromptManager consumePendingFlag` 决定是否弹:

- 一次性守卫(`hasShownPrompt` 全局只弹一次)
- `feedbackGuidance == "0"` → 关
- `feedbackGuidance == "2"` → 仅老客(`appUserType == 2`)
- `>= 4 ★` → `SKStoreReviewController` 系统评分
- `< 4 ★` → `MKBottomSheetTypeRatingSuccess` 感谢页

## 拒量触发(2 处)

| 触发点 | 条件 |
|---|---|
| `applyProductAtIndex:` termV3 返回 `code == 6234303` | `if (code == 6234303 && [MKRejectFlowCoordinator presentRejectH5FromVC:wself]) {}` |
| `handleNoticeTap` 提示卡点击且 `userStatus == 51` | `if (status == 51 && [MKRejectFlowCoordinator presentRejectH5FromVC:self]) return;` |

## 提现拦截

`showExistingOrderAlertWithProductId:` 跳详情时, 对后端约定 `orderId=@"1"` 表示"按 productId 取最新订单":

```objc
MKOrderDetailViewController *vc = [[MKOrderDetailViewController alloc] initWithOrderId:@"1"];
vc.productId = productId;
```

详情页内部识别这个特殊值,自动按 productId 反查最新单。

## UI 铁律

- 所有坐标走 Pencil 节点(Banner 卡 / 4 个 Icon Grid / 产品卡 / KYC 提示卡)
- 产品 logo 走 `Common/Category/UIImageView+MKProductLogo mk_setProductLogoURL:fallbackColor:`(失败保留主色色块)
- 顶部提示条 `MKHomeNoticeCell` 文案直接走 `promptCopy` 字段,不做翻译
- KYC 提示卡走 `View/MKHomeKYCTipCardView`(仅 `userStatus == 10` 显)
- 渐变背景 / banner 顶部走 `View/MKHomeHeaderView`

## 资源

`Assets.xcassets/`:
- `mk_home_banner.imageset`
- `mk_home_partners.imageset`(合作伙伴 logo 群)
- `mk_logo_cic` `mk_logo_npc` `mk_logo_pis` `mk_logo_sec` 各 partner

## 跨模块依赖

- → `Common/Manager/MKAppConfigManager`(拉全局配置, 写回 `currentAppConfig`)
- → `Common/Manager/MKSeamlessOrderManager`(订单提交全流程, 监听 `MKSeamlessOrderDataCaptureCompletedNotification` 刷新首页)
- → `Common/Manager/MKReloanFlowHandler`(复借提示卡)
- → `Common/Manager/MKRejectFlowCoordinator`(2 处拒量触发)
- → `Common/Manager/MKRatingPromptManager`(好评引导)
- → `Product/MKProductApplyViewController`(点产品 → push)
- → `Order/MKOrderDetailViewController` / `Order/MKOrderListViewController`(提示卡点击 / 提现拦截 push)
- → `KYC/MKKYCPersonalViewController` 等(未 KYC 用户点 Apply → push)

## 验收铁律

首页改动**必须真机或模拟器跑 e2e**:启动 → 看 5 接口都 `resultCode==200` → 装饰图/产品列表正确 → 点 Apply 走完授权链。

## 新项目接入提示

- 顶部 banner 图(`mk_home_banner`)按 Pencil 重出
- 合作伙伴 logo 按本项目实际合作机构换(`mk_home_partners` + `mk_logo_*`)
- userStatus 路由分支(`10/51/100/20/...`)是后端语义, 跨项目通用, 不要改
