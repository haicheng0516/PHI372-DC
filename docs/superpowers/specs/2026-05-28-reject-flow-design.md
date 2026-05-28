# 拒量输出（Reject Flow）— 前端设计

- **日期**：2026-05-28
- **范围**：仅 iOS 前端。后端配置接收方、三方传输流程不在本设计内。
- **依据**：需求文档 — 飞书《拒量输出》（2026-03-09 创建，2026-05-22 最近修改）

> **状态码契约**
>
> `userStatus`（首页接口 `data.userStatus`）：
> `10`=待 KYC / `20`=待申请 / `30`=待抓数据 / `32`=待提现 / `41`=待改卡 /
> `50`=审核中 / **`51`=已拒绝** / `70`=放款中 / `80`=待还款 / `81`=逾期 / `100`=其他
>
> `orderStatus`（订单列表 cell）：`31`=Reject（详见 `MKOrderStatusMapper`）。
> 两者独立枚举，**不能混用**。

---

## 1. 背景与目标

当用户被拒贷（订单审核拒绝 / 申请被拒），App 引导用户跳转到合作方的 H5 落地页，将被拒流量转化为合作方的曝光与点击。

**目标**：
- 四类触发场景命中后，跳转配置接口返回的 `rejectH5` 链接
- H5 加载完成后注入用户上下文 `rejectData(JSON)`，含 appId / salt / mobile / baseUrl / userId / token
- 监听 H5 → 原生 `thirdUrl=...&type=...` 消息，调用系统浏览器打开外链 URL
- 跳转外部浏览器时上报埋点 **502**（500/501 由 H5 自行上报）
- 若 `rejectH5` 为空，全部回退到原有流程，不影响现有功能

**不在范围**：
- 后端配置接收方、三方用户信息传输接口
- H5 内 500/501 埋点（H5 自实现）
- 错误码 `6234303`、`userStatus==31` 等契约值由后端定义，前端按约定值识别

---

## 2. 架构

新增一个集中调度组件 `MKRejectFlowCoordinator`，封装"是否触发 + 如何打开 H5"两件事；四个触发点改一行调用。H5 容器子类化现有 `MKWebViewViewController`，专用于拒量页面，承担 JS 注入和 ScriptMessageHandler。

```
+------------------------------------------------------------+
| 触发点（四处一行调用）                                       |
|   - MKHomeViewController            (termV3 返回 6234303)   |
|   - MKReloanFlowHandler             (termV3 返回 6234303)   |
|   - MKHomeViewController 提示卡       (userStatus==51 + 点击) |
|   - MKOrderListViewController       (cell 拒绝订单点击)     |
+----------------------+-------------------------------------+
                       |
                       v
        +-------------------------------+
        | MKRejectFlowCoordinator       |
        |   + shouldTriggerRejectFlow   |
        |   + presentRejectH5FromVC:    |
        +---------------+---------------+
                        |
                        v
        +-------------------------------+
        | MKRejectWebViewController     |
        |   : MKBaseViewController      |
        |  - WKNavigationDelegate       |
        |    didFinish → rejectData(…)  |
        |  - WKScriptMessageHandler     |
        |    body 解析 → UIApplication  |
        |    .open + 埋点 502           |
        +-------------------------------+
                        |
                        v
        MKEventTrackingService.recordEventWithCode:@"502"
```

---

## 3. 组件清单

### 3.1 `MKAppConfigModel`（扩展）

新增字段：

```objc
@property (nonatomic, copy) NSString *rejectH5;
```

- **来源**：`POST /app/v3/app/config` 返回体（驼峰 key 已与后端确认）
- **缓存**：沿用现有 `MKAppConfigManager.sharedManager` 内存缓存
- **空判定**：`rejectH5.length > 0` 才视为已配置

### 3.2 `MKRejectFlowCoordinator`（新增）

文件位置：`PHI372-DC/Common/Manager/MKRejectFlowCoordinator.{h,m}`（与 `MKEventTrackingService` 同目录）

接口：

```objc
@interface MKRejectFlowCoordinator : NSObject

/// rejectH5 不为空时返回 YES；调用方据此决定走拒量分支还是原流程
+ (BOOL)shouldTriggerRejectFlow;

/// 打开拒量 H5（push 到 host 的 navigationController）
/// host 为 nil 时退化为 keyWindow.rootVC 推入；本设计要求传入当前 VC
+ (void)presentRejectH5FromVC:(UIViewController *)host;

@end
```

