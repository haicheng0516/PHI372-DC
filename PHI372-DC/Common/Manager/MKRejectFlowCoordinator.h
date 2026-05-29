//
//  MKRejectFlowCoordinator.h
//
//  拒量输出调度器。判定 + 跳转一体, 调用方只关心"接管了吗"。
//
//  典型调用 (任一触发点):
//
//      if (code == 6234303 && [MKRejectFlowCoordinator presentRejectH5FromVC:self]) return;
//
//  非 VC 类(如 Manager) 调 nil, 内部自动找 top VC:
//
//      if (code == 6234303 && [MKRejectFlowCoordinator presentRejectH5FromVC:nil]) return;
//

#import <Foundation/Foundation.h>

@class UIViewController;

NS_ASSUME_NONNULL_BEGIN

@interface MKRejectFlowCoordinator : NSObject

/// 仅当 rejectH5 已配置时返回 YES。
/// 不调跳转、不消费, 用于"提前判断要不要显示拒量入口"等纯查询场景。
/// 触发点直接用 +presentRejectH5FromVC: 的返回值即可, 不必先查这个。
+ (BOOL)shouldTriggerRejectFlow;

/// 尝试 push 拒量 H5。
/// @param host 期望承载跳转的 VC, 为 nil 时自动用 keyWindow 栈顶 VC。
/// @return YES = 已接管并跳转(调用方应 return); NO = 未配置或无可用 host(调用方走原分支)。
+ (BOOL)presentRejectH5FromVC:(nullable UIViewController *)host;

@end

NS_ASSUME_NONNULL_END
