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
@end

NS_ASSUME_NONNULL_END