实现要点：
- `shouldTriggerRejectFlow` = `[MKAppConfigManager sharedManager].currentAppConfig.rejectH5.length > 0`
- `presentRejectH5FromVC:` 内部 new `MKRejectWebViewController`，传入 URL 后 `[host.navigationController pushViewController:web animated:YES]`
- 不持有状态，纯静态门面；判断条件唯一来源
- 不在 coordinator 里上报 500（按需求 500 由 H5 自报）

### 3.3 `MKRejectWebViewController`（新增）

文件位置：`PHI372-DC/Common/Views/MKRejectWebViewController.{h,m}`

继承 `MKBaseViewController`（实施阶段从原 spec 的 `MKWebViewViewController` 改下来，
父类 viewDidLoad 强制建 webView + loadRequest 且 ivar 私有，会导致双 WKWebView
实例与 URL 双重加载，详见 commit 4cc9ca9）。自建 WKWebView 并：

1. 在 `viewDidLoad` 中向 `WKWebViewConfiguration.userContentController` 注册 `addScriptMessageHandler:self name:@"native"`（具体 name 待 H5 联调确认，先用 `native`）
2. 重写 `webView:didFinishNavigation:`：成功加载后构造 JSON 并 `evaluateJavaScript:@"rejectData('<json>')"`

注入字段（按需求文档参考代码）：

| key | 来源 |
|-----|------|
| `appId`  | `[MKCommonParams sharedInstance].appId`（已初始化为 `kMKAppID` 宏） |
| `salt`   | `[MKCommonParams sharedInstance].salt`（已初始化为 `kMKSalt` 宏） |
| `mobile` | `[MKLoginManager sharedManager].mobile` |
| `userId` | `[MKLoginManager sharedManager].userId` |
| `token`  | `[MKLoginManager sharedManager].token` |
| `baseUrl`| `MKNetworkManager` baseURL 常量（沿用现有取法，避免散落字符串） |

JSON 序列化后做基本转义（按需求文档参考代码 `sanitizeJSONString`：把单引号、反斜杠、换行转义掉，避免破坏外层单引号），传入 `evaluateJavaScript`。

ScriptMessageHandler 回调：

```objc
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *body = [message.body description];
    if (![body hasPrefix:@"thirdUrl="]) return;

    NSString *trimmed = [body stringByReplacingOccurrencesOfString:@"thirdUrl=" withString:@""];
    trimmed = [trimmed stringByReplacingOccurrencesOfString:@"type=" withString:@""];
    NSArray *parts = [trimmed componentsSeparatedByString:@"&"];
    if (parts.count == 0) return;

    NSURL *url = [NSURL URLWithString:parts.firstObject];
    if (!url) return;

    [MKEventTrackingService recordEventWithCode:@"502"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}
```

**生命周期注意**：在 `viewWillDisappear:` 中主动 `removeScriptMessageHandlerForName:@"native"`，**不依赖 dealloc**（WKWebView 引用环可能让 dealloc 不及时触发）。`userContentController` 独立持有为 property，避免 dealloc 时 webView 已被 ARC 释放访问到 nil 失效。

### 3.4 触发点改造

**A. `MKHomeViewController.m:495-511`**（首页点击产品 → termV3 主流程）

```objc
if (resultCode == 6234303 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
    [MKRejectFlowCoordinator presentRejectH5FromVC:self];
    return;
}
// 原有 resultCode == 200 / 6230002 / 6230003 / 其他 toast 逻辑保持不变
```

**B. `MKReloanFlowHandler.m:140-143`**（复借流程 termV5 失败分支）

同 A 的拦截逻辑，host 取 `topMostViewController()` 或 handler 持有的 hostVC。

**C. `MKHomeViewController` 提示卡点击（userStatus==51 已拒绝）**

定位首页提示卡（`MKHomeKYCTipCardView` 当前用于 KYC 引导；userStatus==51 时复用同一卡位展示"已拒绝"提示文案，文案来自 `homeData.promptCopy`）。在卡 onTap 处理里：

```objc
if (homeData.userStatus == 51 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
    [MKRejectFlowCoordinator presentRejectH5FromVC:self];
    return;
}
// userStatus==10 等其他状态走原有跳转逻辑（KYC / 申请 / 详情等）
```

> 注：`userStatus==51` 与订单列表 `orderStatus==31` 是独立枚举，前者来自首页接口的用户态，后者来自订单态映射，分别在两处判断。

**D. `MKOrderListViewController.m:406-417`**（订单列表点击）

```objc
if (item.orderStatus == 31 && [MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
    [MKRejectFlowCoordinator presentRejectH5FromVC:self];
    return;
}
// 原有 push MKOrderDetailViewController 不动
```

### 3.5 `MKEventTrackingService`（无改动）

