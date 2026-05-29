//
//  NSString+MKEncrypt.m
//

#import "NSString+MKEncrypt.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (MKEncrypt)

+ (NSString *)rd_safeString:(id)obj {
    if (!obj || [obj isKindOfClass:[NSNull class]]) return @"";
    if ([obj isKindOfClass:[NSString class]]) return (NSString *)obj;
    if ([obj isKindOfClass:[NSNumber class]]) return [(NSNumber *)obj stringValue];

    if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
        id sorted = [NSString rd_normalizeJSONObject:obj];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sorted options:0 error:&error];
        if (!error && jsonData) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            return jsonString ?: @"";
        }
    }

    return [NSString stringWithFormat:@"%@", obj];
}

+ (id)rd_normalizeJSONObject:(id)obj {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)obj;
        NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSMutableDictionary *sortedDict = [NSMutableDictionary dictionary];
        for (NSString *key in sortedKeys) {
            sortedDict[key] = [NSString rd_normalizeJSONObject:dict[key]];
        }
        return [sortedDict copy];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)obj;
        NSMutableArray *processedArray = [NSMutableArray array];
        for (id item in array) {
            [processedArray addObject:[NSString rd_normalizeJSONObject:item]];
        }
        return [processedArray copy];
    } else {
        return obj;
    }
}

+ (NSString *)rd_md5:(NSString *)input {
    if (!input) input = @"";
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

+ (NSString *)rd_hmacSHA256:(NSString *)data key:(NSString *)key {
    if (!data) data = @"";
    if (!key) key = @"";

    const char *plainData = [data UTF8String];
    const char *secretKeyData = [key UTF8String];

    unsigned char hmacResult[CC_SHA256_DIGEST_LENGTH];
    memset(hmacResult, 0, sizeof(hmacResult));

    CCHmac(kCCHmacAlgSHA256,
           secretKeyData, strlen(secretKeyData),
           plainData, strlen(plainData),
           hmacResult);

    NSMutableString *hexResult = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hexResult appendFormat:@"%02X", hmacResult[i]];
    }

    if (hexResult.length >= 32) {
        return [hexResult substringToIndex:32];
    }
    return hexResult;
}

+ (NSString *)rd_randomNonce16 {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        u_int32_t idx = arc4random_uniform((u_int32_t)[letters length]);
        unichar c = [letters characterAtIndex:idx];
        [s appendFormat:@"%C", c];
    }
    return s;
}

+ (NSString *)rd_currentTimeMillisString {
    long long ms = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    return [NSString stringWithFormat:@"%lld", ms];
}

@end
