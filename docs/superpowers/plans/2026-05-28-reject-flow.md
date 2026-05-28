# 拒量输出（Reject Flow）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把"拒量输出"前端接入到 PHI372-DC：APP 配置带回 `rejectH5` 时，命中 4 个触发场景就跳合作方 H5，注入用户信息，监听 H5 外跳指令并上报埋点 502。

**Architecture:** 新增 `MKRejectFlowCoordinator`（静态门面：判 rejectH5 + push H5）与 `MKRejectWebViewController`（`MKWebViewViewController` 子类，加 JS 注入和 ScriptMessageHandler）。`MKAppConfigModel` 加 `rejectH5` 字段。4 个触发点（首页 termV3 错误码 / 首页提示卡 userStatus==51 / 复借 termV3 错误码 / 订单列表 cell orderStatus==31）各加一行拦截。500/501 由 H5 自报，原生只报 502。

**Tech Stack:** Objective-C, UIKit, WKWebView, Masonry, 现有 `MKEventTrackingService` / `MKLoginManager` / `MKCommonParams` / `MKAppConfigManager`。

**Spec:** [`docs/superpowers/specs/2026-05-28-reject-flow-design.md`](../specs/2026-05-28-reject-flow-design.md)

**契约：**
- 配置字段：`MKAppConfigModel.rejectH5`（驼峰）
- 错误码：`/app/v3/product/termV3` 返回 `resultCode == 6234303`
- 用户状态：`userStatus == 51` 已拒绝（首页 KYC 卡）
- 订单状态：`orderStatus == 31` 已拒绝（订单列表）
- 埋点：原生只报 `@"502"`（外跳浏览器时）

**编译/验证命令（贯穿所有 Task）：**

```bash
cd /Users/seacity/Desktop/锋远项目/PHI372-DC
xcodebuild -workspace PHI372-DC.xcworkspace -scheme PHI372-DC \
  -configuration Debug \
  -destination 'id=5D3DF5C9-B78D-4620-9EE0-A4CEF34E1D86' \
  -derivedDataPath ./build build 2>&1 | tail -20
```

模拟器 id：`5D3DF5C9-B78D-4620-9EE0-A4CEF34E1D86`（iPhone 17 Pro）。bundle id：`yanwenbo.developer.app`。

---

## 文件清单

**新增：**
- `PHI372-DC/Common/Manager/MKRejectFlowCoordinator.h`
- `PHI372-DC/Common/Manager/MKRejectFlowCoordinator.m`
- `PHI372-DC/Common/Views/MKRejectWebViewController.h`
- `PHI372-DC/Common/Views/MKRejectWebViewController.m`

**修改：**
- `PHI372-DC/Modules/Home/Model/MKAppConfigModel.h`（+ `rejectH5`）
- `PHI372-DC/Modules/Home/Model/MKAppConfigModel.m`（解析 rejectH5）
- `PHI372-DC/Modules/Home/Controller/MKHomeViewController.m`（termV3 + handleNoticeTap）
- `PHI372-DC/Common/Manager/MKReloanFlowHandler.m`（termV3 复借分支）
- `PHI372-DC/Modules/Order/Controller/MKOrderListViewController.m`（cell 点击）

---

## Task 1：扩展 `MKAppConfigModel.rejectH5` 字段

**Files:**
- Modify: `PHI372-DC/Modules/Home/Model/MKAppConfigModel.h:27`
- Modify: `PHI372-DC/Modules/Home/Model/MKAppConfigModel.m:31`

- [ ] **Step 1：在 `MKAppConfigModel.h` 加 `rejectH5` 属性**

在 `feedbackGuidance` 属性之后（line 27 之后）插入：

```objc
/// 拒量输出 H5 链接。不为空时，4 个触发场景命中后跳此 URL 而非走原流程。
@property (nonatomic, copy, nullable) NSString *rejectH5;
```

- [ ] **Step 2：在 `MKAppConfigModel.m` 的 `modelWithDictionary:` 解析 rejectH5**

在 `feedbackGuidance` 解析后（line 31 之后）、`return m;` 之前插入：

```objc
    m.rejectH5 = [dict[@"rejectH5"] isKindOfClass:[NSString class]] ? dict[@"rejectH5"] : nil;
```

- [ ] **Step 3：编译验证**

运行编译命令（见顶部）。
**预期：** `BUILD SUCCEEDED`。

