//
//  MKEncryptManager.m
//  PHI372-DC
//

#import "MKEncryptManager.h"
#import "MKCommonParams.h"
#import "NSString+MKEncrypt.h"
#import "MKLoginManager.h"

@implementation MKEncryptManager

+ (instancetype)sharedManager {
    static MKEncryptManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[MKEncryptManager alloc] init];
    });
    return mgr;
}

- (NSString *)valueToString:(id)value {
    if (!value || [value isKindOfClass:[NSNull class]]) {
        return @"";
    }
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        id normalized = [NSString rd_normalizeJSONObject:value];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:normalized options:0 error:&error];
        if (!error && jsonData) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            return jsonString ?: @"";
        }
    }
    return [NSString stringWithFormat:@"%@", value];
}

#pragma mark - Encryption Method 1

- (NSDictionary *)generateRequestBody:(NSDictionary *)data {
    return [self generateRequestBodyWithSignData:data requestData:data];
}

- (NSDictionary *)generateRequestBodyWithSignData:(NSDictionary *)dataForSign
                                      requestData:(NSDictionary *)dataForRequest {
    MKCommonParams *cfg = [MKCommonParams shared];
    MKLoginManager *loginMgr = [MKLoginManager sharedManager];

    NSString *clientTime = [NSString rd_currentTimeMillisString];
    NSString *nonce = [NSString rd_randomNonce16];

    // Build sign params map
    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    if (dataForSign && [dataForSign isKindOfClass:[NSDictionary class]]) {
        [signParams addEntriesFromDictionary:dataForSign];
    }
    signParams[@"appId"] = cfg.appId ?: @"";
    signParams[@"deviceId"] = cfg.deviceId ?: @"";
    signParams[@"channel"] = cfg.channel ?: @"";
    signParams[@"nonce"] = nonce;
    signParams[@"version"] = cfg.version ?: @"2.0";
    signParams[@"clientTime"] = clientTime;
    signParams[@"os"] = @(cfg.os);

    // Extract values and sort ascending
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (id key in signParams) {
        [values addObject:[self valueToString:signParams[key]]];
    }
    NSArray *sorted = [values sortedArrayUsingSelector:@selector(compare:)];

    // Sign: MD5(sorted_values joined by "&") -> uppercase -> append salt -> MD5 -> uppercase
    NSString *s1 = [sorted componentsJoinedByString:@"&"];
    NSString *s2 = [[NSString rd_md5:s1] uppercaseString];
    NSString *s3 = [NSString stringWithFormat:@"%@%@", s2, cfg.salt ?: @""];
    NSString *sign = [[NSString rd_md5:s3] uppercaseString];

    NSLog(@"[Sign] keys=%@", [[signParams.allKeys sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@","]);
    NSLog(@"[Sign] sorted_values=[%@]", s1);
    NSLog(@"[Sign] md5(values)=%@ + salt=%@ → sign=%@", s2, cfg.salt, sign);

    // Build request body
    NSMutableDictionary *requestBody = [NSMutableDictionary dictionary];
    requestBody[@"data"] = dataForRequest ?: @{};
    requestBody[@"appId"] = cfg.appId ?: @"";
    requestBody[@"deviceId"] = cfg.deviceId ?: @"";
    requestBody[@"channel"] = cfg.channel ?: @"";
    requestBody[@"nonce"] = nonce;
    requestBody[@"version"] = cfg.version ?: @"2.0";
    requestBody[@"clientTime"] = clientTime;
    requestBody[@"os"] = @(cfg.os);
    requestBody[@"clientLanguage"] = cfg.clientLanguage ?: @"";
    requestBody[@"clientVersion"] = cfg.appDisplayVersion ?: @"";
    requestBody[@"sign"] = sign;
    requestBody[@"userId"] = loginMgr.userId ?: @"";
    requestBody[@"token"] = loginMgr.token ?: @"";

    return [requestBody copy];
}

#pragma mark - Encryption Method 3

- (NSDictionary *)generateRequestBodyForEncryptionThree:(NSDictionary *)data {
    return [self generateRequestBodyForEncryptionThreeWithSignData:data requestData:data];
}

- (NSDictionary *)generateRequestBodyForEncryptionThreeWithSignData:(NSDictionary *)dataForSign
                                                        requestData:(NSDictionary *)dataForRequest {
    MKCommonParams *cfg = [MKCommonParams shared];
    MKLoginManager *loginMgr = [MKLoginManager sharedManager];

    NSString *nonce = [NSString rd_randomNonce16];

    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    if (dataForSign && [dataForSign isKindOfClass:[NSDictionary class]]) {
        [signParams addEntriesFromDictionary:dataForSign];
    }
    signParams[@"appId"] = cfg.appId ?: @"";
    signParams[@"deviceId"] = cfg.deviceId ?: @"";
    signParams[@"channel"] = cfg.channel ?: @"";
    signParams[@"nonce"] = nonce;
    signParams[@"version"] = cfg.version ?: @"2.0";

    // Extract values and sort descending
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:signParams.count];
    for (id key in signParams) {
        [values addObject:[self valueToString:signParams[key]]];
    }
    NSArray<NSString *> *sortedDesc = [values sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj2 compare:obj1];
    }];

    // Sign: sorted_desc joined by ";" -> append salt -> MD5 -> uppercase
    NSString *s1 = [sortedDesc componentsJoinedByString:@";"];
    NSString *signInput = [NSString stringWithFormat:@"%@%@", s1, cfg.salt ?: @""];
    NSString *sign = [[NSString rd_md5:signInput] uppercaseString];

    NSMutableDictionary *requestBody = [NSMutableDictionary dictionary];
    requestBody[@"data"] = dataForRequest ?: @{};
    requestBody[@"appId"] = cfg.appId ?: @"";
    requestBody[@"deviceId"] = cfg.deviceId ?: @"";
    requestBody[@"channel"] = cfg.channel ?: @"";
    requestBody[@"nonce"] = nonce;
    requestBody[@"version"] = cfg.version ?: @"2.0";
    requestBody[@"sign"] = sign;
    requestBody[@"userId"] = loginMgr.userId ?: @"";
    requestBody[@"token"] = loginMgr.token ?: @"";

    return [requestBody copy];
}

@end
