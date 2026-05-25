# AUTOMATION_SPEC.md — Figma → iOS 马甲包自动化生产流程

> **目的**：本文件是**给下一个 Claude session 的接力剧本**。任何 session 拿到本文件 + Figma URL + 模板项目路径，就能在不需要重新讨论方案的情况下，按步骤自动生产一个新的 iOS 马甲包项目。

## 1. 总览

### 1.1 输入参数
| 参数 | 示例 | 说明 |
|---|---|---|
| `FIGMA_URL` | `https://www.figma.com/design/xxx/...` | Figma 设计稿云端链接 |
| `FIGMA_FILE_KEY` | `wu0stGMF4bln3OP0V0t3mJ` | 从 URL 提取 |
| `TEMPLATE_PROJECT` | `/Users/seacity/Desktop/锋远项目/REXDC334` | 模板项目绝对路径 |
| `OUTPUT_PROJECT` | `/Users/seacity/Desktop/锋远项目/PHI373-XX` | 新项目空 Xcode 工程绝对路径 |
| `NEW_PREFIX` | `PX` / `MX` / `KP` 等双字母 | 类前缀，4.3 规避核心 |
| `NEW_BUNDLE_ID` | `com.px.phi372dc` | App Bundle ID |
| `NEW_APP_NAME` | `PHI372` | App 显示名 |

### 1.2 工具链
- **Figma MCP**：`mcp__figma__get_figma_data`（拿设计数据）、`mcp__figma__download_figma_images`（下切图）
- **Bash**：shell 脚本做文件复制 + sed 批量替换
- **Edit/Write**：写 OC 代码

### 1.3 输出
- 完整 Xcode 工程，可直接 Cmd+R 跑
- 60 个 ViewController 覆盖所有 Figma 页面
- 入口 TableView 菜单可逐个浏览
- 4.3 规避（中等强度）

---

## 2. 流程步骤（按 Phase 顺序）

> ⚠️ 本节随 Phase 推进而填充，当前为 skeleton。

### Phase 0：项目初始化校验

**Action 0.1：确认输入参数完整**
检查 6 个输入参数全部就位。

**Action 0.2：验证空工程结构**
```bash
ls $OUTPUT_PROJECT/{$APP_NAME}/{AppDelegate.h,SceneDelegate.h,ViewController.h,Info.plist,Assets.xcassets}
```

**Action 0.3：验证 Figma MCP 可达**
```
mcp__figma__get_figma_data(fileKey=$FIGMA_FILE_KEY, depth=1)
```
应返回 `metadata.name` + 顶层 canvas 节点。

---

### Phase 1：架构骨架移植（已验证 ✅）

**前置确认**：新工程 pbxproj 是否用 `PBXFileSystemSynchronizedRootGroup`（Xcode 15+ 默认）
```bash
grep PBXFileSystemSynchronizedRootGroup $OUTPUT_PROJECT/$NEW_APP_NAME.xcodeproj/project.pbxproj
```
若有 → 跳过 pbxproj 编辑步骤（放到目录里自动入编译）；
若无 → 需要 Ruby `xcodeproj` gem 或 Python `pbxproj` lib 添加引用。

**Action 1.1：复制 Common 目录**
```bash
cp -R "$TEMPLATE_PROJECT/$TEMPLATE_APP/Common" "$OUTPUT_PROJECT/$NEW_APP/Common"
```

**Action 1.2：批量改前缀 RD → $NEW_PREFIX**（大写）
```bash
cd "$OUTPUT_PROJECT/$NEW_APP/Common"
# 文件内容: RD<大写> → 新前缀<大写>
find . -type f \( -name "*.h" -o -name "*.m" \) -exec sed -i '' "s/RD\([A-Z]\)/$NEW_PREFIX\1/g" {} \;
# 文件名重命名
find . -type f \( -name "RD*" -o -name "*+RD*" \) | while read f; do
  newname=$(echo "$f" | sed -E "s/(\/|^)RD([A-Z])/\1$NEW_PREFIX\2/g; s/\+RD([A-Z])/+$NEW_PREFIX\1/g")
  [ "$f" != "$newname" ] && mv "$f" "$newname"
done
```

**Action 1.3：清理小写前缀和旧项目名**
```bash
# rd_keyWindow → mk_keyWindow (小写 helper 函数)
find . -type f \( -name "*.h" -o -name "*.m" \) -exec sed -i '' "s/rd_keyWindow/$(echo $NEW_PREFIX | tr A-Z a-z)_keyWindow/g" {} \;
# 旧项目名替换
find . -type f -exec sed -i '' "s/$TEMPLATE_APP_NAME/$NEW_APP_NAME/g" {} \;
```

**Action 1.4：修 G1 陷阱（MKConstants.h）**
把 `kScreenWidth/Height` 改用 `UIScreen.mainScreen.bounds`,而非 keyWindow。`kStatusBarHeight/kBottomSafeHeight` 保留 keyWindow（仅 viewWillAppear+ 才稳定使用）。

**Action 1.5：创建 BaseViewController**
在 `Common/Base/${NEW_PREFIX}BaseViewController.h/.m` 创建,包含：
- `MKNavBarStyle` 枚举：None/Transparent/Light
- `preferredStatusBarStyle` 按 navBarStyle 推断
- 自定义 customNavBar + 返回按钮 + 标题 label
- `onBackTapped` 默认 popVC

**Action 1.6：Defer 有外部依赖的文件**
```bash
mkdir -p "$OUTPUT_PROJECT/_DEFERRED"/{Manager,NetWorkTool,Views}
mv "$OUTPUT_PROJECT/$NEW_APP/Common/Manager"/* "$OUTPUT_PROJECT/_DEFERRED/Manager/"
mv "$OUTPUT_PROJECT/$NEW_APP/Common/NetWorkTool"/* "$OUTPUT_PROJECT/_DEFERRED/NetWorkTool/"
# 4 个 Views 有 Masonry/SDWebImage/反向引用依赖
mv "$OUTPUT_PROJECT/$NEW_APP/Common/Views/${NEW_PREFIX}AlertView".* "$OUTPUT_PROJECT/_DEFERRED/Views/"
mv "$OUTPUT_PROJECT/$NEW_APP/Common/Views/${NEW_PREFIX}DataCaptureMaskView".* "$OUTPUT_PROJECT/_DEFERRED/Views/"
mv "$OUTPUT_PROJECT/$NEW_APP/Common/Views/${NEW_PREFIX}DrawerController".* "$OUTPUT_PROJECT/_DEFERRED/Views/"
mv "$OUTPUT_PROJECT/$NEW_APP/Common/Views/${NEW_PREFIX}RepaymentPlanView".* "$OUTPUT_PROJECT/_DEFERRED/Views/"
rmdir "$OUTPUT_PROJECT/$NEW_APP/Common/Manager" "$OUTPUT_PROJECT/$NEW_APP/Common/NetWorkTool"
```

