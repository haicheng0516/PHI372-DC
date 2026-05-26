# ios-app-template

> iOS 应用通用底座 — Objective-C + UIKit + Masonry。
> 一套可编译的空壳工程 + 底层能力库 + 全套提示词 + 生成器流程。
> 新项目从这里克隆,换符号、按设计图重画 UI、按提示词填业务,即可交付。

---

## 目录

1. [这是什么](#一这是什么)
2. [前置依赖](#二前置依赖)
3. [仓库结构](#三仓库结构)
4. [快速开始](#四快速开始)
5. [完整生成流程](#五完整生成流程step-09)
6. [分层与复用原则](#六分层与复用原则)
7. [差异化规范](#七差异化规范)
8. [交付前的清理](#八交付前的清理)
9. [常见陷阱](#九常见陷阱)

---

## 一、这是什么

这个仓库**不是某个具体 App**,而是所有同类 App 的共同底座。它包含三样东西:

- **可编译的空壳工程** — clone 下来 `pod install` 就能编过,跑起来是空首页。
- **底层能力库(`Common/`)** — 网络、加密、公共参数、设备指纹、登录态、订单状态机、复借决策、22+ 底部弹窗、基类、常量。这些不用重写,直接用。
- **提示词系统(各 `CLAUDE.md` + `GENERATOR.md`)** — 告诉 AI 每个模块该怎么实现、接口怎么接、UI 铁律是什么。

每个新项目 = 克隆本仓 → 换符号 → 按新设计图重画 UI → 按提示词填业务逻辑 → 清理后交付。

---

## 二、前置依赖

| 依赖 | 说明 |
|---|---|
| Xcode 16+ | 工程用 `PBXFileSystemSynchronizedRootGroup`(文件落到物理目录即自动入工程) |
| CocoaPods | `pod install` 装依赖 |
| Pencil + Pencil MCP | 读设计图、导出精确坐标/颜色/字号 |
| Figma 本地文件 | 设计来源,导入 Pencil 后由 MCP 解析 |
| Claude Code | 跑生成器流程 |

> 设计图本地路径:把 Figma 导出的 `.pen` 文件准备好,生成器第一步会问你要路径。

---

## 三、仓库结构

```
ios-app-template/
├── README.md            # 本文件
├── GENERATOR.md         # 生成器总纲(AI 跑哪几步)
├── Template.xcodeproj   # 占位工程名
├── Podfile
├── Template/
│   ├── AppDelegate / SceneDelegate / main.m / Info.plist
│   ├── Base.lproj/LaunchScreen.storyboard
│   ├── Common/          # ← 底层,克隆即用
│   │   ├── NetWorkTool/ Manager/ Base/ Views/ Category/ Macros/
│   │   └── CLAUDE.md
│   └── Modules/         # ← 业务空骨架 + 提示词
│       ├── Login/ KYC/ Home/ Product/ Order/ Profile/
│       └── CLAUDE.md
└── _meta/               # 接口规格(不进生成的工程)
    ├── api_spec.md
    └── kyc_spec.md
```

- `Common/` = 不变的底层,只机械换前缀。
- `Modules/<X>/` = 每个模块四目录(`Cell/Controller/Model/View`)+ 一个 `CLAUDE.md` 功能契约。
- `_meta/` = 接口路径、Model 字段对照、KYC 路由的权威参考,只给 AI 看,不打进工程。

---

## 四、快速开始

```bash
# 1. 克隆,改成新项目名
git clone <本仓地址> MyNewApp
cd MyNewApp
rm -rf .git && git init        # 断开与模板仓的历史

# 2. 装依赖,确认空壳能编过
pod install
open MyNewApp.xcworkspace      # 编译跑通 = 底座没问题

# 3. 准备好设计图 .pen 和加密三件套,交给 AI 跑生成器
```

然后对 Claude Code 说:**「按 GENERATOR.md 生成新项目」**,它会逐步引导你走完下面的流程。

---

## 五、完整生成流程(Step 0–9)

> 完整提示词在 `GENERATOR.md`。这里是给人看的概览。

| 步骤 | 做什么 | 你要提供/确认 |
|---|---|---|
| **Step 0 收集输入** | 设计图路径、`appIdentifier`、签名盐值、`hmacKey`、域名配置源、项目前缀 | 加密三件套**必须你给,AI 不许猜** |
| **Step 1 命名体系** | `MK` → 你的项目前缀;`Modules` 目录语义改名 | 确认改名映射表后再动手 |
| **Step 2 扫设计图** | Pencil MCP 逐页读出精确 hex/字号/坐标 → `design_spec.json` | 确认页面清单、哪些页不做 |
| **Step 3 地基** | 从 `design_spec` 生成主题常量(色/字体/scale)+ 公共组件 | — |
| **Step 4 画页面(并行)** | 按模块派多个 agent 并行画独立页面 | — |
| **Step 5 串联** | SceneDelegate 路由 + 模块装配,跑通跳转 | — |
| **Step 6 填业务** | 逐模块按各 `CLAUDE.md` + `_meta/api_spec` 接接口 | 真机/模拟器跑 e2e |
| **Step 7 差异化** | 确认换前缀 + API 路径运行时拼接 + 注入 1–2 个独特页 | 选哪些独特页 |
| **Step 8 自测** | 编译 → 边界条件 → 设计图比对 → 敏感词扫描 → 真机 | 重点场景真机测 |
| **Step 9 剥离封板** | 删 `_dev/`、清脚手架、出封板报告 | 交付干净包 |

**铁律(每个项目都要守):**

- UI 必须基于设计图节点的精确数据(坐标/hex/字号),截图只用于验收,不用于反推。
- 新建 Model / 弹窗 / Manager 前先 `grep` 同名类,底座已预置 22+ 弹窗和合并式 Model,禁止平行实现。
- 改 Apply / Order / KYC 后必须真机或模拟器跑 e2e,`xcodebuild` 通过 ≠ 完成。
- 调试用的 `NSLog` 修完 bug 必须删干净,commit 前 `grep -n "NSLog"` 确认 0 残留。
- 代码里禁出现金融敏感词(loan/lend/borrow/credit/debt/repay/EMI/interest rate),用中性词(Product/Service/Order/Plan/Estimate)替代。

---

## 六、分层与复用原则

| 层 | 内容 | 复用方式 |
|---|---|---|
| **Layer 0 底层 `Common/`** | 网络/加密/公参/设备指纹/登录态/状态机/弹窗/基类/常量 | **原样克隆**,只机械换前缀,逻辑不动 |
| **Layer 1 业务 `Modules/`** | 各功能页面 | UI 按新设计图重画;业务逻辑按 `CLAUDE.md` 提示词重建 + 语义改名 |

**复用清单(先用现成的,别新建):**

| 需求 | 用现成的 |
|---|---|
| 弹窗/选择器/Alert | 底部弹窗框架枚举(22+ 类) |
| 订单状态机(首单 + 复借通用) | 订单状态机 Manager |
| 复借决策 | 复借决策 Handler |
| 网络请求(签名/加密/公参在内) | 网络 Manager + 公共参数 |
| 金额格式化(千分位/取整) | 金额 Category |
| 登录态/用户信息 | 登录 Manager + 用户态 |
| 颜色/字体/scale | 常量头文件,**不要硬编码** |

---

## 七、差异化规范

兼顾"复用同一套逻辑"与"Apple 4.3 必须区分":**复用逻辑结构,区分符号、UI、路径。**

| 层 | 差异化手段 |
|---|---|
| 底层 | `MK` → 项目专属前缀,sed 式机械替换 |
| 业务 | 目录 + 类名语义改名;UI 按新设计图重画;代码风格微调 |
| API 路径 | 运行时拼接,二进制里搜不到完整 `/app/v3/...`,每项目拆法不同 |
| 资源/配置 | Asset 命名、`Info.plist`、文案字符串逐项目区分 |
| 独特功能 | 每项目注入 1–2 个其它项目没有的本地页面(如计算器/日历/FAQ) |

---

## 八、交付前的清理

所有工作产物都关在 `_dev/` 里;交付时一键删掉,只留可编译工程。

| 类别 | 例子 | 交付时 |
|---|---|---|
| 输入/验收素材 | 设计图原始导出、截图、图片 | 删 |
| 工作过程 | 进度、任务计划、调研笔记 | 删 |
| 知识/提示词 | 各 `CLAUDE.md`、`CODE_MAP.md`、流程记录 | 删(本就在模板仓) |
| 编译产物 | `build/` | 删(已 gitignore) |
| **成品** | 工程源码 + `Pods` + `.xcodeproj` | **留** |

交付给上架者的应该是一个**只有工程 + Pods + 源码**的干净包,看不到任何"底座来源"的痕迹。

---

## 九、常见陷阱

1. SceneDelegate 下悬浮窗/window 需传 `windowScene`。
2. 自定义字体需 `Info.plist` 的 `UIAppFonts` 注册。
3. OTP 发送必须校验 `resultCode == 200`。
4. 圆角按钮 `cornerRadius = height / 2`。
5. 金额一律千分位格式化。
6. 启动屏走纯 `LaunchScreen.storyboard`,不写启动 VC、不靠定时器跳转。
7. Xcode 16 同步文件夹组:文件落到物理目录即入工程,**不要手 patch `project.pbxproj`**。
8. `scale` 宏基于 375 设计稿宽,所有坐标必须用它包。
9. 模块间禁止互相 import 内部类型,跨模块通信走 `Common` 或通知。
10. 改底层接口前先 `grep` 全部引用,底层一改可能 break N 个模块。
