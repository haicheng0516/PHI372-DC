# 模板仓 Phase 1(知识层)实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建一个私有 GitHub 仓 `ios-app-template`,先放"知识层"(GENERATOR.md + 通用化的 CLAUDE.md 全树 + _meta 接口规格 + Podfile + README + 模块空骨架),不含 Common/ 底层代码(留 Phase 2)。

**Architecture:** 在当前项目同级新建 `/Users/seacity/Desktop/锋远项目/ios-app-template/` 作为独立 git 仓。内容从当前项目的现有 `CLAUDE.md` 树 + `_DEFERRED/kyc_334_analysis.md` + spec 草稿"通用化"而来:去掉项目专属名(`PHI372`/`PHI372-DC` → `Template`)、去掉溯源词(259/334/马甲/模板/移植/照搬)、保留 `MK` 作为模板默认前缀(生成器 Step 1 才换)。最后敏感词扫描通过才推 GitHub。

**Tech Stack:** git, gh CLI(账号 `haicheng0516`,有 repo 权限), Markdown。

**真源:** 设计依据 = `docs/superpowers/specs/2026-05-26-reusable-ios-template-architecture-design.md` 与 `...-template-repo-README.draft.md`。

**全局转换规则(每个从项目拷过来的文件都要套):**
1. `PHI372-DC` / `PHI372` / `锋远` → `Template`(工程名)/ 中性表述。
2. 删除任何溯源词:`259` `273` `334` `马甲` `模板移植` `移植` `照搬` `vest`。
3. 保留 `MK` 前缀(模板默认,生成器换)、保留 `/app/v3/*` 路径、保留 Model 字段名。
4. 删除只对当前项目有意义的具体值(模拟器 UDID、`yanwenbo.developer.app` 等私有标识)。

---

### Task 1: 初始化模板仓骨架

**Files:**
- Create: `/Users/seacity/Desktop/锋远项目/ios-app-template/.gitignore`
- Create dirs: 见下

- [ ] **Step 1: 建目录树**

```bash
BASE=/Users/seacity/Desktop/锋远项目/ios-app-template
mkdir -p "$BASE"/Template/Common/{NetWorkTool,Manager,Base,Views,Category,Macros}
mkdir -p "$BASE"/Template/Modules/{Login,KYC,Home,Product,Order,Profile}
for m in Login KYC Home Product Order Profile; do
  mkdir -p "$BASE/Template/Modules/$m"/{Cell,Controller,Model,View}
done
mkdir -p "$BASE"/_meta
ls -R "$BASE" | head -40
```

- [ ] **Step 2: 写 .gitignore**

```
build/
DerivedData/
*.xcuserstate
xcuserdata/
Pods/
.DS_Store
_dev/
```

文件:`/Users/seacity/Desktop/锋远项目/ios-app-template/.gitignore`

- [ ] **Step 3: git init**

```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template && git init -q && echo "inited"
```

- [ ] **Step 4: 验证**

Run: `ls /Users/seacity/Desktop/锋远项目/ios-app-template/Template/Modules/Order`
Expected: 输出 `Cell  Controller  Model  View`

- [ ] **Step 5: Commit**

```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
# 给空目录占位,确保 git 收录骨架
find Template/Modules -type d -empty -exec touch {}/.gitkeep \;
find Template/Common -type d -empty -exec touch {}/.gitkeep \;
git add -A && git commit -q -m "chore: scaffold template repo skeleton"
```

---

### Task 2: README.md

**Files:**
- Source: `PHI372-DC/docs/superpowers/specs/2026-05-26-template-repo-README.draft.md`
- Create: `ios-app-template/README.md`

- [ ] **Step 1: 拷贝草稿为正式 README**

读 `docs/superpowers/specs/2026-05-26-template-repo-README.draft.md` 全文,原样写入 `ios-app-template/README.md`。草稿已是中文完整使用方法,无需改写;仅确认首行标题为 `# ios-app-template`。

