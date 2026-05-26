# 可复用 iOS 应用架构 — 设计文档

- 日期:2026-05-26
- 状态:已确认,待落地
- 适用:iOS 借贷类 App,Objective-C + UIKit + Masonry

---

## 1. 背景与问题

当前单个项目里同时混着三类东西,导致难维护、难复用、交付不干净:

1. **可复用资产** — 网络/加密/公参/设备指纹、登录态、订单状态机、复借决策、22+ 弹窗、基类、常量。
2. **知识/提示词** — 根 `CLAUDE.md`、`CODE_MAP.md`、各模块 `CLAUDE.md`、接口规格。
3. **工作垃圾 + 成品混放** — `_figma_raw/`、`_screenshots/`、`images/`、`_DEFERRED/`、`progress.md`、`task_plan.md`、`findings.md`、`build/` 与真正要交付的工程源码混在一起。

目标:把"逻辑 + 提示词 + 可编译空壳"沉淀成一个**长期维护的通用模板仓**,放到 GitHub;每个新项目从它克隆、换符号、按新设计图重画 UI、按提示词填业务,最后剥离脚手架交付一个干净工程。

> 已有的 `gen-app` skill 是给 **H5AppCoreKit(Swift + WebView)** 的,与本项目的 **OC 原生全页面** 不是同一套。新架构以 `GENERATOR.md` 取代它,避免误用。

---

## 2. 已确认的关键决策

| # | 决策点 | 选择 |
|---|---|---|
| 1 | 逻辑代码复用形态 | **分层混合**:底层原样克隆,业务层提示词重建 + 改名 |
| 2 | GitHub 仓库内容 | **可编译的空壳工程**:clone 完能直接 `pod install` 编过,再填业务 |
| 3 | UI 生成节奏 | **先地基后并行**:先串行落地主题常量 + 公共组件,再按模块派 agent 并行画页面 |
| 4 | 差异化方式 | **每项目换前缀 + 目录名**:底层机械换前缀,业务层语义改名 |

---

## 3. 架构总览:两个仓库,职责分离

| 仓库 | 性质 | 内容 | 谁看 |
|---|---|---|---|
| **`ios-app-template`**(GitHub,私有) | 通用、长期维护 | 可编译空壳 + 底层代码 + 全套 .md 提示词 + 生成器 skill | 只有你 |
| **每个新项目**(如本项目) | 一次性、交付物 | 从模板生成,填完业务,**剥离所有 dev 产物** | 交付给上架的人 |

下个项目的生命周期:`clone 模板 → 跑生成器 → 填业务 → 一键剥离 → 交付`。模板仓永不含任何具体项目的痕迹。

---

## 4. 模板仓布局(分层混合 + 可编译空壳)

```
ios-app-template/
├── README.md                    # 完整使用方法(中文,见独立草稿)
├── GENERATOR.md                 # 生成器总纲(skill 入口提示词)
├── Template.xcodeproj           # 占位工程名,生成时改
├── Podfile                      # Masonry / AFNetworking / SVProgressHUD / YYModel
├── Template/
│   ├── AppDelegate / SceneDelegate / main.m / Info.plist
│   ├── Base.lproj/LaunchScreen.storyboard   # 纯启动屏,无 VC
│   ├── Common/                  # ← Layer 0:底层,克隆即用(仅机械换前缀)
│   │   ├── NetWorkTool/         #   网络 / 加密 / 公参 / 设备指纹 / 校验
│   │   ├── Manager/             #   登录态 / 订单状态机 / 复借决策
│   │   ├── Base/                #   基类 VC / Cell / 导航栈
│   │   ├── Views/               #   底部弹窗框架(22+ 弹窗)+ 通用组件
│   │   ├── Category/  Macros/   #   金额格式化 + 常量(主题占位)
│   │   └── CLAUDE.md            #   「先复用别新建」清单
│   └── Modules/                 # ← Layer 1:业务,空四目录骨架 + 提示词
│       ├── Login/   (Cell/Controller/Model/View + CLAUDE.md)
│       ├── KYC/     (同上)
│       ├── Home/  Product/  Order/  Profile/
│       └── CLAUDE.md
└── _meta/                       # 接口规格(不进生成的工程)
    ├── api_spec.md              #   /app/v3/* 路径 + Model 字段对照表
    └── kyc_spec.md              #   KYC 接口 / 字段 / 路由 canonical 参考
```

**分层含义:**

- **Layer 0 `Common/`** — 网络/加密/公参/设备指纹等纯技术代码,Apple 不会判雷同,**整段克隆**,只做机械前缀替换。
- **Layer 1 `Modules/`** — 业务页面。空骨架 + 每目录一个 `CLAUDE.md` 提示词。UI 每次按新设计图重画(天然不同),业务逻辑按提示词重建 + 语义改名。

---

## 5. 提示词系统(.md = 可复用知识层)

三级 `CLAUDE.md`,把当前结构通用化(抽掉具体项目的硬编码值):

```
GENERATOR.md          → 生成器跑哪几步(取代旧 gen-app skill)
Common/CLAUDE.md      → 底层有什么、先复用别新建
Modules/<X>/CLAUDE.md → 每个模块的「功能提示词」:
                        职责 / 状态机 / 接口清单 / UI 铁律 / 字段显隐规则
```

每个模块 `CLAUDE.md` 是**功能契约**,不含 UI 像素值(像素来自当次 `design_spec.json`)。

