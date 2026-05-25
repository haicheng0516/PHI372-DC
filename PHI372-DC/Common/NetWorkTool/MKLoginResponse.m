//
//  MKLoginResponse.m
//  PHI372-DC
//

#import "MKLoginResponse.h"

@implementation MKLoginResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    self = [super init];
    if (self) {
        NSDictionary *dataDict = dictionary[@"data"];
        if (dataDict && [dataDict isKindOfClass:[NSDictionary class]]) {
            _data = [[MKLoginUserInfo alloc] initWithDictionary:dataDict];
        }

        _resultCode = [dictionary[@"resultCode"] integerValue];
        _resultMsg = [dictionary[@"resultMsg"] copy] ?: @"";
        _timestamp = [dictionary[@"timestamp"] longLongValue];
    }
    return self;
}

- (BOOL)isSuccess {
    return self.resultCode == 200 && self.data != nil && [self.data isValid];
}

@end
