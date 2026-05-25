//
//  MKAppVersionResponse.m
//  PHI372-DC
//

#import "MKAppVersionResponse.h"

@implementation MKAppVersionResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _resultCode = [dictionary[@"resultCode"] integerValue];
        _resultMsg = [dictionary[@"resultMsg"] copy] ?: @"";
        NSDictionary *data = dictionary[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            _latestVersion = [data[@"latestVersion"] isKindOfClass:[NSString class]] ? data[@"latestVersion"] : @"";
            _latestVersionContent = [data[@"latestVersionContent"] isKindOfClass:[NSString class]] ? data[@"latestVersionContent"] : @"";
            _latestVersionUrl = [data[@"latestVersionUrl"] isKindOfClass:[NSString class]] ? data[@"latestVersionUrl"] : @"";
            _latestForceVersion = [data[@"latestForceVersion"] isKindOfClass:[NSString class]] ? data[@"latestForceVersion"] : @"";
            _latestForceVersionContent = [data[@"latestForceVersionContent"] isKindOfClass:[NSString class]] ? data[@"latestForceVersionContent"] : @"";
            _latestForceVersionUrl = [data[@"latestForceVersionUrl"] isKindOfClass:[NSString class]] ? data[@"latestForceVersionUrl"] : @"";
        }
    }
    return self;
}

- (BOOL)isSuccess { return self.resultCode == 200; }

@end
