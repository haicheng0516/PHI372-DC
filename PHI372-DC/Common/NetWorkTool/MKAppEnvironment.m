//
//  MKAppEnvironment.m
//

#import "MKAppEnvironment.h"

@implementation MKAppEnvironment

+ (NSString *)stringForInfoKey:(NSString *)key {
    id v = [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
    return [v isKindOfClass:[NSString class]] ? (NSString *)v : @"";
}

+ (NSString *)appId      { return [self stringForInfoKey:@"MKAppID"]; }
+ (NSString *)salt       { return [self stringForInfoKey:@"MKSalt"]; }
+ (NSString *)baseURL    { return [self stringForInfoKey:@"MKBaseURL"]; }
+ (NSString *)merchantId { return [self stringForInfoKey:@"MKMerchantID"]; }

@end
