//
//  MKAppConfigManager.m
//  PHI372-DC
//

#import "MKAppConfigManager.h"

@implementation MKAppConfigManager
+ (instancetype)sharedManager {
    static MKAppConfigManager *inst; static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [[self alloc] init]; });
    return inst;
}
- (BOOL)hasAppConfig { return self.currentAppConfig != nil; }
@end
