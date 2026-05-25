# CLAUDE.md — Home(首页)

## VC

| VC | 职责 |
|---|---|
| `MKHomeViewController` | 主页: banner + 合作伙伴 + 产品入口 + 提现拦截 |
| `MKHomeBankCardViewController` | 换绑银行卡(用户主动入口) |

## 提现拦截

首页加载时若用户有 status==32 订单,弹提示后 push **`MKOrderDetailViewController(orderId:)`** — 走详情页统一处理,不要弹独立 Withdraw VC。

## 产品入口

点产品 cell → push `MKProductApplyViewController`,product 信息走接口拿,Home 这边只传 productId。

## 资源

banner / 合作伙伴 logo 都在 `Assets.xcassets`:
- `mk_home_banner.imageset`
- `mk_home_partners.imageset`
- `mk_logo_cic` `mk_logo_npc` `mk_logo_pis` `mk_logo_sec`(各 partner)
