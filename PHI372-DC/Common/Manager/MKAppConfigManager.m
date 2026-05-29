//
//  MKAppConfigManager.m
//

#import "MKAppConfigManager.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKAppEnvironment.h"

@implementation MKAppConfigManager
+ (instancetype)sharedManager {
    static MKAppConfigManager *inst; static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [[self alloc] init]; });
    return inst;
}
- (BOOL)hasAppConfig { return self.currentAppConfig != nil; }

- (void)loadConfig {
    [self loadConfigWithCompletion:nil];
}

- (void)loadConfigWithCompletion:(void (^)(MKAppConfigModel *_Nullable))completion {
    NSMutableDictionary *body = [[[MKEncryptManager sharedManager] generateRequestBody:@{}] mutableCopy];
    body[@"merchantId"] = [MKAppEnvironment merchantId];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/app/config"
                                    params:body
                                   success:^(id resp) {
        MKAppConfigModel *config = nil;
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"data"] isKindOfClass:[NSDictionary class]]) {
            config = [MKAppConfigModel modelWithDictionary:resp[@"data"]];
            wself.currentAppConfig = config;
        }
        if (completion) completion(config);
    } failure:^(NSError *error) {
        if (completion) completion(nil);
    }];
}
@end
