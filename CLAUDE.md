# CLAUDE.md — PHI372-DC

iOS 借贷类工程,Objective-C + UIKit + Masonry。

## 启动每个任务前必读

1. **[CODE_MAP.md](./CODE_MAP.md)** — 全目录功能索引,先用它定位目标目录
2. 进入子目录工作时,读取**该目录的 `CLAUDE.md`**(局部约定不在根,在目录里)

## 工作铁律(违反一次都不行)

- **UI 必须基于 Pencil 节点的精确数据(坐标/hex/字号)**,截图只用于验收,不用于反推
- **新建 Model / 弹窗 / Manager 前先 grep 同名类** — 工程预置 22+ 弹窗(`MKBottomSheetView` 枚举)和合并式 Model,禁止平行实现
- **改 Apply / Order / KYC 后必须真机或模拟器跑 e2e** — `xcodebuild` 通过 ≠ 完成
- **调试用 `NSLog` 修完 bug 必须删干净** — 排查阶段加的 `NSLog`/printf/临时断点变量,fix 验证后立刻移除;`grep -n "NSLog" <改过的文件>` 确认 0 残留再 commit

## 关键陷阱

- 模拟器: iPhone 17 Pro, id `5D3DF5C9-B78D-4620-9EE0-A4CEF34E1D86`
- `idb` 路径: `~/Library/Python/3.9/bin/`(不在 PATH,需 export 或绝对路径)
- Xcode 16 同步文件夹组(`PBXFileSystemSynchronizedRootGroup`) — 文件落到物理路径即自动入工程,**不要手 patch `project.pbxproj`**
- 主色: `#385330`(绿) / `#E9E9E4`(浅灰卡片) / `#D1D1CF`(分割线)
- Scale 宏: `kScaleW / kScaleH` 基于 375 设计稿宽,所有坐标必须用它包
- 字体/颜色/常量统一从 `Common/Macros/MKConstants.h` 取,不要硬编码

## 文档结构

```
CLAUDE.md          ← 全局指针 + 陷阱(你正在读)
CODE_MAP.md        ← 目录索引(每次开工先扫)
PHI372-DC/CLAUDE.md ← App 壳约定
  └ Common/CLAUDE.md   ← 共享基础(先复用别新建)
  └ Modules/CLAUDE.md  ← 模块组织规则
    └ KYC/CLAUDE.md, Order/CLAUDE.md ... 各模块局部约定
```
