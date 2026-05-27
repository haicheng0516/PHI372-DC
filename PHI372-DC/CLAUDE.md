# CLAUDE.md — App 壳

App 源码根目录。负责生命周期 + 全局资源 + 模块装配。

## 启动链路

```
main.m → AppDelegate
       → LaunchScreen.storyboard (系统启动屏: Se_bg 全屏 + 右下角 logo + APP name)
       → SceneDelegate.willConnectToSession
       → 视登录态直接装载 MKSignInViewController 或 MKHomeViewController
         (无中间 splash VC, 不靠定时器跳转)
```

调试入口(可选): `defaults write yanwenbo.developer.app MK.DebugRoute -string "VCClassName"` —
SceneDelegate 检测到 `MK.DebugRoute` 时以 Home 为锚 push 指定 VC。

## 约定

- **AppDelegate 不放业务逻辑**,只做 SDK init / 全局配置(主题、字体注册、第三方初始化)
- 所有业务 VC 继承 `MKBaseViewController`(自带 `MKNavBar`,不要直接用系统 `UINavigationBar`)
- 资源命名: `mk_xxx`,统一进 `Assets.xcassets`,**不要在工程根目录散放 png**
- 字体/颜色/scale/全局常量走 `Common/Macros/MKConstants.h`,不要硬编码
- `Info.plist` 里的权限文案 (`NSCameraUsageDescription` 等) 必须与实际使用场景匹配,不能写空话

## 文件落位

| 类型 | 位置 |
|---|---|
| 启动配置 | `Info.plist`, `AppDelegate.*`, `SceneDelegate.*`, `Base.lproj/LaunchScreen.storyboard` |
| 图片 | `Assets.xcassets/<name>.imageset/` |
| 通用基础 | `Common/`(详见 [Common/CLAUDE.md](./Common/CLAUDE.md)) |
| 业务功能 | `Modules/<Feature>/`(详见 [Modules/CLAUDE.md](./Modules/CLAUDE.md)) |

## 启动屏(LaunchScreen.storyboard)

- 系统启动屏走 `Base.lproj/LaunchScreen.storyboard`(`INFOPLIST_KEY_UILaunchStoryboardName=LaunchScreen`)
- 内容: `Se_bg` 全屏 + 右下区 50×50 白色圆角 logo 占位 + 24pt 白色 "APP name"
- **不要为启动屏写 VC**;系统加载完直接交给 SceneDelegate 决定下一屏

## Xcode 16 同步文件夹组

工程使用 `PBXFileSystemSynchronizedRootGroup` — **文件放到物理目录即自动入工程**,不要手 patch `project.pbxproj`。如果文件加了但没编译,先检查物理路径在不在 `PHI372-DC/` 树里。
