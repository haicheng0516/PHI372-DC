//
//  MKNotificationPermissionCoordinator.h
//  PHI372-DC
//
//  通知权限请求调度(对齐已上线 SeacityDC318 / IN464-DC):
//  - 一天检查一次(按日历日,凌晨 0 点重置)
//  - 首次 notDetermined → 拉系统弹窗;同意埋 600 拉 FCM token;拒绝埋 601
//  - denied → 显示二次引导弹窗(本项目封装的返回弹窗,引导去设置),弹窗显示即埋 601
//  - 已授权 → 直接注册 + 拉 token 上报
//  - App 回前台 → 状态从非授权切到授权(用户在设置里手动开)→ 补埋 600 + register + 拉 token
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKNotificationPermissionCoordinator : NSObject

+ (instancetype)sharedManager;

/// 今天是否已检查过(按日历日)。
@property (nonatomic, readonly) BOOL hasCheckedToday;

/// 显式同步通知权限状态。由 SceneDelegate.sceneDidBecomeActive 主动调用一次,
/// 避免单例懒加载时序问题(冷启动时 sharedManager 可能还没被访问,didBecomeActive 通知会被错过)。
- (void)syncPermissionStatusIfNeeded;

/// 执行权限检查;completion 返回是否真的弹了窗(供首页弹窗队列排队判断)。
- (void)checkAndRequestIfNeededWithCompletion:(void (^ _Nullable)(BOOL didPresent))completion;

@end

NS_ASSUME_NONNULL_END
