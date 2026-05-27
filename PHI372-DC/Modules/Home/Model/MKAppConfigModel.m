//
//  MKAppConfigModel.m
//  PHI372-DC
//

#import "MKAppConfigModel.h"

@implementation MKAppConfigDynamicParameter
+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    MKAppConfigDynamicParameter *m = [[self alloc] init];
    m.fjtip = [dict[@"fjtip"] isKindOfClass:[NSString class]] ? dict[@"fjtip"] : nil;
    return m;
}
@end

@implementation MKAppConfigModel
+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    MKAppConfigModel *m = [[self alloc] init];
    m.retrieveMobileContact = [dict[@"retrieveMobileContact"] integerValue];
    m.pushMaxCount = [dict[@"pushMaxCount"] integerValue] ?: 1000;
    m.pushPerCount = [dict[@"pushPerCount"] integerValue] ?: 100;
    NSDictionary *dyn = dict[@"dynamicParameter"];
    if ([dyn isKindOfClass:[NSDictionary class]]) m.dynamicParameter = [MKAppConfigDynamicParameter modelWithDictionary:dyn];
    m.policyHref = [dict[@"policyHref"] isKindOfClass:[NSString class]] ? dict[@"policyHref"] : nil;
    m.conditionsHref = [dict[@"conditionsHref"] isKindOfClass:[NSString class]] ? dict[@"conditionsHref"] : nil;
    m.agreementHref = [dict[@"agreementHref"] isKindOfClass:[NSString class]] ? dict[@"agreementHref"] : nil;
    m.appEmail = [dict[@"appEmail"] isKindOfClass:[NSString class]] ? dict[@"appEmail"] : nil;
    m.officialWebsiteUrl = [dict[@"officialWebsiteUrl"] isKindOfClass:[NSString class]] ? dict[@"officialWebsiteUrl"] : nil;
    m.feedbackGuidance = [dict[@"feedbackGuidance"] isKindOfClass:[NSString class]] ? dict[@"feedbackGuidance"] : nil;
    return m;
}
@end
