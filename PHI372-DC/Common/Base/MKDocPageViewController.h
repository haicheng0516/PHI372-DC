//
//  MKDocPageViewController.h
//  PHI372-DC — Figma 3:1257 / 3:1296 / 3:1313 等 Doc 页基类
//
//  通用结构: 品牌绿 nav (98pt #385330 r=0,0,14,14) + UIScrollView 内堆叠:
//    - 可选 hint banner
//    - N 个 Doc card (灰底 + 可选小节标题 + 正文)
//    - N 个 Contact row (icon + URL/email + copy)
//    - 可选 hero header (About 用)
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKDocPageItem : NSObject
+ (instancetype)hintWithText:(NSString *)text;
+ (instancetype)docWithSectionTitle:(nullable NSString *)title body:(NSString *)body;
+ (instancetype)websiteWithURL:(NSString *)url;
+ (instancetype)emailWithAddress:(NSString *)email;
+ (instancetype)spacingWithHeight:(CGFloat)height;
+ (instancetype)customViewWithProvider:(UIView * (^)(CGFloat width))provider;
@end

@interface MKDocPageViewController : MKBaseViewController
@property (nonatomic, copy) NSArray<MKDocPageItem *> *items;
/// 顶部 hero header (About 用 222pt header) — 设置后会替代 navTitle 区域内的标准 nav
@property (nonatomic, strong, nullable) UIView *heroHeaderView;
- (instancetype)initWithTitle:(NSString *)title items:(NSArray<MKDocPageItem *> *)items;
/// 用新的 items 重渲染(异步配置到达后刷新页面)。需在 view 加载后调用。
- (void)reloadDocItems;
@end

NS_ASSUME_NONNULL_END
