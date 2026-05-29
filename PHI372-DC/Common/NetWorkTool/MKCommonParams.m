//
//  MKCommonParams.m
//

#import "MKCommonParams.h"
#import <UIKit/UIKit.h>
#import "MKConstants.h"
#import "MKAppEnvironment.h"

@implementation MKCommonParams

+ (instancetype)shared {
    static MKCommonParams *cfg;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cfg = [[MKCommonParams alloc] init];

        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0.0";
        // 走 MKAppDisplayName 读 Info.plist 的展示名, 不用工程名兜底
        NSString *appName = MKAppDisplayName();

        cfg.appId = [MKAppEnvironment appId];
        cfg.salt = [MKAppEnvironment salt];
        cfg.secretKey = @"";
        cfg.channel = @"app_store";
        cfg.clientVersion = appVersion;
        cfg.version = @"2.0";
        cfg.os = 2;  // iOS = 2
        cfg.clientLanguage = @"en";
        cfg.deviceId = [cfg loadOrCreateDeviceId];
        cfg.appName = appName;
        cfg.appDisplayVersion = appVersion;
    });
    return cfg;
}

- (NSString *)loadOrCreateDeviceId {
    NSString *key = @"MKCommonParams_deviceId";
    NSString *did = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if (did.length == 0) {
        did = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:did forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return did;
}

@end