- [ ] **Step 4：提交**

```bash
git add PHI372-DC/Modules/Home/Model/MKAppConfigModel.h \
        PHI372-DC/Modules/Home/Model/MKAppConfigModel.m
git commit -m "feat(config): MKAppConfigModel 增加 rejectH5 字段

为拒量输出做准备:配置接口返回的 rejectH5 不为空时, 4 个触发场景
跳此 URL 而非走原流程。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2：新建 `MKRejectWebViewController`（H5 容器）

**Files:**
- Create: `PHI372-DC/Common/Views/MKRejectWebViewController.h`
- Create: `PHI372-DC/Common/Views/MKRejectWebViewController.m`

继承现有 `MKWebViewViewController`，覆写两件事：加载完成后注入 `rejectData(JSON)`、监听 ScriptMessage 跳外部浏览器并上报 502。

- [ ] **Step 1：创建 `.h` 文件**

```objc
//
//  MKRejectWebViewController.h
//  PHI372-DC
//
//  拒量输出 H5 容器。继承 MKWebViewViewController, 加 JS 注入 + ScriptMessageHandler。
//  H5 通过 window.webkit.messageHandlers.native.postMessage("thirdUrl=URL&type=ad")
//  通知原生跳外部浏览器, 原生上报埋点 502。
//

#import "MKWebViewViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKRejectWebViewController : MKWebViewViewController

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2：创建 `.m` 文件（核心实现）**

注意：`MKWebViewViewController` 内部已有 webView 和 `WKNavigationDelegate`；这里 access 它需要 KVC 或暴露子接口。**先验证父类 webView 实例变量的访问方式** —— 查 `MKWebViewViewController.m` 看 webView 是 ivar 还是 property。

先看一下：

```bash
grep -n "WKWebView\|webView" PHI372-DC/Common/Views/MKWebViewViewController.m | head -20
```

**如果父类 webView 是私有 ivar/property**，本子类需要自建 webView 实例（不复用父类的），就直接在子类 viewDidLoad 内自己创建 WKWebView 并 add 到 self.view，覆盖父类视图层。

**推荐实现策略**：本子类**不依赖父类的 webView**，自建 webView，避免侵入父类。父类提供的好处仅是 nav bar + base VC 行为。

实现：

```objc
//
//  MKRejectWebViewController.m
//  PHI372-DC
//

#import "MKRejectWebViewController.h"
#import <WebKit/WebKit.h>
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKLoginManager.h"
#import "MKCommonParams.h"
#import "MKNetworkManager.h"
#import "MKEventTrackingService.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

static NSString * const kRejectScriptMessageName = @"native";

@interface MKRejectWebViewController () <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *rejectWebView;
@property (nonatomic, copy)   NSString  *rejectURLString;
@end

@implementation MKRejectWebViewController

- (instancetype)initWithURL:(nullable NSString *)urlString title:(nullable NSString *)title {
    if (self = [super initWithURL:urlString title:title]) {
        _rejectURLString = [urlString copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupRejectWebView];
    [self loadRejectURL];
}

- (void)setupRejectWebView {
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:kRejectScriptMessageName];
    cfg.userContentController = ucc;

    self.rejectWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.rejectWebView.navigationDelegate = self;
    self.rejectWebView.backgroundColor = [UIColor whiteColor];
    self.rejectWebView.opaque = NO;
    [self.view addSubview:self.rejectWebView];
    [self.rejectWebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(kScaleH(44));
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)loadRejectURL {
    if (self.rejectURLString.length == 0) return;
    NSURL *url = [NSURL URLWithString:self.rejectURLString];
    if (!url) return;
    [self.rejectWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self injectRejectData];
}

- (void)injectRejectData {
    MKAppConfigModel *cfg = [MKAppConfigManager sharedManager].currentAppConfig;
    MKLoginManager   *lm  = [MKLoginManager sharedManager];
    MKCommonParams   *cp  = [MKCommonParams sharedInstance];

    NSDictionary *payload = @{
        @"appId":   cp.appId    ?: @"",
        @"salt":    cp.salt     ?: @"",
        @"mobile":  lm.mobile   ?: @"",
        @"userId":  lm.userId   ?: @"",
        @"token":   lm.token    ?: @"",
        @"baseUrl": [MKNetworkManager sharedManager].baseURL ?: @"",
    };

    NSError *err = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
    if (err || !json) return;

    NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSString *safe = [self sanitizeJSONString:jsonString];
    NSString *jsCode = [NSString stringWithFormat:@"rejectData('%@')", safe];

    [self.rejectWebView evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[Reject] rejectData inject failed: %@", error);
        }
    }];
}

/// 转义反斜杠、单引号、换行/回车,避免破坏外层 'json' 字面量。
- (NSString *)sanitizeJSONString:(NSString *)s {
    NSString *r = [s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    r = [r stringByReplacingOccurrencesOfString:@"'"  withString:@"\\'"];
    r = [r stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    r = [r stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    return r;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kRejectScriptMessageName]) return;
    NSString *body = [message.body isKindOfClass:[NSString class]] ? (NSString *)message.body : [message.body description];
    if (![body hasPrefix:@"thirdUrl="]) return;

    NSString *trimmed = [body stringByReplacingOccurrencesOfString:@"thirdUrl=" withString:@""];
    trimmed = [trimmed stringByReplacingOccurrencesOfString:@"type=" withString:@""];
    NSArray<NSString *> *parts = [trimmed componentsSeparatedByString:@"&"];
    if (parts.count == 0) return;

    NSURL *url = [NSURL URLWithString:parts.firstObject];
    if (!url) return;

    [MKEventTrackingService recordEventWithCode:@"502"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)dealloc {
    // 必须移除,否则 userContentController 强引用 self 导致循环引用泄漏
    [self.rejectWebView.configuration.userContentController removeScriptMessageHandlerForName:kRejectScriptMessageName];
}

@end
```