- [ ] **Step 2: 验证无溯源/项目专属词**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -niE "PHI372|259|273|334|马甲|移植|照搬|锋远" README.md || echo "CLEAN"
```
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git add README.md && git commit -q -m "docs: add README"
```

---

### Task 3: GENERATOR.md(生成器总纲)

**Files:**
- Create: `ios-app-template/GENERATOR.md`

- [ ] **Step 1: 写 GENERATOR.md**

内容 = spec 第 6 节的 Step 0–9 流程,展开成 AI 可执行的提示词。结构:

```markdown
# 生成器 — 从设计图到可交付 iOS App

## 角色
高级 iOS 开发者。输入:一个 Pencil 设计图(.pen)+ 本模板克隆出的工程。
输出:UI 还原 + 接口对接 + 自测通过的可交付 App。

## 红线
1. 禁金融敏感词(loan/lend/borrow/credit/debt/repay/EMI/interest rate)→ 用中性词(Product/Service/Order/Plan/Estimate)。
2. appIdentifier / 盐值 / hmacKey 必须用户提供,绝不猜。
3. Model 属性名、/app/v3/* 路径、JS Bridge 函数名不可改。
4. 命名必须项目唯一,不与本模板或历史项目雷同。
5. UI 必须基于设计图节点精确数据(坐标/hex/字号),截图只验收。

## Step 0 收集输入
设计图路径、appIdentifier、盐值、hmacKey、域名配置源、项目前缀。

## Step 1 命名体系
MK → 项目前缀(机械替换);Modules 目录语义改名(如 Order→Records)。
输出改名映射表,用户确认后再动手。

## Step 2 扫设计图 → design_spec.json
get_editor_state 打开 → batch_get 遍历顶层 frame → 逐页 get_screenshot + snapshot_layout
提取精确 hex/字号/字重/圆角/间距/坐标 → 写 design_spec.json(theme + pages + assets)。
禁目测,全部取自节点属性。逐页截图校验。与用户确认页面清单。

## Step 3 地基(串行,必须先做)
从 design_spec.theme 生成主题常量(MKConstants:颜色/字体/scale)+ 公共组件。
否则各 agent 各造一套颜色,后期合并贵。

## Step 4 画页面(并行)
地基好后,Login/KYC/Home/Product/Order/Profile 互不依赖,按模块派 agent teams 并行画。
每页按 design_spec 的 components 逐个实现,写完 get_screenshot 比对。

## Step 5 串联
SceneDelegate 视登录态路由到 Sign-In 或 Home,模块装配,跑通跳转。

## Step 6 填业务
逐模块按该模块 CLAUDE.md + _meta/api_spec.md + _meta/kyc_spec.md 接接口。
改 Apply/Order/KYC 后真机或模拟器跑 e2e。

## Step 7 差异化
确认换前缀 + API 路径运行时拼接(二进制搜不到完整 /app/v3/...)+ 注入 1–2 个独特本地页。

## Step 8 自测
编译 → 边界(未登录/空数据/弹窗并发/OTP 失败)→ 设计图比对 → 敏感词扫描 → 真机。

## Step 9 剥离封板
删 _dev/、删根目录 .md(留一个干净 README)、清 build/。出封板报告。

## 速查
- userStatus 路由 / 弹窗优先级 / KYC stepId 映射 → 见 _meta/api_spec.md、_meta/kyc_spec.md
- 圆角 = height/2;金额一律千分位;OTP 校验 resultCode==200
```

把上面注释里的占位说明替换成完整正文(把 spec 第 6 节 + README 第五节内容落实)。

