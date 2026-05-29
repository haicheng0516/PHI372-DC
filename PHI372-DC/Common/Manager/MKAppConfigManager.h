//
//  MKAppConfigManager.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>
#import "MKAppConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKAppConfigManager : NSObject
+ (instancetype)sharedManager;
@property (nonatomic, strong, nullable) MKAppConfigModel *currentAppConfig;
- (BOOL)hasAppConfig;

/// 拉取 /app/v3/app/config 并写入 currentAppConfig(失败静默)
- (void)loadConfig;
/// 拉取配置,完成回调返回最新配置(失败回调 nil)
- (void)loadConfigWithCompletion:(void (^_Nullable)(MKAppConfigModel *_Nullable config))completion;
@end

NS_ASSUME_NONNULL_END