- [ ] **Step 3：验证 `MKNetworkManager.baseURL` 是否存在 / 名字是否对**

```bash
cd /Users/seacity/Desktop/锋远项目/PHI372-DC
grep -n "baseURL\|baseUrl\|@property" PHI372-DC/Common/NetWorkTool/MKNetworkManager.h | head -10
```

**预期：** 若属性名为 `baseURL` 则代码 OK；若为 `baseUrl` 或常量宏，按真实名替换 `[MKNetworkManager sharedManager].baseURL`。**编译前必查**，否则会报"no property baseURL"错误。

- [ ] **Step 4：编译验证**

运行编译命令。
**预期：** `BUILD SUCCEEDED`。如失败按报错改属性名/import。

- [ ] **Step 5：提交**

```bash
git add PHI372-DC/Common/Views/MKRejectWebViewController.h \
        PHI372-DC/Common/Views/MKRejectWebViewController.m
git commit -m "feat(common): 新增 MKRejectWebViewController 拒量 H5 容器

继承 MKWebViewViewController, 自建 WKWebView + ScriptMessageHandler;
didFinish 后通过 evaluateJavaScript 注入 rejectData(JSON), 内含
appId/salt/mobile/userId/token/baseUrl; 监听 H5 thirdUrl=&type= 消息
跳外部浏览器并上报埋点 502。dealloc 移除 message handler 防泄漏。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3：新建 `MKRejectFlowCoordinator`（静态门面）

**Files:**
- Create: `PHI372-DC/Common/Manager/MKRejectFlowCoordinator.h`
- Create: `PHI372-DC/Common/Manager/MKRejectFlowCoordinator.m`

- [ ] **Step 1：创建 `.h`**

```objc
//
//  MKRejectFlowCoordinator.h
//  PHI372-DC
//
//  拒量输出调度器。判定是否触发、负责跳转 H5。
//
//  调用方式: 在 4 个触发点(termV3 6234303 / 首页提示卡 userStatus=51 /
//  复借 termV3 6234303 / 订单列表 orderStatus=31)各加一行:
//
//      if ([MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
//          [MKRejectFlowCoordinator presentRejectH5FromVC:self];
//          return;
//      }
//

#import <Foundation/Foundation.h>

@class UIViewController;

NS_ASSUME_NONNULL_BEGIN

@interface MKRejectFlowCoordinator : NSObject

/// rejectH5 不为空时返回 YES。
+ (BOOL)shouldTriggerRejectFlow;

/// 在 host.navigationController 上 push MKRejectWebViewController。host 必传。
+ (void)presentRejectH5FromVC:(UIViewController *)host;

@end

