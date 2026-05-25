//
//  MKCommonParams.m
//  PHI372-DC
//

#import "MKCommonParams.h"
#import <UIKit/UIKit.h>
#import "MKConstants.h"

/// PHI372-DC 项目配置
static NSString * const kMKAppID = @"phi372-dc";
static NSString * const kMKSalt  = @"qdaGzDWaf2plCOcP";

@implementation MKCommonParams

+ (instancetype)shared {
    static MKCommonParams *cfg;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cfg = [[MKCommonParams alloc] init];

        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0.0";
        // 用 MKAppDisplayName(): 工程名兜底字符串(PHI372-DC)在网络层 appName 字段不应泄露
        NSString *appName = MKAppDisplayName();

        cfg.appId = kMKAppID;
        cfg.salt = kMKSalt;
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
