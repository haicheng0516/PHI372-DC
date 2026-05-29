# CLAUDE.md — Modules(业务模块)

每个模块按四目录组织:

```
ModuleName/
├── Cell/         # UITableViewCell / UICollectionViewCell
├── Controller/   # UIViewController(MKBaseViewController 子类)
├── Model/        # 数据模型(手写 init from dict, 不用 YYModel / Mantle)
└── View/         # 自定义视图(UIView 子类)
```

## 模块清单(必读对应 CLAUDE.md)

| 模块 | 关键 VC | 主要职责 |
|---|---|---|
| [Login](./Login/CLAUDE.md) | `MKSignInViewController` | 手机+OTP 登录 / 注册一体 |
| [KYC](./KYC/CLAUDE.md) | `MKKYCBaseViewController` + 8 子页 | 4 步表单 + 证件拍照 + 活体 + 银行卡 |
| [Home](./Home/CLAUDE.md) | `MKHomeViewController` | 单 VC 多 userStatus 切态 + 5 接口 + 弹窗优先级队列 + 好评引导 |
| [Product](./Product/CLAUDE.md) | `MKProductApplyViewController` | 单 VC + `selectionMode` flag 同时承载多/单金额申请 |
| [Order](./Order/CLAUDE.md) | `MKOrderListViewController` + `MKOrderDetailViewController` | 4 桶列表 + 单 VC 多 status 详情 |
| [Profile](./Profile/CLAUDE.md) | `MKProfileViewController` + 6 子页 | 个人中心 + 5 个 Doc 页 |

## 命名

- 所有类前缀 `MK`(模板默认, Phase 2 提升时统一替换为项目前缀)
- 文件名带模块名: `MKOrderListViewController.m` `MKKYCPersonalViewController.m`
- View 类带 `View` 后缀(除非是 `Card` / `Cell` / `Bar` 等明确语义)

## 新增模块清单

1. 建 `Cell/Controller/Model/View` 四个子目录(空目录用 `.gitkeep` 占位)
2. 在模块根放 `CLAUDE.md` 写本模块独有约定(见下面的范式)
3. 更新 `../../CODE_MAP.md` 顶层模块表

## 模块 CLAUDE.md 范式(每个模块按此 6 段写)

下次给某个模块写 CLAUDE.md 时遵循:

1. **VC 清单** — 表格列出每个 VC + 一句话职责 + 基类
2. **状态机 / 字段规则** — 业务核心契约(单 VC 多状态的分支表 / picker 级联 / 字段显隐规则)
3. **接口清单** — 涉及的 `/app/v3/*` 路径表 + 关键 Model 名
4. **UI 铁律** — Pencil 节点引用 / 配色 / 字号 / 特殊布局约束
5. **跨模块依赖** — 我用 `Common/` 的哪些 / 跟哪些模块 push 串 / 谁会 push 我
6. **新项目接入提示** — 哪些配置 / 资源 / 文案需要按本项目调

模块 CLAUDE.md 写法目标:**让下个项目接手时翻这一个文件就能补完该模块的业务**, 不必读源码反推。

## 模块间约定

- 模块**禁止互相 import 内部 Model / View / Cell 类型**
- **跨模块路由 push** 允许(直接 `pushViewController:` 创建对方 VC 即可),不要建路由层(工程体量没必要)
- **跨模块数据交换**走 `Common/Manager/*Manager` 或 `NSNotification`,不要直接读对方 model
- 复用 UI 组件**优先放 `Common/Views/`**, 不要在某个模块的 `View/` 里放被其他模块需要的东西
  - 例外:`MKLoanProductHeroView` 物理在 `Product/View/` 但 Order 详情也用 — 因体积较大且与 Apply 高度绑定, 保留不移
