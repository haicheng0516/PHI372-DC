//  MKLoanProductHeroView.h
//  Hero 绿卡 (#385330 r24)
//    Full    — 244 高, 产品申请页 (含 sub-label + 大号 ₱amount + 钱袋 + chevron affordance)
//    Compact — 171 高, 订单详情态 (审核中/待提现/待还款) — TODO: 后续接入时实现
//    Mini    — 144 高, 还款页 — TODO: 后续接入时实现

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKHeroVariant) {
    MKHeroVariantFull = 0,    // Pencil b4hMw0 / LbSVz: 339×244
    MKHeroVariantCompact,     // Pencil cpq29 / b5RSzJ / hv74X: 339×171  (TODO)
    MKHeroVariantMini,        // Pencil qxkIX: 339×144  (TODO)
};

@interface MKLoanProductHeroView : UIView

- (instancetype)initWithVariant:(MKHeroVariant)variant;

/// Hero 当前 variant 高度
+ (CGFloat)heightForVariant:(MKHeroVariant)variant;

/// 配置内容 (Full variant — 申请页)
- (void)configureAppName:(NSString *)appName
                termText:(NSString *)termText
              amountText:(NSString *)amountText
              subLabel:(NSString *)subLabel;

/// 配置内容 (Compact variant — 订单详情页)
/// @param statusText 右上角状态文案 (e.g. "Under review" / "Pending Repayment" / "To be withdrawn"); 无背景, 白字
- (void)configureCompactAppName:(NSString *)appName
                       termText:(NSString *)termText
                     amountText:(NSString *)amountText
                     statusText:(NSString *)statusText;

/// 加载产品 logo (顶部白底圆角小框)
- (void)setProductLogoURL:(nullable NSString *)urlStr;

/// 是否多金额 (决定 amount chevron 显示 + sub label 文案)
@property (nonatomic, assign) BOOL isMultiAmount;

/// 是否多期限 (独立判断, 决定 term capsule chevron 显示)
@property (nonatomic, assign) BOOL isMultiTerm;

/// 回调
@property (nonatomic, copy, nullable) void(^onTermCapsuleTapped)(void);
@property (nonatomic, copy, nullable) void(^onAmountChevronTapped)(void);
@property (nonatomic, copy, nullable) void(^onAmountSubLabelTapped)(UIView *anchor);

@end

NS_ASSUME_NONNULL_END