**Action 1.7：编译验证**
```bash
cd "$OUTPUT_PROJECT"
xcodebuild -project "$NEW_APP_NAME.xcodeproj" -scheme "$NEW_APP_NAME" -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
必须看到 `** BUILD SUCCEEDED **`。

---

### Phase 2：Design Token 提取（→ ${PREFIX}Constants.h）✅ 已验证

**Action 2.1：拉 Figma globalVars**
选 2-3 个代表性页面拉数据（Sign-in + Home + 任一 KYC 页通常已覆盖 90%+ 颜色）：
```
mcp__figma__get_figma_data(fileKey=$FIGMA_FILE_KEY, nodeId="3:1743", depth=3)  # Sign-in
mcp__figma__get_figma_data(fileKey=$FIGMA_FILE_KEY, nodeId="3:1786", depth=3)  # Home
```

**Action 2.2：汇总颜色映射**
解析 globalVars.styles, 把所有 `fill_XXX → '#hex'` 收集去重。
按用途分类（主色 / 背景 / 文字 / icon / 渐变）写成映射表。

**Action 2.3：覆写 ${PREFIX}Constants.h 色值**
保留宏名结构（`kColorPrimary` 等不变），只换 hex 值。
**老模板有但新设计未用到的颜色**：保留宏名,值设为新设计中最相近的颜色（兼容业务代码引用）。

**Action 2.4：写入字体精确规格**
为每个 Figma TextStyle 创建一个精确字体宏（如 `kFontPingFang14S`）,业务层调用更直观。
Poppins → 系统字体（接受 ~5-10% 差异）; PingFang SC → 系统默认（完美匹配）。

**Action 2.5：编译验证**
```bash
xcodebuild ... 2>&1 | grep -E "(error:|BUILD)"  # 必须 BUILD SUCCEEDED
```

**典型 token 表参考**：见同目录 findings.md > "颜色映射表（最终）" 节。


### Phase 3：60 frame 清单 + 模块映射
> 已在 findings.md > "60 个 Frame 清单" 完成初稿，Phase 3 执行时校对补全

### Phase 4：逐页 ViewController 生成（Login 已样板, 剩余 32 VC + 22 Modal 按 pattern 重复）

#### 4.1 单页生成 SOP（每个 VC 都走这 5 步）

**Step 1 — 拉数据**
```
mcp__figma__get_figma_data(fileKey=$FIGMA_FILE_KEY, nodeId="<nodeId>", depth=3 或 4)
```
拿到精确坐标 / 颜色 / 字体规格。

**Step 2 — 拆解组件**
按 findings.md "60 个 Frame 完整分类表" 决定该页面的：
- 是否长页 → 用 UITableView 还是 UIView
- NavBar 样式 → 在 VC.init 中赋值 navBarStyle
- 子视图划分 → 顶部 Header / 内容卡片 / 列表 Cell / 按钮组

**Step 3 — 建目录**
```bash
mkdir -p Modules/<Module>/{Controller,View,Cell,Model}
```

**Step 4 — 写文件（按依赖顺序）**
4a. 先写 View / Cell（叶子节点, 无依赖）
4b. 后写 ViewController（组装 View / Cell）

**Step 5 — 编译验证**
每个模块写完跑一次 xcodebuild, 必须 BUILD SUCCEEDED 再继续下一模块。

---

#### 4.2 文件模板（直接对照 Login 抄）

##### 模板 A: ViewController（极薄, 仅做组装 + 事件分发）

文件位置：`Modules/<Module>/Controller/MK<Name>ViewController.h/.m`

```objc
// .h
#import "MKBaseViewController.h"
@interface MK<Name>ViewController : MKBaseViewController
@end

// .m
#import "MK<Name>ViewController.h"
#import "MK<Name>CardView.h"           // 各子视图
#import "MKGradientBackgroundView.h"    // 通用渐变
#import "MKConstants.h"

@interface MK<Name>ViewController ()
@property (nonatomic, strong) MK<Name>CardView *cardView;
@end

@implementation MK<Name>ViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.navBarStyle = MKNavBarStyleNone | Trans | Light;  // 按 findings.md 表
        self.navTitle = @"页面标题";                            // 仅 Light 模式
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self bindActions];
}

- (void)setupViews {
    // 只做 alloc/init + frame + addSubview, 不写内部布局
    self.cardView = [[MK<Name>CardView alloc] initWithFrame:CGRectMake(...)];
    [self.view addSubview:self.cardView];
}

- (void)bindActions {
    __weak typeof(self) wself = self;
    self.cardView.onXxxTapped = ^{ /* Phase 9: 接业务 */ };
}
@end
```

##### 模板 B: 子视图 View（layout 全部在这里）

文件位置：`Modules/<Module>/View/MK<Name><Block>View.h/.m`

```objc
// .h
@interface MK<Name><Block>View : UIView
@property (nonatomic, copy, nullable) void (^onXxxTapped)(void);
@end

// .m
#import "MK<Name><Block>View.h"
#import "MKConstants.h"
#define S(v) ((v) * kScale)

@implementation MK<Name><Block>View

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kColorXxx;
        self.layer.cornerRadius = S(<r>);
        [self setupSubElements];
    }
    return self;
}

- (void)setupSubElements {
    // 子元素坐标 = Figma 原坐标减去本 View 在父中的偏移, 全部 S() 缩放
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(S(...), S(...), S(...), S(...))];
    lbl.text = @"...";
    lbl.font = kFontXxx;
    lbl.textColor = kColorXxx;
    [self addSubview:lbl];
    // ... 其他元素
}
@end
```

##### 模板 C: TableViewCell（长页面/列表用）

```objc
@interface MK<Name>Cell : UITableViewCell
+ (CGFloat)cellHeight;  // 设计稿固定高度
- (void)configureWithModel:(id)model;
@end
```

Cell 内 layout 与 View 模板一致, 在 initWithStyle:reuseIdentifier 中 setupSubElements。

##### 模板 D: Modal（22 个弹窗 → 统一一个 BottomSheet 类 + 枚举）

⚠️ **用户决策**: 22 个 modal 全部用**底部弹出**形式 (bottom sheet), 不是页面中心弹窗。所有 modal 复用同一个 `MKBottomSheetView` 类, 用枚举区分类型, 内部按类型 switch 构建内容。

文件位置：`Common/Views/MKBottomSheetView.h/.m`

```objc
// MKBottomSheetView.h
typedef NS_ENUM(NSInteger, MKBottomSheetType) {
    // 版本更新
    MKBottomSheetTypeForceUpdate,
    MKBottomSheetTypeNormalUpdate,
    // 个人中心
    MKBottomSheetTypeLogoutConfirm,
    MKBottomSheetTypeAccountDelete,
    MKBottomSheetTypeAccountDeleteSuccess,
    MKBottomSheetTypeAccountDeleteFail,
    // 通用
    MKBottomSheetTypeBackConfirm,
    MKBottomSheetTypeExistingOrder,
    MKBottomSheetTypeCommonPicker,
    // 产品申请
    MKBottomSheetTypeRatingGuide,
    MKBottomSheetTypeRatingSuccess,
    MKBottomSheetTypeProductReloan,
    MKBottomSheetTypeRepaymentPlan,
    // 订单
    MKBottomSheetTypeOrderReloan,
    MKBottomSheetTypeWithdrawPending,
    MKBottomSheetTypeWithdrawSuccess,
    MKBottomSheetTypeHomeReloan,
    // 权限二次确认
    MKBottomSheetTypePermissionCamera,
    MKBottomSheetTypePermissionLocation,
    MKBottomSheetTypePermissionContacts,
};

@interface MKBottomSheetView : UIView

+ (instancetype)sheetWithType:(MKBottomSheetType)type
                       config:(nullable NSDictionary *)config;

/// 在当前 keyWindow 弹出 (附 dim 蒙层 + 底部滑入动画)
- (void)show;
/// 关闭
- (void)dismiss;