NS_ASSUME_NONNULL_END
```

- [ ] **Step 2：创建 `.m`**

```objc
//
//  MKRejectFlowCoordinator.m
//  PHI372-DC
//

#import "MKRejectFlowCoordinator.h"
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKRejectWebViewController.h"
#import <UIKit/UIKit.h>

@implementation MKRejectFlowCoordinator

+ (BOOL)shouldTriggerRejectFlow {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.rejectH5;
    return url.length > 0;
}

+ (void)presentRejectH5FromVC:(UIViewController *)host {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.rejectH5;
    if (url.length == 0 || !host.navigationController) return;

    MKRejectWebViewController *web = [[MKRejectWebViewController alloc] initWithURL:url title:nil];
    [host.navigationController pushViewController:web animated:YES];
}

@end
```

- [ ] **Step 3：编译验证**

运行编译命令。
**预期：** `BUILD SUCCEEDED`。

- [ ] **Step 4：提交**

```bash
git add PHI372-DC/Common/Manager/MKRejectFlowCoordinator.h \
        PHI372-DC/Common/Manager/MKRejectFlowCoordinator.m
git commit -m "feat(common): 新增 MKRejectFlowCoordinator 拒量调度门面

shouldTriggerRejectFlow: 判 currentAppConfig.rejectH5 非空。
presentRejectH5FromVC:  push MKRejectWebViewController。
4 个触发点改一行调用即可,判断条件唯一来源。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4：触发点 A — `MKHomeViewController` termV3 错误码分支

**Files:**
- Modify: `PHI372-DC/Modules/Home/Controller/MKHomeViewController.m:14`（import）
- Modify: `PHI372-DC/Modules/Home/Controller/MKHomeViewController.m:507`（在 6230002/6230003 分支前插入 6234303 拦截）

- [ ] **Step 1：在 `.m` 顶部加 import**

定位文件中 `#import "MKHomeKYCTipCardView.h"`（line 14 附近）下面加：

```objc
#import "MKRejectFlowCoordinator.h"
```

- [ ] **Step 2：在 termV3 成功回调里插拒量拦截**

定位 `applyProductAtIndex:` 方法中 line 495-511 这块（`NSInteger code = [resp[@"resultCode"] integerValue];` 之后），改成：

```objc
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code == 200) {
            // home 层按 amountDetailList.count==1 决定 selectionMode, 然后 push 同一个 VC
            id rawData = resp[@"data"];
            MKProductTermDataModel *termData = [rawData isKindOfClass:[NSDictionary class]]
                ? [[MKProductTermDataModel alloc] initWithDictionary:rawData]
                : nil;
            MKLoanAmountSelectionMode mode = (termData.amountDetailList.count == 1)
                ? MKLoanAmountSelectionModeSingle
                : MKLoanAmountSelectionModeMultiple;
            UIViewController *next = [[MKProductApplyViewController alloc] initWithTermData:termData mode:mode];
            [wself.navigationController pushViewController:next animated:YES];
        } else if (code == 6234303 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
            [MKRejectFlowCoordinator presentRejectH5FromVC:wself];
        } else if (code == 6230002 || code == 6230003) {
            [wself showExistingOrderAlert];
        } else {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Request failed"];
        }
```

注意：6234303 分支**必须放在 6230002/6230003 之前**（如未来后端碰巧给同时返回了多个码也以拒量优先）；且只在 `shouldTriggerRejectFlow` 为 YES 时拦截，否则继续走 else 链（保留 toast 作为兜底）。

- [ ] **Step 3：编译验证**

运行编译命令。
**预期：** `BUILD SUCCEEDED`。

- [ ] **Step 4：提交**