例 — `Order/CLAUDE.md`:「单 VC + orderStatus 驱动 UI;4 个 status 桶;底部按钮 mode 由 mapper 推导,不在 VC 散写 if/else」。这套逻辑下个项目照搬,只换颜色坐标。

---

## 6. 生成器工作流(GENERATOR.md 步骤)

```
Step 0  收集输入:Figma/.pen 路径、appIdentifier/盐值/hmacKey、域名源、项目前缀
Step 1  命名体系:MK→项目前缀(机械)+ Modules 目录语义改名(差异化),输出映射表待确认
Step 2  扫 Pencil → design_spec.json(精确 hex/字号/坐标,禁目测)
Step 3  地基:从 design_spec 生成主题常量(主题色/字体/scale)+ 公共组件
Step 4  并行:按模块派 agent teams 画独立页面
Step 5  串联:SceneDelegate 路由 + 模块装配
Step 6  填业务:逐模块按 CLAUDE.md 提示词 + _meta/api_spec 接接口
Step 7  差异化:换前缀确认 + API 路径运行时拼接 + 注入 1-2 个独特页
Step 8  自测:编译 → 边界 → 设计图对比 → 敏感词扫描 → 真机
Step 9  剥离 + 封板(见第 8 节)
```

**第 4 步并行纪律:** 地基(主题常量 + 公共 Views)必须**先串行落地**,否则各 agent 各造一套颜色/组件,后期合并很贵。地基好之后,Login/KYC/Home/Order/Profile 互不依赖,可并行。

---

## 7. 差异化机制(每项目换前缀 + 目录名)

两档,按层施加,这是"直接复用"与"Apple 4.3 必须区分"的和解点:**复用逻辑结构,区分符号、UI、路径**。

| 层 | 做法 | 强度 |
|---|---|---|
| Layer 0 底层 | `MK` → 项目前缀(如 `XQ`),sed 式机械替换,逻辑不动 | 符号全变,结构相同(Manager/Model 相似可接受) |
| Layer 1 业务 | 目录 + 类名语义改名(`Order`→`Records`)+ UI 按新图重画 + 代码风格微调 | 天然差异化 |
| API 路径 | 运行时拼接,二进制搜不到完整 `/app/v3/...` | 每项目拆法不同 |

---

## 8. 项目卫生:成品 vs 脚手架

所有非交付物关进一个 `_dev/` 目录,交付时一键删掉。

| 散落物 | 归类 | 交付时 |
|---|---|---|
| `_figma_raw/`  `_screenshots/`  `images/` | 验收/输入素材 | `_dev/`,**删** |
| `_DEFERRED/`  `findings.md`  `progress.md`  `task_plan.md` | 工作过程 | `_dev/`,**删** |
| `AUTOMATION_SPEC.md` + 各 `CLAUDE.md` `CODE_MAP.md` | 知识/提示词 | 本就在**模板仓**,不进交付 |
| `build/` | 编译产物 | gitignore,**删** |
| `Template/` 源码 + `.xcodeproj` + `Pods` | **成品** | **留** |

生成器 Step 9 跑 `handoff` 脚本:删 `_dev/`、删根目录所有 `.md`(除一个干净 README)、清 `build/`。交付给上架者的就是一个**只有工程 + Pods + 源码**的干净包。

---

## 9. 非目标(Non-goals)

- 不做跨平台(只 iOS / OC / UIKit)。
- 不引入路由层 / 大型架构框架(工程体量不需要)。
- 不自动做二进制级混淆(可选,交用户用专业工具)。
- 不把 H5AppCoreKit(Swift)那套并进来。

---

## 10. 运作模式:单向提升 + 分阶段播种

**前提:当前项目尚未完成,架构还会继续优化。** 模板是"成品的提炼",所以不能现在冻死。

### 单向提升(promotion),永不回灌

- 项目开发期间:**当前项目是唯一真源**,模板仓是它的"已知最佳提炼"。
- 改进只能 **项目 → 模板** 单向推。**绝不**把模板的改动反向拉进正在开发的活项目(会打乱正在跑的 e2e)。
- 下个新项目时才从模板 `clone` 出来用。

### 分阶段播种

| 阶段 | 时机 | 往模板仓放什么 |
|---|---|---|
| **Phase 1 知识层**(现在) | 立即建私有仓 | `GENERATOR.md` + 各 `CLAUDE.md`(通用化)+ `_meta/`(api/kyc 规格)+ `Podfile` + `README` |
| **Phase 2 代码层**(后续) | 当前项目 `Common/` 稳定后 | 底层代码 + 可编译空壳;跑一次"提升",做前缀通用化(`MK` → 占位符) |
| **持续** | 每当某模块 `CLAUDE.md` 或底层在项目里稳定 | 单独提升该项改进上去 |

### 提升检查单(每次 Phase 2 / 持续提升时)

1. 抽掉本项目专属硬编码值(前缀、appId、盐值、域名、主题色坐标)。
2. 代码里换回占位符前缀,确认无具体项目痕迹。
3. 敏感词扫描(金融词 + 溯源词)。
4. 推到模板仓,**不动活项目**。

### GitHub

- 仓库:**私有**(复用 IP + 金融域)。
- 账号:`haicheng0516`(已认证,有 `repo` 权限)。

---

## 11. 一句话总结

模板仓承载"逻辑 + 提示词 + 可编译空壳";每个新项目从它克隆、换符号、按新图重画 UI、按提示词填业务、剥离脚手架后交付。