@property (nonatomic, copy, nullable) void (^onConfirmTapped)(void);
@property (nonatomic, copy, nullable) void (^onCancelTapped)(void);
@end
```

**关键设计点**：
1. **底部滑入动画**: 初始 frame.y = kScreenHeight (屏幕外), `show` 时用 spring animation 上移到目标位置 (sheet.frame.height 顶到底部 + safeArea)。
2. **不同 type 不同高度**: `+heightForType:` 返回类型对应高度（如 `ForceUpdate` 高 380, `CommonPicker` 高 300）。
3. **dim 蒙层**: `show` 时给 keyWindow 加一个 `UIView` 全屏 `MKColorAlpha(0,0,0,0.5)`, 同步淡入。
4. **顶部圆角**: 仅 sheet 顶部两个角 `cornerRadius = S(20)`, 用 `CACornerMask` 限定 `kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner`。
5. **内容由 type switch 构建**: 私有方法 `_buildContentForType:(MKBottomSheetType)type config:config`, 内部按 type 添加 icon / 标题 / 文本 / 按钮组。
6. **拖动关闭** (可选): PanGesture 监听, 下拉 > 100pt 触发 dismiss。

**调用示例**：
```objc
MKBottomSheetView *sheet =
    [MKBottomSheetView sheetWithType:MKBottomSheetTypeLogoutConfirm config:nil];
sheet.onConfirmTapped = ^{ /* 执行退出 */ };
sheet.onCancelTapped  = ^{ /* 仅 dismiss */ };
[sheet show];
```

**文件数收益**：22 个独立 Modal 类 → 1 个 MKBottomSheetView 类，文件量从 ~50 降到 ~2。

---

#### 4.2.5 批量生成技巧（实战验证 — 节省 70% 时间）

写 32 个 stub VC、3+ 个 Profile 子页、3 个 Order 列表、3 个 Order 详情、2 个 KYC 拍照 等结构相似的 VC 时, **不要逐文件 Write**。改用 **Bash heredoc 批生成脚本**:

```bash
# 模板: 在脚本里循环, 用 EOF 写入每个 .m 文件
cat > "$DIR/MK<Name>ViewController.m" <<'EOF'
#import "MK<Name>ViewController.h"
#import "MKConstants.h"

@implementation MK<Name>ViewController
- (instancetype)init { if (self = [super init]) { self.navBarStyle = MKNavBarStyleLight; self.navTitle = @"<Title>"; } return self; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    // ... 实际布局
}
@end
EOF
```

**已验证的生成器脚本**（保存在 `_DEFERRED/scripts/`):
- `_gen_stubs.sh` — 34 个 VC 占位
- `_gen_profile_pages.sh` — 6 个 Profile 子页
- `_gen_product_misc.sh` — 3 Product + Launch + Empty + DataCapture
- `_gen_kyc_pages.sh` — 8 个 KYC 页面
- `_gen_order_pages.sh` — 8 个 Order 页面

每个脚本一次写 5-10 个文件,运行 1 秒,比 Write 工具调用快 30+ 倍。

#### 4.3 关键约定（每条都不能违反）

1. **坐标转换公式**: 设计稿坐标 (x,y,w,h) → `CGRectMake(S(x), S(y), S(w), S(h))`
2. **子视图内坐标**: Figma 原坐标 减去 父 View 在父级中的偏移
3. **图片资源**: 全部用半透明纯色 UIView 占位 (alpha:0.22, cornerRadius:S(8)); Phase 9 替换为真实切图
4. **字体**: 优先用 `kFontPingFangXxx` / `kFontPoppinsXxx` 等 Phase 2 定义好的精确宏
5. **颜色**: 优先用 `kColorXxx` 宏, 禁止硬编码 `[UIColor colorWith...]`
6. **事件**: 用 `void (^)(void)` block 暴露给 VC, 禁止 View 直接持有 VC
7. **VC 体积**: VC.m 不超过 100 行(纯组装), 超过说明布局没拆干净
8. **每个模块编译验证**: 至少 1 次 `xcodebuild ... BUILD SUCCEEDED` 后再进下一个

---

#### 4.4 模块完成顺序（推荐, 见 findings.md）

| 顺序 | 模块 | 文件数估计 | 复杂度 |
|---|---|---|---|
| 1 ✅ | Login (Sign in) | 4 (2 VC 同类 + 1 View + 1 GradientBg 公共) | 简单 |
| 2 | Home | ~12 | 中 |
| 3 | Product | ~15 | 中 |
| 4 | KYC | ~30 (含 8 长表单) | 高 |
| 5 | Order | ~25 (含详情 TableView) | 高 |
| 6 | Profile | ~20 | 中 |
| 7 | **MKBottomSheetView (22 Modal 合 1)** | 2 | 中(分支多但单文件) |
| 8 | Launch/Empty/DataCapture | ~3 | 简单 |

总计约 **~110 文件**(用户决策 22 modal 合 1 后), 每个 100-300 行 OC。

---

#### 4.5 Login 模块已交付文件清单（作为参考样本）
- `Common/Views/MKGradientBackgroundView.h/.m` — 通用渐变背景, 多页面共用
- `Modules/Login/Controller/MKSignInViewController.h/.m` — 50 行 VC
- `Modules/Login/View/MKSignInCardView.h/.m` — 200 行 View, 内含所有内部布局
- 修改 `SceneDelegate.m` + `Info.plist` 接 root VC

**编译验证**: `** BUILD SUCCEEDED **` ✅



### Phase 5：入口 TableView 菜单 + 真实导航流 ✅ 已验证

#### 5.0 双轨制原则

PoC 项目同时存在两套入口逻辑, **缺一不可**:

| 入口 | 用途 | 切换方式 |
|---|---|---|
| **A. 入口 TableView 菜单** | 调试期: 直接点击任一页面单测; 验收期: 让产品/测试逐页对照 Figma | SceneDelegate root = ViewController |
| **B. 真实业务导航流** | 演示期/生产期: 模拟用户真实路径 | 每个 VC 在 onTapped 中 push 下一个 VC, 用户从 Login 开始体验完整流程 |

A 是开发期工具,B 是产品本身。**B 的 push 关系必须在 Phase 4 写 VC 时就埋好** —— 这样可以同步验证两种入口。

#### 5.1 PHI372-DC 已串接的完整导航树（参考样板）

```
ViewController(入口菜单)
└── [Login] MKSignIn
    └── 点 Sign in → replace root vc 为 MKHomeBeforeKYC
        ├── 点 Apply Now → MKKYCID
        │   └── 点 box → MKKYCIDCamera
        │       └── 点 shutter → MKKYCLiveness
        │           └── 点 Continue → MKKYCLivenessDone
        │               └── 点 Continue → MKKYCPersonal
        │                   └── 点 Next → MKKYCFinance
        │                       └── 点 Next → MKKYCPayment
        │                           └── 点 Save → MKKYCContact
        │                               └── 点 Submit → MKProductMultiAmount
        │                                   └── 点 Apply → MKProductSingleAmount
        │                                       └── 点 Confirm → MKProductSuccess
        │                                           └── 点 Back to Home → popToRoot
        ├── 点 Bank icon → MKHomeBankCard
        ├── 点 Order icon → MKOrderRepaymentList
        │   └── 点 row → MKOrderDetailWaitRepay
        │       └── 点 Repay → MKOrderRepay
        │           └── 点 Confirm → BottomSheet 提现成功
        ├── 点 Contact icon → MKProfileContact
        └── 点 Me icon → MKProfile
            ├── Repayment Notes → MKProfileRepaymentInfo
            ├── Feedback → MKProfileFeedback
            ├── Contact Us → MKProfileContact
            ├── Official Reloan → MKProfileOfficialReloan
            ├── Service Agreement → MKProfileAgreement
            ├── About Us → MKProfileAbout
            └── Sign Out → BottomSheet 退出确认
