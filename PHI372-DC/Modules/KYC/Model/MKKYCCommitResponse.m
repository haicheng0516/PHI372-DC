//
//  MKKYCCommitResponse.m
//

#import "MKKYCCommitResponse.h"

@implementation MKKYCCommitResponse

- (instancetype)initWithDictionary:(id)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        NSDictionary *d = (NSDictionary *)dict;
        _resultCode = [d[@"resultCode"] integerValue];
        _resultMsg = d[@"resultMsg"];
    }
    return self;
}

- (BOOL)isSuccess { return self.resultCode == 200; }

@end