已有 `+ (void)recordEventWithCode:(NSString *)eventCode` 直接传 `@"502"` 即可。500/501 不在前端范围。

---

## 4. 数据流

### 4.1 触发路径

```
[ 配置接口 ] config.rejectH5 缓存 → shouldTriggerRejectFlow 返回 YES
       │
       ├──[A] 首页点产品 → termV3 → resultCode=6234303 ──┐
       ├──[B] 复借 handler → termV3 → resultCode=6234303 ┤
       ├──[C] 首页提示卡点击，userStatus==51 ────────────┤
       └──[D] 订单列表 cell，orderStatus==31 ────────────┤
                                                          │
                                                          ▼
                                  presentRejectH5FromVC:host
                                                          │
                                                          ▼
                                   push MKRejectWebViewController
                                          │
                                          ▼
                          load(rejectH5) → didFinish → rejectData(JSON)
```

### 4.2 H5 → 原生外跳

```
H5 调用 window.webkit.messageHandlers.native.postMessage("thirdUrl=https://x.com&type=ad")
       ▼
ScriptMessageHandler 收到 → 解析 → UIApplication.openURL
       ▼
MKEventTrackingService.recordEventWithCode("502")
```

---

## 5. 错误与边界

| 场景 | 行为 |
|------|------|
| `rejectH5` 为空 | `shouldTriggerRejectFlow` 返回 NO，所有触发点走原流程 |
| `rejectH5` 非合法 URL | `MKRejectWebViewController` 加载失败 → 沿用父类 `didFailNavigation` toast 提示 |
| H5 消息体非 `thirdUrl=` 前缀 | 直接 return，不做处理 |
| H5 消息体 URL 不合法 | `[NSURL URLWithString:]` 返回 nil → return，不上报 502 |
| App 切后台后 H5 投递消息 | WKWebView 暂停 → 不会触发；恢复后正常 |
| 用户回到拒量页（push 栈中） | 沿用父类返回按钮逻辑 |
| coordinator 被多次调用 | 不做幂等，每次 push 一个新 VC（与 H5 SPA 行为一致；如有问题后续加锁） |

---

## 6. 测试要点

- 后端 mock `rejectH5` 为空 / 非空 → 触发四个场景，分别验证回退 vs 跳转
- termV3 mock 返回 `resultCode=6234303`（首单 + 复借两条路径）
- 订单列表构造 `orderStatus==31` 的订单 → 点击进入 H5 而非详情
- 真机加载测试链接 `https://test-phl-api.fyinformation.cc/h5/juliang/index.html`，验证：
  - 注入的 JSON 在 H5 中可读到
  - H5 postMessage `thirdUrl=...&type=...` 触发外跳 Safari
  - 网络抓包确认 `/app/v3/bury/record` 上报 `eventCode=502`
- dealloc 验证：拒量 VC pop 后 `MKRejectWebViewController` 实例释放，无 ScriptMessageHandler 残留

---

## 7. 文件清单

新增：
- `PHI372-DC/Common/Manager/MKRejectFlowCoordinator.h`
- `PHI372-DC/Common/Manager/MKRejectFlowCoordinator.m`
- `PHI372-DC/Common/Views/MKRejectWebViewController.h`
- `PHI372-DC/Common/Views/MKRejectWebViewController.m`

修改：
- `PHI372-DC/Modules/Home/Model/MKAppConfigModel.{h,m}`（+ `rejectH5`）
- `PHI372-DC/Modules/Home/Controller/MKHomeViewController.m`（termV3 错误码分支 + KYC 卡点击分支）
- `PHI372-DC/Modules/Order/Controller/MKOrderListViewController.m`（cell 点击分支）
- `PHI372-DC/Modules/Home/MKReloanFlowHandler.m`（termV3 错误码分支）

不改：
- `MKWebViewViewController`（保持纯展示，避免被拒量逻辑污染）
- `MKNetworkManager`（不在网络层做业务码分发）
- `MKEventTrackingService`（接口已够用）

---

## 8. 风险与后续

- **`userStatus==51`、`orderStatus==31` 是已确认的契约值**（与后端对齐过），如未来枚举调整，仅改对应分支常量，coordinator/H5 层零影响。
- **ScriptMessage 名 `native`** 是占位，需 H5 联调时统一。
- **500/501 由 H5 自报**，前端在 H5 联调时需配合验证 H5 拿到注入参数后能上报。
- **`sanitizeJSONString` 实现**：先按"转义单引号 + 反斜杠 + 换行"处理；若 H5 反馈解析问题再迭代为 `base64(JSON)` 方案。