```



**目的**: 在 PoC/调试阶段, 让所有 60 个页面 + 21 个 BottomSheet 都能通过菜单逐个点击进入查看。生产环境(Phase 9)切换为正常 Launch → SignIn → Home 流程。

**Action 5.1**: 重写默认 `ViewController.h/.m` 继承 `MKBaseViewController`, 内置 `UITableView (UITableViewStyleGrouped)`, 按模块分 8 个 section:
- Login / Home / Product / KYC / Order / Profile / Launch+Misc / **Bottom Sheets**

**Action 5.2**: 每个 row 是 `EntryRow` 对象, 字段 `(title, kind, vcClass | sheetType)`:
- `kind == EntryRowKindVC` → `pushViewController:`
- `kind == EntryRowKindSheet` → `[MKBottomSheetView sheetWithType:type config:nil] show]`

**Action 5.3**: SceneDelegate 把 root 改为 `UINavigationController(rootVC=ViewController)`, 同时移除 Info.plist 中 `UISceneStoryboardFile` 键。

**Action 5.4**: `Cmd+R` 在 iPhone 17 Pro 模拟器跑通, 8 个 section 全部可点击进入, BottomSheet 全部能从底部滑出。

---

### Phase 6：4.3 规避处理 ✅ 已验证(轻量)

**已执行**:
1. **类前缀**: `RD` → `MK`(Phase 1)
2. **文件结构调整**: 部分 Manager/NetWorkTool 移到 `_DEFERRED/`(Phase 1)
3. **Bundle ID**: 模板默认 → `com.mk.phi372dc`(Phase 6)
4. **Modal 重构为单 BottomSheet**: 结构性差异化(Phase 4)
5. **新建 MKBaseViewController + MKGradientBackgroundView**: 新增类, 模板没有(Phase 1, Phase 4)

**待做(随 Phase 4 真实实现自然发生)**:
6. **方法签名扰动**: 真实 VC.m 写代码时, 30% 的私有方法名加随机后缀(如 `setupHeader` → `setupHeader_x7k`)。**不必现在批量改, 写新 VC 时直接用扰动名即可。**
7. **代码顺序扰动**: VC.m 里属性声明顺序 / setup 顺序与模板 RDXxxVC 不同。

**4.3 规避强度自查清单**:
- [ ] 类名 100% 不与模板项目重名 ✅ (RD → MK)
- [ ] 图片资源名变更 (Phase 9 接资源时改)
- [ ] Bundle ID 完全不同 ✅
- [ ] App Name / Display Name 不同 (Phase 9 改 Info.plist 中 CFBundleDisplayName)
- [ ] 至少 5 个方法有命名差异 (随 Phase 4 真实实现累积)
- [ ] 至少 3 个类有结构性差异 ✅ (MKBaseVC / MKGradientBg / MKBottomSheet 均新)

---

### Phase 7：编译 + 截图 diff 验证 ✅ 已验证

**Action 7.1: xcodebuild 全量编译**
```bash
cd "$OUTPUT_PROJECT"
xcodebuild -project "$NAME.xcodeproj" -scheme "$NAME" -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|BUILD)"
```
必须 `** BUILD SUCCEEDED **`。

**Action 7.2: iPhone 17 Pro 模拟器跑通**
1. Cmd+Shift+K 清缓存
2. Cmd+R 启动
3. 看到入口 TableView 菜单, 8 section, 33 VC 行 + 21 Sheet 行
4. 逐个点击, 全部能正常 push/show

**Action 7.3: 关键页面截图对照 Figma**
拍 5 个关键页面截图, 与 Figma 原图肉眼/工具对照:
- Sign in (3:1743)
- 首页-KYC前 (3:1786)
- KYC-身份证 (3:1099)
- 订单详情-待还款 (3:814)
- 个人中心 (3:338)

**Action 7.4: 还原度记录**
在 progress.md 里写每页大致还原度(>90% / 80-90% / <80%), 不达标的拉单页 Figma 数据重做。

---

### Phase 8：AUTOMATION_SPEC.md 文档化 ✅ 自身

**本节即文档主体, 包含**:
- ✅ Phase 0 → Phase 7 全部 Action 步骤(每步可独立执行)
- ✅ 4 个文件模板 (VC / 子 View / Cell / BottomSheet)
- ✅ 完整 token 映射表(颜色 + 字体)
- ✅ 60 frame 全部分类表
- ✅ 7 个已知陷阱 (G1-G7)
- ✅ 命名映射规则
- ✅ 验收清单

**下个项目复用流程**:
1. 复制本文件到新项目根
2. 按 Phase 0 → 7 顺序执行
3. 仅需替换输入参数(Figma URL / 类前缀 / Bundle ID), 其余无变化

---

## 3. 已知陷阱（Gotchas）

| ID | 陷阱 | 现象 | 正解 |
|---|---|---|---|
| G1 | `viewDidLoad` 时 keyWindow 未就绪 | `UIWindowScene.windows[].isKeyWindow` 返回 nil → kScale=1.0 不缩放 | 用 `[UIScreen mainScreen].bounds.size.width` |
| G2 | `preferredStatusBarStyle` 改了不生效 | Xcode 缓存了上次 build | Cmd+Shift+K 清 build folder 再 Cmd+R |
| G3 | Pencil 导入 Figma 有损 | Components / Variables 全部丢失 | 不要用 Pencil 当代码源，直接用 Figma MCP |
| G4 | Figma file 没正式 Components | `components: {}` 即使设计师"用了" | mapping 表靠 frame name，token 靠 globalVars.styles |
| G5 | `mcp__figma__get_figma_data` 一次拿太多超限 | 60 frame 全展开 235k 字符 | 限定 `nodeId` 单页拉、限定 `depth=2` |
| G6 | `mcp__figma__download_figma_images` 网络易失败 | fetch failed | 加重试 / 本轮跳过用占位符 |

---

## 4. 命名映射规则

### 4.1 Figma 节点名 → OC 类名
| Figma 命名模式 | OC 类名 | 模块 |
|---|---|---|
| `Sign in-*` | `${PREFIX}SignIn*ViewController` | Login |
| `首页-*` | `${PREFIX}Home*ViewController` | Home |
| `KYC-*` | `${PREFIX}KYC*ViewController` | KYC |
| `历史订单-*` | `${PREFIX}Order*ViewController` | Order |
| `个人中心-*` | `${PREFIX}Profile*ViewController` | Profile |
| `产品申请-*` | `${PREFIX}Product*ViewController` | Product |
| `*弹窗*` / `*提示*` | `${PREFIX}*View`（用作 modal） | Common/Views |

### 4.2 Figma 节点 → 项目现有组件
| Figma 节点名/特征 | OC 组件 | 来源 |
|---|---|---|
| `Button`（圆角矩形 + 文字） | `${PREFIX}ActionButton` | Common/Views |
| 渐变 fill + 圆角的按钮 | `${PREFIX}GradientButton` | Common/Views |
| 带 label + placeholder 的输入框 | `${PREFIX}FormField` | Common/Views |
| 顶部导航栏 frame | `${PREFIX}NavBar` | Common/Views |
| 弹窗类 frame | `${PREFIX}AlertView` 变体 | Common/Views |

### 4.3 Figma 样式 → RDConstants 宏
| Figma globalVars | 宏名 | 备注 |
|---|---|---|
| 主色 `fill_YLFCXD #385330` | `kColorPrimary` | 渐变按钮、CTA |
| 背景 `fill_VD7CCF #F8F8F7` | `kColorBackground` | 页面底色 |
| 卡片 `fill_FOTS7F #E9E9E4` | `kColorCardSecondary` | 卡片 |
| 弹窗白 `fill_1JG958 #FFFFFF` | `kColorCardBg` | Modal |
| 主文字 `Neutral/1 #171718` | `kColorTextPrimary` | 主文案 |
| 次文字 `fill_SYW5R2 #999999` | `kColorTextSecondary` | placeholder |

