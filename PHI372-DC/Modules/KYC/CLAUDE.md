# CLAUDE.md — KYC 实名认证

## 8 步流程

| 步骤 | VC | 接口前缀 |
|---|---|---|
| 1 个人信息 | `MKKYCPersonalViewController` | `/app/v3/kyc/personal` |
| 2 证件信息 | `MKKYCIDViewController` | `/app/v3/kyc/id` |
| 3 证件拍照 | `MKKYCIDCameraViewController` | 端内 OCR |
| 4 活体 | `MKKYCLivenessViewController` | 第三方 SDK |
| 5 财务/家庭 | `MKKYCFinanceViewController` | `/app/v3/kyc/finance` |
| 6 紧急联系人 | `MKKYCContactViewController` | `/app/v3/kyc/contact` |
| 7 还款方式 | `MKKYCPaymentViewController` | `/app/v3/kyc/payment` |
| 8 银行卡 | `MKKYCBankCardEditViewController` | `/app/v3/kyc/bankCard` |

所有子页继承 `MKKYCBaseViewController`(自带顶部进度条 + 底部 Next 按钮)。

## 关键规则

- 步骤推进**由后端返回的 next route 决定**,不要在前端硬编码顺序
- 进入 KYC 的状态机由 `MKReloanFlowHandler` + `MKSeamlessOrderManager` 决定

## 数据抓取(Data Capture)

KYC 完成后服务端可能要求抓取通讯录/位置 → 走 `MKSeamlessOrderManager`:

- 首次定位拒绝: 静默停留(不弹任何东西)
- 首次通讯录拒绝: 返回上层
- 不要在 KYC VC 里写权限逻辑,统一交给 `MKSeamlessOrderManager`

## 字段差异化

KYC 字段/选项(婚姻状态/教育/收入档)以后端返回 enum 为准,Model 在本模块 `Model/` 下,先核对接口返回再调整 enum。