```bash
git add PHI372-DC/Modules/Home/Controller/MKHomeViewController.m
git commit -m "feat(home): termV3 错误码 6234303 触发拒量 H5

首页点产品调用 /app/v3/product/termV3, 返回 resultCode=6234303 时,
若 rejectH5 已配置则跳 H5; 否则继续走原 toast 兜底。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5：触发点 C — `MKHomeViewController` 首页提示卡 userStatus==51

**Files:**
- Modify: `PHI372-DC/Modules/Home/Controller/MKHomeViewController.m:843-852`（handleNoticeTap）

- [ ] **Step 1：在 `handleNoticeTap` 顶部插入拒量拦截**

定位 `handleNoticeTap` 方法（line 843-852），改成：

```objc
- (void)handleNoticeTap {
    NSInteger status = self.homeData.userStatus;
    if (status == 51 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
        [MKRejectFlowCoordinator presentRejectH5FromVC:self];
        return;
    }
    if (status == 10) {
        [self applyTapped];   // 走 KYC 流程
    } else if (status == 100 || status == 20) {
        // 无订单 / 审核中 → 不跳转
    } else {
        [self.navigationController pushViewController:[MKOrderListViewController new] animated:YES];
    }
}
```

注意：userStatus==51 时只有 rejectH5 已配置才走 H5；未配置时退到 else 分支（push 订单列表），与原有逻辑兼容。

- [ ] **Step 2：编译验证**

运行编译命令。
**预期：** `BUILD SUCCEEDED`。

- [ ] **Step 3：提交**

```bash
git add PHI372-DC/Modules/Home/Controller/MKHomeViewController.m
git commit -m "feat(home): 首页提示卡点击 userStatus==51 触发拒量 H5

handleNoticeTap 增加 userStatus==51 已拒绝分支:
rejectH5 已配置时跳 H5, 否则退回 else 走订单列表。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6：触发点 B — `MKReloanFlowHandler` termV3 复借分支

**Files:**
- Modify: `PHI372-DC/Common/Manager/MKReloanFlowHandler.m`（顶部 import + line 140-143 分支）

- [ ] **Step 1：先确认 import 区**

```bash
grep -n "^#import" PHI372-DC/Common/Manager/MKReloanFlowHandler.m | head -10
```

在最后一个 `#import` 后添加：

```objc
#import "MKRejectFlowCoordinator.h"
```

- [ ] **Step 2：改 termV3 失败分支（line 140-143）**

定位 `startSeamlessOrderWithProductId:selectedAmount:` 中的 `if ([resp[@"resultCode"] integerValue] != 200) { ... }`，改成：

```objc
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code != 200) {
            [SVProgressHUD dismiss];
            if (code == 6234303 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
                UIViewController *host = [strongSelf hostViewControllerForRejectFlow];
                if (host) {
                    [MKRejectFlowCoordinator presentRejectH5FromVC:host];
                    return;
                }
            }
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Failed to load product"];
            return;
        }
```

- [ ] **Step 3：在 `MKReloanFlowHandler` 类里加私有 helper 取 host VC**

`MKReloanFlowHandler` 没有直接持有 host VC，需要拿到栈顶 VC 来 push。在 `@implementation` 块的尾部、`@end` 之前加：

```objc
- (UIViewController *)hostViewControllerForRejectFlow {
    UIViewController *top = nil;
    NSArray<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes.allObjects;
    for (UIScene *s in scenes) {
        if (![s isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)s;
        for (UIWindow *w in ws.windows) {
            if (w.isKeyWindow) { top = w.rootViewController; break; }
        }
        if (top) break;
    }
    while (top.presentedViewController) top = top.presentedViewController;
    if ([top isKindOfClass:[UINavigationController class]]) {
        top = [(UINavigationController *)top topViewController];
    } else if ([top isKindOfClass:[UITabBarController class]]) {
        UIViewController *sel = [(UITabBarController *)top selectedViewController];
        if ([sel isKindOfClass:[UINavigationController class]]) {
            top = [(UINavigationController *)sel topViewController];
        } else {
            top = sel;
        }
    }
    return top;
}
```

- [ ] **Step 4：编译验证**

运行编译命令。
**预期：** `BUILD SUCCEEDED`。

- [ ] **Step 5：提交**

```bash
git add PHI372-DC/Common/Manager/MKReloanFlowHandler.m
git commit -m "feat(reloan): 复借 termV3 错误码 6234303 触发拒量 H5

MKReloanFlowHandler 在 termV3 失败分支判 resultCode=6234303 +
rejectH5 已配置, 命中则 push H5; 取 host VC 用 keyWindow 栈顶
逻辑(handler 本身不持有 VC)。否则保留 toast 兜底。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7：触发点 D — `MKOrderListViewController` cell 点击

**Files:**
- Modify: `PHI372-DC/Modules/Order/Controller/MKOrderListViewController.m`（顶部 import + line 406-417 didTapItemInSection）

- [ ] **Step 1：加 import**

```bash
grep -n "^#import" PHI372-DC/Modules/Order/Controller/MKOrderListViewController.m | head -10
```

在最后一个 `#import` 后添加：