---

## 5. 验收清单

下一个 session 完工时核对：

- [ ] 工程能 `xcodebuild` 编译通过（零 warning 优先）
- [ ] iPhone 17 Pro 模拟器跑通
- [ ] 入口菜单能浏览所有页面
- [ ] 关键 5 页（Sign in / Home / KYC1 / Order list / Profile）人眼对照 Figma 还原度 ≥ 90%
- [ ] 类前缀全部改为 `$NEW_PREFIX`，模板项目代码不被反向污染
- [ ] Bundle ID / App Name 全部改为新值
- [ ] 4.3 规避中等强度已应用（方法签名扰动可见）
- [ ] AUTOMATION_SPEC.md 已更新本次执行记录

---

## 5.5 下一个项目快启动 Checklist（一页纸版）

把下列项依次照做, 一个新马甲包项目就能产出:

### 准备(5 分钟)
- [ ] Xcode 新建 iOS App (Objective-C, Storyboard)
- [ ] 工程根目录: `/Users/seacity/Desktop/锋远项目/<NEW_NAME>`
- [ ] 拿到 Figma URL → 提取 `FIGMA_FILE_KEY`
- [ ] 决定 `NEW_PREFIX` (两字母, 不能与已存在项目重名)
- [ ] 决定 `NEW_BUNDLE_ID` (`com.<prefix>.<name>`)

### Phase 1: 骨架移植(15 分钟)
- [ ] 复制 REXDC334/Common 到新工程
- [ ] sed 改前缀 `RD → $NEW_PREFIX`
- [ ] sed 改 `rd_keyWindow → <prefix小写>_keyWindow`
- [ ] sed 改 `REXDC334 → <NEW_NAME>` (注释)
- [ ] 修 MKConstants.h G1 陷阱(用 UIScreen.mainScreen)
- [ ] 创建 `${PREFIX}BaseViewController.h/.m`
- [ ] 创建 `${PREFIX}GradientBackgroundView.h/.m`
- [ ] Defer 18 个文件到 `_DEFERRED/`(Manager 5 + NetWorkTool 13 + 4 个有依赖的 Views)
- [ ] `xcodebuild` 必须 SUCCEEDED

### Phase 2: Token(10 分钟)
- [ ] Figma MCP 拉 2-3 个代表页 (Sign-in / Home / Order详情)
- [ ] 整理 globalVars.styles → 颜色/字体表
- [ ] 覆写 `${PREFIX}Constants.h` 色值
- [ ] 添加精确字体宏(kFontPingFangXxx 等)
- [ ] `xcodebuild` 必须 SUCCEEDED

### Phase 3: 60 frame 清单(10 分钟)
- [ ] Figma MCP 调用 depth=2 拿全部顶层 frame
- [ ] 按命名前缀分组 (Sign in / 首页 / KYC / 历史订单 / 个人中心 / 产品申请 / Modal)
- [ ] 给每 frame 分配类名 + NavBar 样式 + 长页面标记
- [ ] 写入 findings.md "60 Frame 分类表"

### Phase 4: 生成代码(2-4 小时, 大头)
- [ ] 用 bash 脚本生成所有 VC stub(33 个)
- [ ] 创建 `${PREFIX}BottomSheetView.h/.m` (合并所有 modal)
- [ ] Login 模块详细实现(2 个 View + 1 VC)
- [ ] Home 模块详细实现(3 个 View + 1 VC)
- [ ] 剩余模块逐个用 Figma MCP 拉数据 + 替换 stub
- [ ] 每模块写完 `xcodebuild` 必须 SUCCEEDED

### Phase 5: 入口菜单(15 分钟)
- [ ] 改造 `ViewController.h/.m` 为 UITableView 列表
- [ ] 8 section 按模块分组
- [ ] EntryRow 模型支持 VC push / Sheet show
- [ ] SceneDelegate 用 UINavigationController 包裹

### Phase 6: 4.3 规避(20 分钟)
- [ ] Bundle ID 改为 `$NEW_BUNDLE_ID`
- [ ] App Name 改为 `$NEW_APP_NAME` (Info.plist CFBundleDisplayName)
- [ ] 抽查 5 个 VC 看是否有方法签名扰动
- [ ] 资源命名前缀变更(Phase 9 接资源时改)

### Phase 7: 验证(30 分钟)
- [ ] xcodebuild SUCCEEDED
- [ ] iPhone 17 Pro 模拟器跑通
- [ ] 5 个关键页面截图对照 Figma, 还原度记录

### Phase 8: 文档(本步即文档更新)
- [ ] 把本次执行中发现的陷阱(G8+)写入 findings.md
- [ ] AUTOMATION_SPEC.md 任何需要修正的地方更新

**总时长预估**: **熟练后约 3-5 小时, 90% 还原度**

---

## 6. 文件结构最终态

```
$OUTPUT_PROJECT/
├── task_plan.md            # 本次执行计划（每个项目独立）
├── findings.md             # 本次研究记录（每个项目独立）
├── progress.md             # 本次会话日志（每个项目独立）
├── AUTOMATION_SPEC.md      # 通用流程文档（跨项目共用，从这里复制）
├── $NEW_APP_NAME.xcodeproj
└── $NEW_APP_NAME/
    ├── Common/
    │   ├── Macros/PXConstants.h
    │   ├── Category/(PX 前缀 Category)
    │   ├── Views/(11 个公共视图)
    │   ├── Manager/(5 个业务 Manager)
    │   └── NetWorkTool/(13 个网络类)
    ├── Modules/
    │   ├── Login/(Sign in)
    │   ├── Home/
    │   ├── KYC/
    │   ├── Order/
    │   ├── Profile/
    │   ├── Product/
    │   └── Launch/
    ├── AppDelegate.h/.m
    ├── SceneDelegate.h/.m
    └── ViewController.h/.m  # 入口 TableView 菜单
```

---

## 7. Phase 9：业务接口接入（最终成功流程）

> 本节按"模块顺序"记录每个功能页跑通的**最终成功步骤**。下个项目按此节直接执行即可。
> 调整过程与失败尝试不在此处，进入 `## 3. 已知陷阱` 的 G-编号 trap。

### 7.0 NetWorkTool 基础设施一次性搭建

**前置**: `_DEFERRED/NetWorkTool/` 已含 RD 前缀重命名后的源文件（Phase 1 已 defer）。

