//
//  MKRejectFlowCoordinator.h
//  PHI372-DC
//
//  拒量输出调度器。判定是否触发、负责跳转 H5。
//
//  调用方式: 在 4 个触发点(termV3 6234303 / 首页提示卡 userStatus=51 /
//  复借 termV3 6234303 / 订单列表 orderStatus=31)各加一行:
//
//      if ([MKRejectFlowCoordinator shouldTriggerRejectFlow]) {
//          [MKRejectFlowCoordinator presentRejectH5FromVC:self];
//          return;
//      }
//

#import <Foundation/Foundation.h>

@class UIViewController;

NS_ASSUME_NONNULL_BEGIN

@interface MKRejectFlowCoordinator : NSObject

/// rejectH5 不为空时返回 YES。
+ (BOOL)shouldTriggerRejectFlow;

/// 在 host.navigationController 上 push MKRejectWebViewController。host 必传。
+ (void)presentRejectH5FromVC:(UIViewController *)host;

@end

NS_ASSUME_NONNULL_END
