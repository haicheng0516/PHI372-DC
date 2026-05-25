# CLAUDE.md — Modules(业务模块)

每个模块按四目录组织:

```
ModuleName/
├── Cell/         # UITableViewCell / UICollectionViewCell
├── Controller/   # UIViewController(MKBaseViewController 子类)
├── Model/        # 数据模型(手写 init from dict,不用 YYModel/Mantle)
└── View/         # 自定义视图(UIView 子类)
```

## 命名

- 所有类前缀 `MK`
- 文件名带模块名: `MKOrderListViewController.m` `MKKYCPersonalViewController.m`
- View 类带 `View` 后缀(除非是 Card/Cell/Bar 等明确语义)

## 新增模块清单

1. 建 `Cell/Controller/Model/View` 四个子目录(空目录用 `.gitkeep` 占位)
2. 在模块根放 `CLAUDE.md` 写本模块独有约定(状态映射、特殊路由、UI 规则)
3. 更新 `../../CODE_MAP.md` 顶层模块表

## 模块间约定

- 模块**禁止互相 import 内部类型**。跨模块通信走 Common 或 NSNotification
- 路由跳转在 Controller 里直接 `pushViewController:`,不要建路由层(工程体量没必要)
- 复用 UI 组件优先放 `Common/Views/`,不要在某个模块的 View/ 里放被其他模块需要的东西
