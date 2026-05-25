# CLAUDE.md — Profile(个人中心)

## VC

| VC | 职责 |
|---|---|
| `MKProfileViewController` | 主入口(头像/菜单列表) |
| `MKProfileAboutViewController` | 关于我们 |
| `MKProfileAgreementViewController` | 协议列表(隐私/服务/许可…) |
| `MKProfileContactViewController` | 联系客服 |
| `MKProfileFeedbackViewController` | 意见反馈 |
| `MKProfileOfficialReloanViewController` | 复借入口 |
| `MKProfileRepaymentInfoViewController` | 还款信息说明 |

## 约定

- 协议/About 等静态内容走 **`Common/Views/MKWebViewViewController`**,URL 在 `Common/Macros/MKConstants.h`
- 上线前 URL(隐私政策、服务协议、官网、客服邮箱)必须按本工程实际地址配置
- 菜单项点击走 NSIndexPath switch,不要在 cell 里写跳转逻辑

## 头部资源

- `mk_me_header_bg.imageset` — 个人中心顶部背景
- `mk_money_bag` `mk_signin_shield` 等 — 菜单图标
