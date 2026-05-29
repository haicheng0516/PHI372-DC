//
//  MKBaseViewController.h
//
//  统一基类: 状态栏样式 / 自定义 NavBar / 通用 back / 屏宽适配
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKNavBarStyle) {
    MKNavBarStyleNone,           // 无导航栏(启动页 / 登录页 / 全屏弹窗)
    MKNavBarStyleTransparent,    // 透明导航(渐变顶部页面: 首页 / KYC 拍照)
    MKNavBarStyleLight,          // 白底黑字标题 + 黑返回箭头(列表 / 详情 / 个人中心子页)
    MKNavBarStylePrimaryDark,    // 深绿底 + 白标题 + 黄绿返回箭头 (KYC 流程)
};

@interface MKBaseViewController : UIViewController

/// 导航栏样式 (子类在 viewDidLoad 之前在 init 或 viewDidLoad 头部设置)
@property (nonatomic, assign) MKNavBarStyle navBarStyle;

/// 标题文字 (仅 Light 样式生效)
@property (nonatomic, copy, nullable) NSString *navTitle;

/// 状态栏样式 (默认根据 navBarStyle 推断: None/Transparent → LightContent, Light → Default)
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

/// 自定义返回按钮处理 (默认 popViewController), 子类可重写
- (void)onBackTapped;

@end

NS_ASSUME_NONNULL_END
