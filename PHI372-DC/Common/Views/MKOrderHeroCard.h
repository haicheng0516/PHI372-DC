//
//  MKOrderHeroCard.h
//  PHI372-DC — Figma 3:719 / 3:761 / 3:814 Order detail 顶部 Hero 卡 (状态色切换)
//
//  尺寸: 339×171 r=14
//  bgColor 由 state 决定:
//    Reviewing       #11722E (绿)
//    Withdraw        #FB8E11 (橙)
//    PendingRepay    #AF5D00 (棕)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MKOrderHeroState) {
    MKOrderHeroStateReviewing,        // 审核中  #11722E
    MKOrderHeroStateWithdraw,         // 待提现  #FB8E11
    MKOrderHeroStatePendingRepay,     // 待还款  #AF5D00
    MKOrderHeroStateCustom,           // 自定义色
};

@interface MKOrderHeroCard : UIView
- (instancetype)initWithState:(MKOrderHeroState)state;
- (void)setAppName:(NSString *)name;
- (void)setStatusText:(NSString *)text;
- (void)setAmount:(NSString *)amount;     // "₱ 50,000"
- (void)setTermText:(NSString *)term;     // "180 Days"
- (void)setCustomColor:(UIColor *)color;  // 仅 Custom state 用
+ (CGFloat)cardHeight;                    // 171
@end

NS_ASSUME_NONNULL_END
