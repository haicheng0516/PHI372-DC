//
//  MKLoginUserInfo.m
//  PHI372-DC
//

#import "MKLoginUserInfo.h"

@implementation MKLoginUserInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _userId = [NSString stringWithFormat:@"%@", dictionary[@"userId"] ?: @""];
        _token = [NSString stringWithFormat:@"%@", dictionary[@"token"] ?: @""];
        _isRegister = [dictionary[@"isRegister"] boolValue];
        _appLink = dictionary[@"appLink"];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"userId"] = self.userId ?: @"";
    dict[@"token"] = self.token ?: @"";
    dict[@"isRegister"] = @(self.isRegister);
    if (self.appLink) {
        dict[@"appLink"] = self.appLink;
    }
    return [dict copy];
}

- (BOOL)isValid {
    return self.userId.length > 0 && self.token.length > 0;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.userId forKey:@"userId"];
    [coder encodeObject:self.token forKey:@"token"];
    [coder encodeBool:self.isRegister forKey:@"isRegister"];
    [coder encodeObject:self.appLink forKey:@"appLink"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _userId = [coder decodeObjectOfClass:[NSString class] forKey:@"userId"] ?: @"";
        _token = [coder decodeObjectOfClass:[NSString class] forKey:@"token"] ?: @"";
        _isRegister = [coder decodeBoolForKey:@"isRegister"];
        _appLink = [coder decodeObjectOfClass:[NSString class] forKey:@"appLink"];
    }
    return self;
}

@end
