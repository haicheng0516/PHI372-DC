//  MKConstants.h
//  PHI372-DC
//  所有颜色值严格来自Figma设计稿JSON

#ifndef MKConstants_h
#define MKConstants_h

#import <UIKit/UIKit.h>

// Screen 适配 — 关键陷阱 G1:
//   旧实现用 keyWindow 拿屏宽,但 viewDidLoad 时 scene 未激活,返回 nil 导致缩放失效。
//   现改用 UIScreen.mainScreen,确保 viewDidLoad 即可用。
//   safeAreaInsets 仍需 window,所以保留 mk_keyWindow() 但仅 viewWillAppear+ 才能稳定使用。
static inline UIWindow * _Nullable mk_keyWindow(void) {
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) return window;
            }
        }
    }
    // 兜底: 取任一已连接 scene 的 window
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class] && scene.windows.firstObject) {
            return scene.windows.firstObject;
        }
    }
    return nil;
}

#define kScreenWidth  ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define kScale (kScreenWidth / 375.0)
#define kScaleW(w) ((w) * kScale)
#define kScaleH(h) ((h) * kScale)
#define kStatusBarHeight (mk_keyWindow().safeAreaInsets.top)
#define kNavBarHeight (kStatusBarHeight + 44.0)
#define kBottomSafeHeight (mk_keyWindow().safeAreaInsets.bottom)

// Color Macros
#define MKColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define MKColorAlpha(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define MKHexColor(hex) [UIColor colorWithRed:((hex >> 16) & 0xFF)/255.0 green:((hex >> 8) & 0xFF)/255.0 blue:(hex & 0xFF)/255.0 alpha:1.0]
#define MKHexColorAlpha(hex, a) [UIColor colorWithRed:((hex >> 16) & 0xFF)/255.0 green:((hex >> 8) & 0xFF)/255.0 blue:(hex & 0xFF)/255.0 alpha:(a)]

// ============ 设计稿精确色值 (Figma file: wu0stGMF4bln3OP0V0t3mJ) ============
// Token 来源: 综合 Sign-in (3:1743) + Home-kyc前 (3:1786) globalVars.styles
// 对应 Figma globalVars 列在右侧注释

// 主色系 - 深绿
#define kColorPrimary       MKHexColor(0x385330)   // fill_YLFCXD: 按钮/CTA/渐变起点
#define kColorPrimaryDark   MKHexColor(0x252F2C)   // fill_2VOYMT/fill_9CB9IK: 胶囊深色/icon背景
#define kColorAccentGreen   MKHexColor(0xBBCB2F)   // fill_KUSM7S: 黄绿强调(safe stroke)
#define kColorBrightGreen   MKHexColor(0x30DC5E)   // fill_XCWJYV: 亮绿小标签

// 背景色
#define kColorBackground    MKHexColor(0xF8F8F7)   // fill_VD7CCF/fill_0C5IX6/fill_9IIZWE: 主背景
#define kColorBgAlt         MKHexColor(0xECEFF3)   // fill_BADBFA: KYC失败/启动页备用背景
#define kColorCardBg        MKHexColor(0xFFFFFF)   // fill_R8KTR4/fill_KBP5LL/fill_1JG958: 弹窗/纯白
#define kColorCardSecondary MKHexColor(0xE9E9E4)   // fill_FOTS7F/fill_W80EM5: 卡片/输入框米色
#define kColorKYCPanel      MKHexColor(0xE9E9E4)   // KYC 米色面板内层
#define kColorKYCCell       MKHexColor(0xF8F8F7)   // KYC cell 浅米 (与 view bg 同, 但在 panel 上看着浮)
#define kColorChevronCircle MKHexColor(0x60A786)   // KYC chevron 中绿圆
#define kColorContactIconGreen MKHexColor(0x98C900) // 联系人头像主色亮黄绿
#define kColorWhite         [UIColor whiteColor]
#define kColorOverlay       MKColorAlpha(0, 0, 0, 0.5)

// 文字色
#define kColorTextPrimary   MKHexColor(0x171718)   // Neutral/1: 主文字
#define kColorBlack         MKHexColor(0x000000)   // fill_UDCW2V: 副标题/icon label (近似主文字)
#define kColorTextSecondary MKHexColor(0x999999)   // fill_SYW5R2/fill_MXXTXW: 次要文字/placeholder
#define kColorTextHint      MKHexColor(0x8F8F8F)   // Secondary: 边框/灰色描边
#define kColorFootnote      MKHexColor(0xA6AFBC)   // fill_T8OMBB: 底部声明文字
#define kColorIconLight     MKHexColor(0xDADADA)   // fill_QFKJNN/fill_9M2VVU: 状态栏 icon 浅灰