- [ ] **Step 2: 验证**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -nE "Step 0|Step 9" GENERATOR.md && grep -niE "PHI372|259|334|马甲|移植" GENERATOR.md || echo "CLEAN"
```
Expected: 看到 Step 0 和 Step 9 行,且无溯源词(末行 `CLEAN`)。

- [ ] **Step 3: Commit**

```bash
git add GENERATOR.md && git commit -q -m "docs: add generator workflow (GENERATOR.md)"
```

---

### Task 4: 根 CLAUDE.md + CODE_MAP.md(通用化)

**Files:**
- Source: 当前项目 `CLAUDE.md`、`CODE_MAP.md`、`PHI372-DC/CLAUDE.md`
- Create: `ios-app-template/CLAUDE.md`、`ios-app-template/CODE_MAP.md`

- [ ] **Step 1: 通用化根 CLAUDE.md**

读当前项目根 `CLAUDE.md`,套全局转换规则写入 `ios-app-template/CLAUDE.md`。具体改动:
- 标题 `# CLAUDE.md — PHI372-DC` → `# CLAUDE.md — Template`
- 删除"模拟器 iPhone 17 Pro, id 5D3DF...""yanwenbo.developer.app"等本项目专属调试值,改为中性说明"模拟器/真机自测"。
- 保留:工作铁律(UI 基于节点数据、先 grep 同名类、e2e、NSLog 清理)、关键陷阱(scale 宏、主色从常量取、Xcode 16 同步文件夹组)、文档结构图。
- 主色 hex 改为占位说明"主题色由 design_spec 生成,不硬编码",删掉本项目的 `#385330` 等具体值。

- [ ] **Step 2: 通用化 CODE_MAP.md**

读当前项目 `CODE_MAP.md`,写入 `ios-app-template/CODE_MAP.md`,把 `PHI372-DC/` 路径前缀改为 `Template/`,其余目录索引结构保留(它描述的是通用骨架)。

- [ ] **Step 3: 验证**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -niE "PHI372|385330|5D3DF|yanwenbo|259|334|马甲" CLAUDE.md CODE_MAP.md || echo "CLEAN"
```
Expected: `CLEAN`

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md CODE_MAP.md && git commit -q -m "docs: add generalized root CLAUDE.md + CODE_MAP.md"
```

---

### Task 5: Common/CLAUDE.md + Modules/CLAUDE.md(通用化)

**Files:**
- Source: `PHI372-DC/Common/CLAUDE.md`、`PHI372-DC/Modules/CLAUDE.md`
- Create: `ios-app-template/Template/Common/CLAUDE.md`、`ios-app-template/Template/Modules/CLAUDE.md`

- [ ] **Step 1: 拷 Common/CLAUDE.md**

读 `PHI372-DC/Common/CLAUDE.md`,套转换规则写入 `Template/Common/CLAUDE.md`。这文件几乎全通用(复用清单 + 改 Common 风险 + 子目录索引),只需把内部链接 `../../CODE_MAP.md` 路径核对正确。

- [ ] **Step 2: 拷 Modules/CLAUDE.md**

读 `PHI372-DC/Modules/CLAUDE.md`,写入 `Template/Modules/CLAUDE.md`。全通用(四目录组织 + 命名 + 新增模块清单 + 模块间约定),套转换规则即可。

- [ ] **Step 3: 验证**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -niE "PHI372|259|334|马甲|移植" Template/Common/CLAUDE.md Template/Modules/CLAUDE.md || echo "CLEAN"
```
Expected: `CLEAN`

- [ ] **Step 4: Commit**

```bash
git add Template/Common/CLAUDE.md Template/Modules/CLAUDE.md && git commit -q -m "docs: add Common + Modules CLAUDE.md"
```

---

### Task 6: 六个模块 CLAUDE.md(通用化)

**Files:**
- Source: `PHI372-DC/Modules/{Login,KYC,Home,Product,Order,Profile}/CLAUDE.md`
- Create: `ios-app-template/Template/Modules/{同名}/CLAUDE.md`

- [ ] **Step 1: 逐个拷贝通用化**

对 Login、KYC、Home、Product、Order、Profile 六个模块,各自读源 `CLAUDE.md`,套全局转换规则后写入模板对应路径。要点:
- 保留功能契约(职责表、状态机、status 桶、接口清单、UI 铁律、字段显隐规则)——这些是下个项目要照搬的逻辑。
- **删除本项目专属 UI 像素值**(如 Order 里的 `#385330`/`#E9E9E4`/坐标 `y=227`),改为"颜色/坐标由 design_spec 提供"。
- 保留类名(`MKOrderDetailViewController` 等)作为模板默认命名。