```objc
#import "MKRejectFlowCoordinator.h"
```

- [ ] **Step 2：改 didTapItemInSection**

定位 line 406-417，改成：

```objc
- (void)didTapItemInSection:(NSInteger)section idx:(NSInteger)idx {
    if (section >= (NSInteger)self.bucketedData.count) return;
    NSArray<NSDictionary *> *bucket = self.bucketedData[section];
    if (idx >= (NSInteger)bucket.count) return;
    MKOrderListModel *m = bucket[idx][@"_model"];
    if (!m) return;

    // 拒绝订单 + rejectH5 已配置 → 跳拒量 H5
    if (m.orderStatus == 31 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
        [MKRejectFlowCoordinator presentRejectH5FromVC:self];
        return;
    }

    // 否则统一走 MKOrderDetailViewController, 由它按 orderStatus 自适应渲染
    MKOrderDetailViewController *detail = [[MKOrderDetailViewController alloc] initWithOrderId:m.orderId];
    detail.productId = m.productId;
    [self.navigationController pushViewController:detail animated:YES];
}
```

注意：`MKOrderListModel.orderStatus` 字段已存在（status mapper 用它），如果字段名是别的（如 `status`、`state`），按实际改。先 grep 确认：

```bash
grep -n "orderStatus\|@property.*NSInteger\|@property.*status" PHI372-DC/Modules/Order/Model/MKOrderListModel.h
```

- [ ] **Step 3：编译验证**

运行编译命令。
**预期：** `BUILD SUCCEEDED`。

- [ ] **Step 4：提交**

```bash
git add PHI372-DC/Modules/Order/Controller/MKOrderListViewController.m
git commit -m "feat(order): 订单列表 cell orderStatus==31 触发拒量 H5

点击拒绝订单 cell 时, 若 rejectH5 已配置则跳 H5 而非详情页;
否则保留原有走 MKOrderDetailViewController 的流程。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8：e2e 验证（模拟器跑通四个场景 + 外跳 + 埋点）

无法 unit test，按 CLAUDE.md 铁律走 e2e 验证。

**Files:** 无新增；只看现有 build 产物。

- [ ] **Step 1：清 NSLog 残留**

按 CLAUDE.md 铁律，调试期临时加的 NSLog 全删。本计划只在 `injectRejectData` 加了一处 `NSLog(@"[Reject] rejectData inject failed: %@", error)`，**保留**（这是出错时的诊断日志，不是临时调试），其余不应有调试 NSLog。

```bash
cd /Users/seacity/Desktop/锋远项目/PHI372-DC
grep -n "NSLog" PHI372-DC/Common/Manager/MKRejectFlowCoordinator.m \
                 PHI372-DC/Common/Views/MKRejectWebViewController.m \
                 PHI372-DC/Modules/Home/Controller/MKHomeViewController.m \
                 PHI372-DC/Common/Manager/MKReloanFlowHandler.m \
                 PHI372-DC/Modules/Order/Controller/MKOrderListViewController.m
```

人工 review 看是否只剩诊断/原有日志，无临时调试残留。

- [ ] **Step 2：装包到模拟器**

```bash
cd /Users/seacity/Desktop/锋远项目/PHI372-DC
xcodebuild -workspace PHI372-DC.xcworkspace -scheme PHI372-DC \
  -configuration Debug \
  -destination 'id=5D3DF5C9-B78D-4620-9EE0-A4CEF34E1D86' \
  -derivedDataPath ./build build 2>&1 | tail -5
xcrun simctl install 5D3DF5C9-B78D-4620-9EE0-A4CEF34E1D86 \
  build/Build/Products/Debug-iphonesimulator/PHI372-DC.app
xcrun simctl launch 5D3DF5C9-B78D-4620-9EE0-A4CEF34E1D86 yanwenbo.developer.app
open -a Simulator
```

**预期：** App 启动、首页加载完成。

- [ ] **Step 3：场景 A 验证 — 首页点产品触发 6234303**

前置：后端 mock `rejectH5=https://test-phl-api.fyinformation.cc/h5/juliang/index.html`、`/app/v3/product/termV3` 返回 `resultCode=6234303`（联调阶段由后端配合 mock 或测试账号准备）。

操作：登录后在首页点任一产品 cell。

