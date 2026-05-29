# CLAUDE.md — KYC(实名认证)

实名认证流。**4 个表单步骤 + 1 个证件拍照 + 1 个活体 + 1 个支付绑定 + 1 个改卡**,共 8 个业务 VC + 1 个基类。

## VC

### 表单步骤(继承 `MKKYCBaseViewController`)

| VC | kycId | 接口 |
|---|---|---|
| `MKKYCPersonalViewController` | `personal` | `/app/v3/kyc/four/personal` |
| `MKKYCFinanceViewController` | `work_questionnaire` | `/app/v3/kyc/four/work` |
| `MKKYCContactViewController` | `urgent_contact` | `/app/v3/kyc/four/contact` |
| `MKKYCPaymentViewController` | (走子接口) | `/app/v3/payAccountInfo/save` |

四个表单页都走基类的"`search-iterm` 拉表单字段 → 渲染 → 提交"通用流程,**子类只需设 `kycId` + commit URL**。

### 证件 / 活体(独立 VC)

| VC | 用途 |
|---|---|
| `MKKYCIDViewController` | 证件类型选择(从 `search-iterm kycId=identity_liveness` 拉首个 `buttonList[0].buttonKey`) |
| `MKKYCIDCameraViewController` | 证件拍照(AVFoundation 自拉相机预览 + 取景框 + Ready/Captured 双态);**不继承基类**;通过 `onImageCaptured` block 回调 |
| `MKKYCLivenessViewController` | 活体认证(前置相机 + Ready/Captured);**不继承基类**;通过 `onLivenessCompleted` block 回调,上传 `/app/v3/kyc/four/liveness` |

### 其他

| VC | 用途 |
|---|---|
| `MKKYCBankCardEditViewController` | 修改/绑定银行卡;编辑模式必填 `bankCardBindId`,新增模式置 0 |

## 基类 `MKKYCBaseViewController`

封装:NavBar(深绿) + 顶部进度条(`View/MKKYCProgressBarView`) + UITableView + 底部固定 Continue 按钮。

子类只需:
1. 设 `kycId`(触发 `search-iterm` 拉表单)
2. 设 `progressPercent`(进度条进度)
3. 自定义 `continueAction`(提交回调)
4. 覆盖 `requestFormItems` 后渲染 `Cell/MKKYCInputCell` + `Cell/MKKYCPickerCell` + `Cell/MKKYCContactCombinedCell`

## 关键规则

- **步骤推进由后端 next route 决定**, 不要在前端硬编码顺序(后端给 `nextStep` 字段, 据此 push)
- **进入 KYC 的时机**由 `MKReloanFlowHandler` + `MKSeamlessOrderManager` 决定:
  - 首次 Apply 且 `userStatus == 10` → push Personal
  - 已有未完订单且需 KYC → 同上
- **KYC 字段(婚姻状态 / 教育 / 收入档 / 工作类型)以后端 `search-iterm` 返回 enum 为准**, 前端 `MKKYCItemModel` 是通用映射 model
- **省市级联**:走 `/app/v3/sys/province` + `/app/v3/sys/city`, 缓存到 picker, 不要为每次选省重发
- **联系人 KYC 已认证 name 自动填入** + Name 字段锁定不可编辑(`bankName` 排除)
- **Bank Account Type 级联**:选了 Account Type → 触发对应 list 接口填 Bank Name 选项

## 接口清单

| 路径 | 用途 |
|---|---|
| `/app/v3/kyc/four/search-iterm` | 拉表单字段(传 `kycId`) |
| `/app/v3/kyc/four/personal` | 提交个人信息 |
| `/app/v3/kyc/four/work` | 提交财务/家庭 |
| `/app/v3/kyc/four/contact` | 提交紧急联系人 |
| `/app/v3/kyc/four/liveness` | 上传活体图 |
| `/app/v3/payAccountInfo/list` | 已绑银行卡列表 |
| `/app/v3/payAccountInfo/payAccountItemList` | 收款方式 → 银行选项级联 |
| `/app/v3/payAccountInfo/save` | 保存/更新银行卡 |
| `/app/v3/sys/province` | 省份列表 |
| `/app/v3/sys/city` | 城市列表(传 provinceId) |
| `/app/v3/user/info` | KYC 完成后取用户 name(银行卡页自动填入用) |

## 数据抓取(Data Capture)

KYC 完成后服务端可能要求抓取通讯录/位置 → **统一走 `Common/Manager/MKSeamlessOrderManager`**:

- 首次定位拒绝:**静默停留**(不弹任何东西)
- 首次通讯录拒绝:返回上层
- **不要在 KYC VC 里写权限逻辑**,统一交给 `MKSeamlessOrderManager`

## UI 铁律

- 4 个表单页 cell 渲染走基类, **不在子 VC 手 layout**
- 证件拍照 / 活体走 AVFoundation 原生, 取景框走 mask + path(不要拿 UIImageView 占位)
- 进度条颜色 `kColorPrimary`,渐变背景走 Pencil 节点数据
- 拍照成功后 image 通过 block 回调上层, **VC 自己不发上传请求**(基类处理)

## 跨模块依赖

- → `Common/Manager/MKSeamlessOrderManager`(权限 + 上传 + 路由)
- → `Common/NetWorkTool/MKNetworkManager` `MKEncryptManager`(全部接口)
- → `Common/Views/MKBottomSheetView`(婚姻/教育/收入 picker 全走它)
- → `Common/Manager/MKLoginManager`(KYC 完成后写 isKycCompleted 标志)
- ← `Login/MKSignInViewController`(新用户首次登录 push Personal)
- ← `Home/MKHomeViewController`(`userStatus==10` 点 Apply 进入)
- ← `Profile/MKProfileViewController`(若菜单含"更换银行卡" → push `MKKYCBankCardEditViewController`)

## 验收铁律

KYC 改动**必须 idb e2e 跑** [[feedback-test-apply-flow-e2e]]:

1. 从未 KYC 用户登录(可走调试入口切号)
2. Apply → Personal → Finance → Contact → ID → IDCamera → Liveness → Payment
3. 完成全链路看到 Home 进入 `userStatus==100/20` 态

每一步换 page 后看返回值的 `nextStep` 字段, 不要靠前端假设。

## 新项目接入提示

- 表单字段都来自 `search-iterm` 接口, **不要把字段名硬编码到 model**, `MKKYCItemModel` 已是通用 map
- 证件类型(身份证/驾照/护照)按本项目实际地区改 `identity_liveness` 的选项映射
- 活体 SDK 若换厂(如换 Megvii / FaceID), 改 `MKKYCLivenessViewController` 一处即可, 其他页不受影响
- 拍照取景框尺寸 / 圆角按 Pencil 节点数据复核