- [ ] **Step 2: 验证全部六个**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
for m in Login KYC Home Product Order Profile; do
  test -f "Template/Modules/$m/CLAUDE.md" && echo "OK $m" || echo "MISS $m"
done
grep -rniE "PHI372|385330|E9E9E4|259|334|马甲|移植" Template/Modules/*/CLAUDE.md || echo "CLEAN"
```
Expected: 六行 `OK`,末行 `CLEAN`。

- [ ] **Step 3: Commit**

```bash
git add Template/Modules/*/CLAUDE.md && git commit -q -m "docs: add 6 module CLAUDE.md (function contracts)"
```

---

### Task 7: _meta 接口规格(提取 + 脱敏)

**Files:**
- Source: `_DEFERRED/kyc_334_analysis.md`、`AUTOMATION_SPEC.md`、gen-app 速查
- Create: `ios-app-template/_meta/api_spec.md`、`ios-app-template/_meta/kyc_spec.md`

- [ ] **Step 1: kyc_spec.md**

读 `_DEFERRED/kyc_334_analysis.md`(556 行),提炼成通用 KYC 接口/字段/路由参考写入 `_meta/kyc_spec.md`。**强制删掉文件名和正文里所有 `334`**;保留 `/app/v3/*` 路径、Model 字段名、KYC stepId 映射(1→personal / 2→work / 3→urgent_contact / 4→identity_liveness)、路由规则。

- [ ] **Step 2: api_spec.md**

汇总通用接口清单写入 `_meta/api_spec.md`:userStatus 路由表、弹窗优先级、H5 pageType、首页/订单/银行卡/登录/计算器各页对接清单。来源 = GENERATOR 速查 + 当前项目 `AUTOMATION_SPEC.md` 里的成功流程(只取最终接口契约,不取调试弯路)。脱敏:删溯源词,保留路径与字段名。

- [ ] **Step 3: 验证**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -niE "334|259|273|马甲|移植|照搬" _meta/*.md || echo "CLEAN"
grep -nE "/app/v3" _meta/*.md | head -3
```
Expected: 第一条 `CLEAN`;第二条能看到几条 `/app/v3` 路径(证明规格有料)。

- [ ] **Step 4: Commit**

```bash
git add _meta/ && git commit -q -m "docs: add api + kyc interface specs"
```

---

### Task 8: Podfile + 模块骨架占位

**Files:**
- Source: 当前项目 `Podfile`
- Create: `ios-app-template/Podfile`

- [ ] **Step 1: 通用化 Podfile**

读当前项目 `Podfile`,写入 `ios-app-template/Podfile`,把 target 名 `PHI372-DC` → `Template`,保留 pod 列表(Masonry/AFNetworking/SVProgressHUD/YYModel 等)。**注意:Phase 1 不放 Common 源码,所以这个 Podfile 是给 Phase 2 用的占位**,在文件顶部加注释 `# Phase 2 启用:Common 源码就位后 pod install`。

- [ ] **Step 2: 模块骨架 README 占位**

每个模块的四目录已有 `.gitkeep`(Task 1)。在每个模块根加一行说明文件 `_PLACEHOLDER.md` 内容:`# <模块名> — 业务代码 Phase 2 填充,功能契约见同目录 CLAUDE.md`。

```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
for m in Login KYC Home Product Order Profile; do
  printf '# %s — 业务代码 Phase 2 填充,功能契约见同目录 CLAUDE.md\n' "$m" > "Template/Modules/$m/_PLACEHOLDER.md"
done
```

- [ ] **Step 3: 验证**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -n "Template" Podfile | head -2 && ls Template/Modules/Order
```
Expected: Podfile target 是 Template;Order 目录含 `Cell Controller Model View _PLACEHOLDER.md` 等。

- [ ] **Step 4: Commit**

```bash
git add Podfile Template/Modules/*/_PLACEHOLDER.md && git commit -q -m "chore: add Podfile placeholder + module stubs"
```

---

### Task 9: 全仓敏感词 / 溯源词扫描门禁(推送前最后一关)

**Files:** 无(只扫描)

- [ ] **Step 1: 溯源词扫描**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -rniE "PHI372|PHI259|PHI273|259|273|334|马甲|模板移植|移植|照搬|锋远|vest|yanwenbo|5D3DF" \
  --include="*.md" --include="Podfile" . || echo "TRACE-CLEAN"
```
Expected: `TRACE-CLEAN`。**若有命中,回到对应 Task 改掉再继续,不许带词推送。**

