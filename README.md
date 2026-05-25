# PHI372-DC

iOS 借贷类工程,基于 Objective-C + UIKit + Masonry。

## 技术栈

| 类型 | 选型 |
|---|---|
| 语言 | Objective-C |
| UI 框架 | UIKit + Masonry(约束布局) |
| 网络 | AFNetworking 4.0.1(`MKNetworkManager` 封装) |
| 图片 | SDWebImage |
| HUD / Toast | SVProgressHUD |
| 依赖管理 | CocoaPods |
| 最低系统 | iOS 13 |
| Xcode | 16+(使用同步文件夹组) |

## 环境要求

- macOS + Xcode 16 以上
- CocoaPods(`sudo gem install cocoapods`)
- iPhone 17 Pro 模拟器或真机(iOS 16/17 验收)

## 构建运行

```bash
# 1. 安装依赖
pod install

# 2. 用 workspace 打开(不要直接打开 xcodeproj)
open PHI372-DC.xcworkspace

# 3. Xcode 中选好 Team 后,Cmd+R 运行
```

命令行 build:

```bash
xcodebuild \
  -workspace PHI372-DC.xcworkspace \
  -scheme PHI372-DC \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

## 项目结构

```
PHI372-DC/
├── AppDelegate.* / SceneDelegate.*    # App 生命周期入口
├── Info.plist                          # 权限文案 + 启动配置
├── Assets.xcassets/                    # 图片资源(mk_xxx 命名)
├── Common/                             # 跨模块共享基础
│   ├── Base/        # MKBaseViewController / MKNavigationController
│   ├── Category/    # NSString+MKAmount(金额格式化)等
│   ├── Macros/      # MKConstants.h(颜色/字体/scale 宏)
│   ├── Manager/     # 登录/订单状态机/复借决策
│   ├── NetWorkTool/ # 网络/加密/公参/校验
│   └── Views/       # 22+ 通用 UI 组件(MKBottomSheetView 等)
└── Modules/                            # 业务功能模块
    ├── Launch/      # 启动页
    ├── Login/       # 登录(手机号 + OTP)
    ├── KYC/         # 实名认证 8 步
    ├── Home/        # 首页 + 换绑银行卡
    ├── Product/     # 产品申请页
    ├── Order/       # 订单列表 + 详情 + 还款
    └── Profile/     # 个人中心
```

完整目录索引见 [CODE_MAP.md](./CODE_MAP.md)。

## 核心业务模块

| 模块 | 关键功能 |
|---|---|
| **Login** | 手机号 + OTP 一步登录;首次手机号即注册 |
| **KYC** | 8 步实名: Personal / ID / IDCamera / Liveness / Finance / Contact / Payment / BankCardEdit |
| **Home** | Banner + 合作伙伴 + 产品入口 + 提现拦截 |
| **Product** | 单 VC + selectionMode 切换,支持多金额/多期限选择 |
| **Order** | 列表按 orderStatus 分 4 段(Submit/Pending/Processing/Completed),详情页单 VC 多状态驱动 UI |
| **Profile** | 个人中心 + 协议 / 反馈 / 复借入口 |

## 开发约定

- 所有 VC 继承 `MKBaseViewController`,自带 `MKNavBar`
- 颜色 / 字体 / scale 一律从 `Common/Macros/MKConstants.h` 取,禁止硬编码
- 弹窗 / 选择器一律走 `MKBottomSheetView` 枚举(22+ 类),禁止新建独立 picker
- 网络请求一律走 `MKNetworkManager`(签名/加密/公参已内置)
- 资源命名 `mk_xxx`,统一进 `Assets.xcassets`
- UI 坐标必须用 `kScaleW / kScaleH` 宏(基于 375 设计稿宽)

完整开发规则见 [CLAUDE.md](./CLAUDE.md)。

## 文档体系

```
CLAUDE.md                  ← 全局指针 + 陷阱
CODE_MAP.md                ← 目录索引
PHI372-DC/CLAUDE.md        ← App 壳约定
  ├ Common/CLAUDE.md       ← 共享基础(先复用别新建)
  └ Modules/CLAUDE.md      ← 模块组织规则
      ├ KYC/CLAUDE.md
      ├ Order/CLAUDE.md
      ├ Home/CLAUDE.md
      ├ Product/CLAUDE.md
      ├ Profile/CLAUDE.md
      └ Login/CLAUDE.md
```

每个目录的 `CLAUDE.md` 只放该目录独有约定,通用规则在父级。

## License

私有项目,版权所有。
