//
//  MKRatingPromptManager.h
//  PHI372-DC
//
//  好评引导触发协调器(跨模块,走 NSUserDefaults 持久标志)。
//  下单成功页(Order/Product/Home)只调 noteOrderCompleted 打标志;
//  首页在 viewDidAppear 调 consumePendingFlag 决定是否弹好评引导。
//  仅首单触发一次;弹过即永久不再弹(hasShownPrompt)。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKRatingPromptManager : NSObject

/// 下单成功调用。仅首单会置"待弹"标志,后续订单不触发。
+ (void)noteOrderCompleted;

/// 读取并清除"待弹"标志。返回 YES 表示首页应弹好评引导。
+ (BOOL)consumePendingFlag;

/// 是否已经弹过好评引导(永久一次性)。
+ (BOOL)hasShownPrompt;

/// 标记好评引导已弹出。
+ (void)markPromptShown;

@end

NS_ASSUME_NONNULL_END