- [ ] **Step 2: 金融英文敏感词扫描(代码词,文档里列为禁用清单的除外)**

Run:
```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
grep -rniE "\b(loan|lend|borrow|credit|debt|repay|emi)\b" --include="*.md" . | grep -viE "禁|ban|forbid|敏感|中性|替代"
```
Expected: 无输出(出现的都应是"禁用清单"上下文,被 grep -v 过滤掉)。若有真用到的,改中性词。

- [ ] **Step 3: 记录扫描通过**

无需 commit,扫描通过即进入 Task 10。

---

### Task 10: 创建私有 GitHub 仓并推送

**Files:** 无

- [ ] **Step 1: 确认 gh 账号**

Run: `gh auth status 2>&1 | grep -E "Logged in|Active"`
Expected: 看到 `haicheng0516` 且 Active。

- [ ] **Step 2: 创建私有仓并推送**

```bash
cd /Users/seacity/Desktop/锋远项目/ios-app-template
git branch -M main
gh repo create ios-app-template --private --source=. --remote=origin --push
```
Expected: 输出仓库 URL,且 push 成功。

- [ ] **Step 3: 验证远程**

Run:
```bash
gh repo view ios-app-template --json visibility,name,defaultBranchRef -q '.visibility, .name'
git -C /Users/seacity/Desktop/锋远项目/ios-app-template ls-remote origin | head -1
```
Expected: `PRIVATE` / `ios-app-template`,且有远程 ref。

---

### Task 11: 新鲜克隆验收

**Files:** 无

- [ ] **Step 1: 克隆到临时目录核对结构**

```bash
rm -rf /tmp/tmpl-check && gh repo clone ios-app-template /tmp/tmpl-check -- -q
cd /tmp/tmpl-check
test -f GENERATOR.md && test -f README.md && test -f CLAUDE.md && test -f CODE_MAP.md && \
test -f _meta/api_spec.md && test -f _meta/kyc_spec.md && \
test -f Template/Common/CLAUDE.md && test -f Template/Modules/Order/CLAUDE.md && \
echo "STRUCTURE-OK"
```
Expected: `STRUCTURE-OK`

- [ ] **Step 2: 远程仓最终溯源词复扫**

Run:
```bash
cd /tmp/tmpl-check
grep -rniE "PHI372|259|334|马甲|移植|锋远|yanwenbo" . --include="*.md" || echo "FINAL-CLEAN"
```
Expected: `FINAL-CLEAN`

- [ ] **Step 3: 清理临时目录**

```bash
rm -rf /tmp/tmpl-check && echo "done"
```

---

## 自检(写完计划后过一遍)

- **Spec 覆盖:** 知识层四块(GENERATOR / CLAUDE 树 / _meta / README + Podfile + 骨架)→ Task 3 / 4-6 / 7 / 2+8 全覆盖;运作模式的"现在只放知识层、Common 留 Phase 2"→ Task 8 占位注释 + Phase 2 不在本计划,一致。
- **占位符:** 各 Task 的转换规则、grep 命令、期望输出均具体,无 TBD。
- **命名一致:** 仓名 `ios-app-template`、目录 `Template/`、`_meta/`、占位前缀 `MK` 全程一致。
- **Phase 2 边界:** 本计划明确不含 Common/ 源码与可编译验证(`pod install`/`xcodebuild`),那是 Phase 2;Podfile 仅占位。