**预期：** 不弹"existing order" alert、不 push 申请页；push `MKRejectWebViewController`，loadFinish 后注入用户信息（H5 应能 console.log 出 rejectData 内容）。

- [ ] **Step 4：场景 C 验证 — 首页提示卡 userStatus==51**

前置：后端返回 `data.userStatus=51`，`data.promptCopy="您的申请已被拒绝, 点击查看更多"`。

操作：进首页 → 点首页第一行提示卡。

**预期：** push `MKRejectWebViewController`，不进订单列表。

- [ ] **Step 5：场景 B 验证 — 复借走 termV3**

前置：有完成态用户（已还款），首页"Apply Now"按钮入口走 `MKReloanFlowHandler`；后端让 termV3 返回 6234303。

操作：首页点 "Apply Now" 复借按钮。

**预期：** push `MKRejectWebViewController`。

- [ ] **Step 6：场景 D 验证 — 订单列表点拒绝订单**

前置：构造一个 `orderStatus=31` 的订单，rejectH5 已配置。

操作：进订单列表 → 点该订单。

**预期：** push `MKRejectWebViewController`，不进订单详情。

- [ ] **Step 7：H5 → 原生外跳 + 502 埋点**

在 H5 页里点任一产品（H5 自实现 postMessage `thirdUrl=https://example.com&type=ad`）。

**预期：**
- iPhone 弹出 Safari 加载 example.com
- Charles/Proxyman 抓到 `/app/v3/bury/record` 请求体含 `eventCode=502`

- [ ] **Step 8：回退验证 — rejectH5 为空**

前置：后端把 `rejectH5` 改回空字符串或不返回。

操作：分别走场景 A/B/C/D。

**预期：**
- A：6234303 仍只 toast 错误信息（如 "Request failed"）
- B：6234303 toast 错误
- C：userStatus==51 进订单列表
- D：cell 点击进订单详情

- [ ] **Step 9：dealloc 释放验证**

push 拒量 H5 后 → 返回首页（pop）→ 重复 3 次以上。

**预期：** Xcode Memory Graph 中 `MKRejectWebViewController` 实例数为 0；无 ScriptMessageHandler 残留。

- [ ] **Step 10：MEMORY.md 记录**

在 `/Users/seacity/.claude/projects/-Users-seacity-Desktop------PHI372-DC/memory/` 新建 `project_phi372_reject_flow.md`，描述：
- 何时（2026-05-28）
- 改了哪些文件
- 验证哪些场景已通过
- 后续依赖（H5 联调时确认 messageHandler 名 `native`、500/501 由 H5 自报）

更新 `MEMORY.md` 顶层一行指针。

---

## 风险与回滚

- 单次 commit 粒度小（每个 Task 独立提交），任一阶段出问题可 `git revert <commit>` 单点撤销，不影响其他任务
- `rejectH5` 字段缺失/null safety 由 `length > 0` 判定，无 crash 路径
- `MKReloanFlowHandler` 取 host VC 依赖 keyWindow 栈顶；若用户在弹窗页面命中场景 B，可能 push 到非预期栈。**测试时关注：复借走拒量时 host VC 是否符合直觉**。若不符合，把 `hostViewControllerForRejectFlow` 改为 handler 持有的 weakRef host（需要给 `MKReloanFlowHandler` 加 `weak hostVC` 属性，由 caller 设置）
- ScriptMessageHandler 名 `native`：H5 联调时若 H5 用别的名，改 `kRejectScriptMessageName` 常量即可（单点改）

## Self-Review 结论

- **Spec coverage**：
  - rejectH5 字段 → Task 1 ✓
  - MKRejectFlowCoordinator → Task 3 ✓
  - MKRejectWebViewController → Task 2 ✓
  - 触发点 A/B/C/D → Task 4/5/6/7 ✓
  - 埋点 502 → Task 2 ✓
  - 测试场景 → Task 8 ✓
- **Placeholder scan**：无 TBD/TODO；`baseURL` 属性名要 Task 2 Step 3 实际 grep 后确认；订单 model 字段名要 Task 7 Step 2 grep 确认。这两处明确给了 grep 命令，不是占位
- **Type consistency**：`MKRejectFlowCoordinator` 两个类方法在 Task 3 定义、Task 4/5/6/7 调用名一致；`MKRejectWebViewController` 在 Task 2 定义、Task 3 引用一致