// 渐变 (顶部 484pt 渐变, 27% 主色 → 53% 背景)
#define kColorGradientTop    kColorPrimary        // #385330
#define kColorGradientBottom kColorBackground     // #F8F8F7

// 状态色
#define kColorSuccess       MKHexColor(0x4CAF50)
#define kColorError         MKHexColor(0xF44336)

// === 兼容旧宏 (避免业务层引用断裂) ===
#define kColorPrimaryLight  kColorTextSecondary
#define kColorOrange        MKHexColor(0xEB8A54)
#define kColorOrangeLight   MKHexColor(0xEBD754)
#define kColorOrangeGradientStart MKHexColor(0xF67904)
#define kColorOrangeGradientEnd   MKHexColor(0xFFE15C)
#define kColorBgTeal        kColorCardSecondary
#define kColorBgInput       kColorCardSecondary
#define kColorTextDark      kColorTextPrimary
#define kColorTextLabel     kColorTextSecondary
#define kColorTextQuota     kColorTextSecondary
#define kColorTeal          MKHexColor(0xC5DEE6)
#define kColorTealLight     kColorCardSecondary
#define kColorCardDecor     MKHexColor(0xC4D1D5)
#define kColorLine          MKHexColor(0xD9D9D9)
#define kColorBorderGray    kColorTextHint
#define kColorGray          kColorTextSecondary
#define kColorLightGray     MKHexColor(0xCCCCCC)
#define kColorUsernamePurple MKHexColor(0x8487E3)
#define kColorGradientStart kColorGradientTop
#define kColorGradientEnd   kColorGradientBottom
#define kColorBannerBlueStart  MKHexColor(0x00739D)
#define kColorBannerBlueEnd    MKHexColor(0x00114E)
#define kColorBannerRedStart   MKHexColor(0xC7402D)
#define kColorBannerRedEnd     MKHexColor(0x691100)

// ============ 字体 ============
// 设计稿字体: Poppins (英文/数字) / PingFang SC (中文) / Inter (大额数字)
// iOS 系统字体近似: SF Pro 与 Poppins 视觉差异约 5-10%, 可后续 Phase 9 加 Poppins .ttf
// PingFang SC 为 iOS 默认中文字体,完美匹配
#define kFontRegular(s)  [UIFont systemFontOfSize:(s)]
#define kFontMedium(s)   [UIFont systemFontOfSize:(s) weight:UIFontWeightMedium]
#define kFontSemibold(s) [UIFont systemFontOfSize:(s) weight:UIFontWeightSemibold]
#define kFontBold(s)     [UIFont boldSystemFontOfSize:(s)]

// 设计稿精确字体规格 (按 Figma TextStyle 命名)
// Poppins
#define kFontPoppins12     kFontRegular(12)              // style_1BC07M: 协议文字
#define kFontPoppins15     kFontRegular(15)              // style_Z7J8A9: 输入 placeholder
#define kFontPoppins14     kFontRegular(14)              // style_2U58NP: 底部声明
#define kFontButtonLarge   kFontSemibold(16)             // Button/Large: CTA 按钮
#define kFontBodySemibold  kFontSemibold(16)             // Body/1/Semibold
// PingFang SC
#define kFontPingFang14    kFontRegular(14)              // style_5NWUFP/style_CLLE82: label/卡片正文
#define kFontPingFang14M   kFontMedium(14)               // (按钮文字)
#define kFontPingFang14S   kFontSemibold(14)             // style_33ETNN/MV90AH/8XGK5W: icon 下标签
#define kFontPingFang16M   kFontMedium(16)               // style_T5UDTI: Get OTP
#define kFontPingFang20M   kFontMedium(20)               // style_SJFSZS: welcome 标题

// Weak/Strong Self
#define kWeakSelf __weak typeof(self) weakSelf = self;
#define kStrongSelf __strong typeof(weakSelf) strongSelf = weakSelf;

// App 显示名: 全部走 Info.plist (CFBundleDisplayName → CFBundleName → CFBundleExecutable)
// 用户可见的 Profile/About/网络 appName 字段都走这个,避免工程名 (PHI372-DC) 泄露
// 本工程只需改 Info.plist 一处
static inline NSString *MKAppDisplayName(void) {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *n = info[@"CFBundleDisplayName"];
    if (n.length > 0) return n;
    n = info[@"CFBundleName"];
    if (n.length > 0) return n;
    n = info[@"CFBundleExecutable"];
    return n.length > 0 ? n : @"App";
}

#endif /* MKConstants_h */