**Action 7.0.1 — 复制 8 个文件到 Common/NetWorkTool/**:
```bash
mkdir -p PHI372-DC/Common/NetWorkTool
cp _DEFERRED/NetWorkTool/{MKEncryptManager,MKCommonParams,NSString+MKEncrypt,MKPhoneValidator,MKOTPValidator,MKLoginResponse,MKLoginUserInfo,MKDeviceInfo}.{h,m} PHI372-DC/Common/NetWorkTool/
```
不复制: `MKNetworkManager`（重写）、`MKLoginManager`（已存在简化版）、`MKDomainManager`（写死）、`MKBuriedPointService`（暂跳过）、`MKNavigationHelper`（已有 MKNavigationController）。

**Action 7.0.2 — 改 `MKCommonParams.m` 的 appId + salt**:
```objc
static NSString * const kMKAppID = @"phi372-dc";      // 本项目专属
static NSString * const kMKSalt  = @"qdaGzDWaf2plCOcP"; // 本项目专属
```
**关键**: 加密方式和 334 完全一致, 只换这两个值即可。

**Action 7.0.3 — 重写 `MKNetworkManager.h/.m`（NSURLSession, 不用 AFNetworking）**:
- 接口签名保持 `post:params:success:failure:` 不变
- baseURLString 写死: `https://test-phl-api.fyinformation.cc`
- 完成回调统一切到 main queue
- 每次请求 NSLog `[MKNet] POST <path> → status=<code> <ms>ms err=<msg>`

**Action 7.0.4 — `MKLoginManager.h/.m` 扩展**:
- 加 `userId` 只读属性（NSUserDefaults key=`MK.userId`）
- 加方法 `loginWithUserId:token:mobile:` 持久化 userId + token + mobile，写 isLoggedIn=YES，发 `MKLoginStateDidChangeNotification`
- `logout` 同步清掉所有 key
- 关键: 写完 defaults 必须 `[d synchronize]`（虽然 deprecated 但避免 simctl spawn 旁路问题）

**Action 7.0.5 — 在 `MKLaunchVC.viewDidLoad` 加 `pingNetwork` 测连通**（只在第一次集成时；验证后立刻删掉）:
```objc
NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{ @"mobile": @"0000000000", @"verifyType": @"1" }];
[[MKNetworkManager sharedManager] post:@"/app/v3/sms/sendVerifySms" params:body success:^(id resp) {
    NSLog(@"[NetPing] resultCode=%@ msg=%@", resp[@"resultCode"], resp[@"resultMsg"]);
} failure:nil];
```
预期: `resultCode=6201001 msg=Please enter the correct mobile number` → 签名通过, 服务端只是拒了 mobile。

---

### 7.1 Login 模块（已验证 ✅）

**前置**: Phase 7.0 完成。

**Action 7.1.1 — 重写 `MKSignInViewController.m`**:
- `onGetOTPTapped`: 校验 `MKPhoneValidator validationErrorMessage:`, normalize 后 POST `/app/v3/sms/sendVerifySms` `{mobile, verifyType:"1"}`, 成功后 SVProgressHUD success + `[self.cardView startOTPCountdown:60]`
- `onSignInTapped`: 校验 phone + otp + agreement, 取 `deviceId = [MKCommonParams shared].deviceId`, POST `/app/v3/auth/registerOrLogin` `{mobile, verifyCode, imei:"", serialNo:deviceId, longitude:"-360", latitude:"-360"}`, 解析 `MKLoginResponse`, 成功后 `[MKLoginManager loginWithUserId:r.data.userId token:r.data.token mobile:normalized]` + 0.6s 后 `enterHome`

**Action 7.1.2 — `MKSignInCardView` 加 OTP 倒计时方法**: `startOTPCountdown:` / `resetOTPButton` + 私有 NSTimer + countdown 属性 + tickCountdown。

**Action 7.1.3 — `MKProfileViewController.rowTapped:` 的 `_LOGOUT_` 分支改成 `performLogout`**:
```objc
- (void)performLogout {
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    [SVProgressHUD showWithStatus:@"Signing out..."];
    [[MKNetworkManager sharedManager] post:@"/app/v3/auth/logout" params:body
        success:^(id resp) {
            [[MKLoginManager sharedManager] logout];
            [SVProgressHUD showSuccessWithStatus:@"Signed out"];
            dispatch_after(...0.6s..., ^{ [wself goToSignIn]; });
        }
        failure:^(NSError *e) {
            [[MKLoginManager sharedManager] logout];   // 网络失败也本地登出
            [wself goToSignIn];
        }];
}
```

**验证步骤**（用 idb）:
1. Reinstall + 清掉 NSUserDefaults: `xcrun simctl spawn booted defaults delete com.<bundle>`
2. 启动 → 落在 SignIn 页
3. tap phone field → `idb ui text` "9888888881" → tap Get OTP → 看 `MKNet] POST .../sendVerifySms → status=200` + HUD "OTP sent" + 按钮 60s 倒计时
4. tap OTP field → text "111111" → tap agreement checkbox → tap Sign In → 看 `MKNet] POST .../registerOrLogin → 200` + `[Login] persisted userId=...` + 0.6s 后切到 Home
5. tap Me icon → tap "Log out" 行 → 弹 LogoutConfirm 底部 sheet → tap Confirm → 看 `MKNet] POST .../auth/logout → 200` + 切回 SignIn
6. 跑 ≥3 轮 login→logout 循环 + 1 轮 login→kill app→relaunch→直进 Home（确认持久化）

**测试号码（test 环境）**: mobile=`9888888881`, 万用 OTP=`111111`。

---

### 7.2 Home 模块（已验证 ✅）

**核心决策**: **单 VC `MKHomeViewController`** 替代 BeforeKYC + AfterKYC, 按 `homeData.userStatus` 状态切 cell（避免重复维护两份）。

**Action 7.2.1 — 复制 6 个 Model 文件到 `Modules/Home/Model/`**（从 334, RD → MK 前缀）:
- `MKHomeResponse.h/.m` — 含 `MKHomeDataModel` + `MKHomeResponse` + `MKProductListResponse` + `MKKYCStatusResponse`（这 4 个都在同一文件）
- `MKProductInfoModel.h/.m`
- `MKAppVersionResponse.h/.m`
- `MKAppConfigModel.h/.m` — 含 `MKAppConfigDynamicParameter`
- `MKAppConfigManager.h/.m` — sharedManager + `currentAppConfig`

**Action 7.2.2 — 写 `MKHomeViewController.h/.m`** 含:
- 状态: `homeData`, `productList`, `showEmpty`（=userStatus==10）, `isRequestingKYCStatus`, `isRequestingProductTerm`
- 弹窗队列状态: `isVersionCheckCompleted`, `isShowingForceUpdateAlert`, `isShowingWithdrawalAlert`, `pendingAlertQueue`
- 静态变量: `sHasShownUpdateAlertThisLaunch`, `sHasShownReloanTipThisLaunch`（同一 launch 只弹一次）
- UI: `MKHomeHeaderView` + 2 sections (notice / 装饰图或产品 cell) + `MKHomeFooterView` + sticky bottom `Apply Now`（仅 showEmpty 时显示）
- `viewWillAppear` 触发 5 API：
  - `POST /app/v3/app/version` → 如有新版且 cur < latest → `showForceUpdateAlertWithContent:url:`
  - `POST /app/v3/app/config` → body 加 `merchantId="phi372-dc"`（如有真实商户号则用真号），缓存 `MKAppConfigManager.currentAppConfig`
  - `POST /app/v3/user/suphome` → `MKHomeResponse` → 更新 homeData + showEmpty + `kycCompleted` + reloadData + `withdrawalOrderId`/`appUserType` 触发弹窗
  - `POST /app/v3/product/list` → `MKProductListResponse` → productList → reload
  - `POST /app/v3/user/info` → **`adid` 不参与签名**, 用 `generateRequestBodyWithSignData:requestData:` 分别传 `@{}` 和 `@{@"adid":@""}`
- `applyTapped`: POST `/app/v3/kyc/four/status` → `navigateToKYCStep:` 按 willExecuteStepNumber 1/2/3/4 push 对应 KYC VC
- `applyProductAtIndex:`: POST `/app/v3/product/termV3` `{productId}` → 200 push ProductApply, 6230002/6230003 弹 ExistingOrder

**Action 7.2.3 — 弹窗优先级队列**:
- priority 1 ForceUpdate: `isShowingForceUpdateAlert=YES`, 弹完才 flush queue
- priority 2 WithdrawPending: 检查 version + forceUpdate 状态, 占用时 enqueue
- priority 3 ReloanTip: 检查前两者 + `cfg.dynamicParameter.fjtip == "on"`, 占用时 enqueue

**Action 7.2.4 — 强更弹窗禁止 dim tap**:
- `MKBottomSheetView.h` 加 `@property BOOL dismissibleByDim`
- init 时 `_dismissibleByDim = (type != MKBottomSheetTypeForceUpdate)`
- `setupDim` 里只有 dismissibleByDim 才加 UITapGestureRecognizer

**Action 7.2.5 — 路由更新**:
- `MKLaunchVC.routeToNext`: 删 BeforeKYC/AfterKYC 引用, 统一 `[MKHomeViewController new]`
- `MKSignInVC.enterHome`: 同上
- `MKProductSuccessVC.backToHome`: 同上
- 删除文件: `MKHomeBeforeKYCViewController.h/.m` + `MKHomeAfterKYCViewController.h/.m`

**验证步骤**（用 idb）:
1. Clean install + 清 defaults + 完整 login（按 7.1 流程）
2. 落到 Home 后, 看 log 应有 6 个 `MKNet] POST` (含 registerOrLogin + 5 个 Home API), 全部 200
3. ForceUpdate 弹窗应自动弹（test 环境会返回有更新）→ 单按钮 "Upgrade", 无 Cancel
4. tap 弹窗外 dim 区域 → 弹窗仍在（dim 不可关）✅
5. tap Upgrade 按钮 → 弹窗消失 → flush queue（如有 withdrawal/reloan 弹下一个）
6. tap "Apply Now" → log 应有 `MKNet] POST /app/v3/kyc/four/status → 200` → push 到 KYC ID 页

**关键 Status code 含义**:
| code | 含义 |
|---|---|
| 200 | SUCCESS |
| 500 | 签名错误 (检查 salt / merchantId / sign 算法) |
| 6201001 | mobile 格式错 |
| 6230002 / 6230003 | 已有申请中订单 → 弹 ExistingOrder |
| 2000001 / 2000002 / 2002001 | 需要重新登录 (留 TODO 写中间件) |

---

### 7.3 KYC 主链路 + ID / Liveness 拍照（已接入 ✅）

**核心决策**: 4 步链路 Personal → Finance → Contact → ID。Home `Apply Now` 调 `/kyc/four/status` 拿 `willExecuteStepNumber` 分发到对应 VC。每步表单结构由 `/kyc/four/search-iterm`（`kycId` 参数化）下发 → `MKKYCInitResponse` → `formItems`；提交后端各自端点；ID 步结束 `popToRootViewController` 让 Home `viewWillAppear` 自动刷 status。

**Action 7.3.1 — `MKKYCBaseViewController` 提供通用能力**:
- NavBar(`MKNavBarStylePrimaryDark`) + UITableView(plain, sep none, rowHeight 94) + 底部固定 Continue 按钮
- `requestFormItems` 走 `POST /app/v3/kyc/four/search-iterm` `{kycId}`，用 `MKKYCInitResponse` 解析 `data.kycItemList` 并按 `itemSort` 排序填 `self.formItems`
- `validateFormItems` 必填 + 正则校验，失败 HUD 弹错
- `scrollToNextRowAfterIndex:` 输入完成自动滚到下一行 + focus 输入框 / 弹 picker
- `onBackTapped` 拦截返回，弹 `MKBottomSheetTypeBackConfirm`
- **去除**进度条机制：Figma 设计无进度条，顶部"装饰横线"是静态贴图；Base 不再持有 `currentStep / showsProgressBar / progressBar` 属性，`MKKYCProgressBarView` + `MKKYCUploadBoxView` 已删

**Action 7.3.2 — `MKKYCPersonalViewController` (kycId="personal", step 1 → /personal)**:
- `loadFormItems` → `requestFormItems`
- `showPickerForIndex:` 分发 province/city/普通三种 picker
- Province: `POST /sys/province` `{countryId: kCountryIdPH}` → `MKKYCPickerView` 弹选；选完清空 city
- City: `POST /sys/city` `{countryId, provinceId: selectedProvinceKey}` → 依赖 Province 先选；未选 Province 报错
- 普通 picker: 用字段自带 `buttonList`
- `continueAction` → 收集 flat `{itemCode: selectedKey?:selectedValue}` → `POST /kyc/four/personal` → 200 push `MKKYCFinanceViewController`

**Action 7.3.3 — `MKKYCFinanceViewController` (kycId="work_questionnaire", step 2 → /work)**:
- `loadFormItems` → `requestFormItems` 走 search-iterm
- 6 字段全部由 API 下发（picker + input 混合）
- `continueAction` → `POST /kyc/four/work` → 200 push `MKKYCContactViewController`

**Action 7.3.4 — `MKKYCContactViewController` (kycId="urgent_contact", step 3 → /contact)**:
- `sectionTitles = @[ @"Contact 1", @"Contact 2", @"Contact 3", @"E-Mail" ]`，硬编码 10 字段结构（3 × {relation/name/phone} + email），search-iterm 仅用来取 `buttonList` 作为 3 个 `*_relation` 的选项源
- `*_name` 字段渲染为 PickerCell（占位 `Pick from Contacts`），tap 触发 `CNContactPickerViewController`（`displayedPropertyKeys=@[CNContactPhoneNumbersKey]`）
- `contactPicker:didSelectContactProperty:` 回调把 `givenName+familyName` 写入 name 字段；电话用 `MKPhoneValidator filterPhoneNumber:` 过滤非数字 + 去 `63` 前缀 / 前导 `0`，写入 phone 字段
- `continueAction` → `POST /kyc/four/contact` payload 形如 `{first_name, first_phone, first_relation, second_*, third_*, email}` → 200 push `MKKYCIDViewController`

**Action 7.3.5 — `MKKYCIDViewController` (step 4 → /liveness)**:
- 自定义 `MKKYCDashedBox` (UIControl + dashed border layer + 内嵌 photoPreview)
- viewDidLoad → `requestIDTypeKey` 调 `POST /kyc/four/search-iterm` `{kycId: "identity_liveness"}` 取首个含 `buttonList` 项的 `buttonList[0].buttonKey` 作为 `card_type`
- `frontTapped` → push `MKKYCIDCameraViewController`，`onImageCaptured` 回调写 `self.idImage` + frontBox 显示预览
- `faceTapped` → push `MKKYCLivenessViewController`，`onLivenessCompleted` 回调写 `self.faceImage` + faceBox 显示预览
- `continueTapped` 三段校验（idImage / faceImage / idTypeKey 缺一 HUD 错），全 OK → base64 编码（先 `resizeImage maxDim=1024` + JPEG quality 0.7 起阶梯压到 ≤800KB）→ `POST /kyc/four/liveness` `{identity_front_img, liveness_img, card_type}` → 200 `showSuccessWithStatus:@"Submitted"` + 1s 后 `popToRootViewControllerAnimated:` 回 Home

**Action 7.3.6 — `MKKYCIDCameraViewController` (后置相机)**:
- `AVCaptureSession + AVCaptureDevicePositionBack + AVCapturePhotoOutput`
- 全屏 `AVCaptureVideoPreviewLayer` + 黑遮罩 0.85 + 虚线取景框 (#BBCB2F, dash 9-9, r=30)
- Ready/Captured 状态机: 圆形快门 → snap → `AVCapturePhotoCaptureDelegate` 回 image → `enterCaptured` 显示 retake (旋转 icon) + confirm (绿圆勾) → confirm 走 `onImageCaptured(image)` + pop
- 模拟器 fallback: `snapshotPreview` (黑屏 layer 截图) 当 capturedImage

**Action 7.3.7 — `MKKYCLivenessViewController` (前置相机)**:
- 同上模式，`AVCaptureDevicePositionFront`，`previewLayer.frame = previewContainer.bounds`（嵌在 307×307 圆形容器内）
- Ready: 单按钮 "Take A Photo" 主色实心
- Captured: 上=Confirm 主色 / 下=Restart 描边
- 模拟器 fallback: `placeholderFaceImage` (灰底 + person.fill 渲染) — 真机过 Liveness 风控需真实人脸

**`MKKYCInitResponse` 加 `listKey` 重载**: `initWithDictionary:listKey:` 支持 KYC 用 `kycItemList` / payAccountInfo 用 `payAccountInfoItemDtoList`

**模块文件清单**（清理后）:
- Controller × 9：Base / Personal / Finance / Contact / ID / IDCamera / Liveness / Payment / BankCardEdit
- Cell × 2：MKKYCInputCell / MKKYCPickerCell
- Model × 3：MKKYCInitResponse / MKKYCCommitResponse / MKKYCItemModel(+ ButtonModel)
- View × 0（ProgressBarView + UploadBoxView 已删）

**已知限制（模拟器测试）**:
- Liveness 前置相机在模拟器走 placeholder 灰图，提交 base64 给后端是占位图（不通过真实风控）；真机有完整 AVFoundation 链路
- CNContactPicker 在模拟器可用，但 Apple 默认联系人电话（如 Anna Haro `(555) 522-8243`）经 `MKPhoneValidator` 过滤后是 `5555228243`（不符合 PH 9 开头 10 位规则），后端会回 `kyc param error`。真机或注入符合 PH 格式的测试联系人即可

---

### 7.4 银行卡绑定 / 修改（已接入 ✅）

---

### 7.4 银行卡绑定 / 修改（已接入 ✅）

**核心决策**: `MKKYCPaymentViewController` 不属 KYC 主链路（KYC 4 步 = Personal→Finance→Contact→ID），改归属"产品申请流（下单前绑卡）"。`MKKYCBankCardEditViewController` 用同一组接口的 `update` 方法。两者参考 PHI259-DC `BankAccountController` 的 Add / Modify 两种模式拆出。

**Action 7.4.1 — `MKKYCInitResponse` 加 `listKey` 参数化构造**:
- `- (instancetype)initWithDictionary:(id)dict listKey:(NSString *)listKey;` — 复用 KYC 表单响应解析逻辑（已按 `itemSort` 排序），把 `data.kycItemList` 替换为任意 list key（payAccountInfo 用 `payAccountInfoItemDtoList`）

**Action 7.4.2 — `MKKYCPaymentViewController`（Add 模式 → /save）**:
- 移除 `currentStep` 设置 + `kycId`，置 `showsProgressBar = NO`
- 继续按钮标题改 "Save"
- `loadFormItems` → `requestPayAccountItemList`:
  - POST `/app/v3/payAccountInfo/payAccountItemList`，body 无业务参数（`generateRequestBodyWithSignData:@{} requestData:@{}`)
  - 用 `MKKYCInitResponse initWithDictionary:listKey:@"payAccountInfoItemDtoList"` 解析填 `formItems`
- `continueAction → submitBankAccount`:
  - 构造 `kycCommitItemList` 数组 `[{itemCode, itemValueType:@1, itemValue}]`（picker 用 `selectedKey ?: selectedValue`）
  - body = `{kycCommitItemList: [...], defaultFlag: "1"}`
  - POST `/app/v3/payAccountInfo/save` → 200 弹 "Added successfully" → pop

**Action 7.4.3 — `MKKYCBankCardEditViewController`（Edit 模式 → /update）**:
- public 属性 `@property (nonatomic, assign) NSInteger bankCardBindId;`（调用方必传，否则降级到无预填）
- `showsProgressBar = NO`，继续按钮标题 "Submit"
- `loadFormItems` 流程:
  1. `bankCardBindId > 0` → POST `/app/v3/payAccountInfo/list` `{bankCardBindId}` → 取 `data.payAccountInfoList[0]` → 存 `recordId` + 平铺的字段值字典 `prefillValues`（排除 meta key: `recordId / bankCardBindId / defaultFlag / createTime / updateTime / userId / id / status`）
  2. 再 POST `/app/v3/payAccountInfo/payAccountItemList` 拉表单结构
  3. `applyPrefillIfNeeded`: picker 按 `buttonKey` 或 `buttonLabel` 双向匹配回填 `selectedIndex/Key/Value`，input 直接写 `selectedValue`
- `continueAction → submitUpdate`:
  - 校 `recordId` 非空（缺则提示 "Bank card record ID is missing"）
  - body = `{kycCommitItemList: [...], recordId, defaultFlag: "1"}`
  - POST `/app/v3/payAccountInfo/update` → 200 弹 "Updated successfully" → pop

**Action 7.4.4 — Home 银行卡列表入口分流**:
- `MKHomeBankCardViewController.addTapped` 改 push `MKKYCPaymentViewController`（新建）
- 已有卡的 Submit/编辑入口 push `MKKYCBankCardEditViewController`（需将该卡的 `bankCardBindId` 传入；当前 Home 仍用 mock 卡，真实 bindId 需要 Home 改造去 POST `/payAccountInfo/list` 拿真实列表后填充——遗留待办）

**Phase 9 遗留**:
- `MKHomeBankCardViewController` 接 `/payAccountInfo/list`（不带 bindId 形态，需要确认接口是否支持空 bindId 拉全部 → 否则需查 334 / PHI259 别的列表接口）
- 在 ProductApply / ProductMulti 流程里接入 Payment 入口（用户决策: Payment 属产品申请流，但具体触发时机—— productApply 前还是后—— 等做 Product 模块时再敲定）

**验证步骤**（用 idb / xcodebuild Build 已通过 2026-05-20）:
1. Profile → "Bank Account" → tap "Add" → 落到 Payment 页 → log 应有 `MKNet] POST /app/v3/payAccountInfo/payAccountItemList → 200`
2. 填完字段 tap "Save" → log `POST /app/v3/payAccountInfo/save → 200` + HUD "Added successfully" → pop 回列表
3. 列表上 tap 已有卡的 Submit → 落到 BankCardEdit 页 → log `POST /payAccountInfo/list → 200` + `POST /payAccountInfoItemList → 200` → 表单预填
4. 改字段 tap "Submit" → log `POST /payAccountInfo/update → 200` → HUD "Updated successfully" → pop
