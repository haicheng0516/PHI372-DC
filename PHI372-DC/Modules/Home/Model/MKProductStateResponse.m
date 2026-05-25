//
//  MKProductStateResponse.m
//  PHI372-DC — 照搬 334 RDProductStateResponse
//

#import "MKProductStateResponse.h"

@implementation MKProductStateDataModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        id listObj = dictionary[@"amountDetailList"];
        if ([listObj isKindOfClass:[NSArray class]]) {
            NSMutableArray<MKProductStateDetailModel *> *arr = [NSMutableArray array];
            for (NSDictionary *item in (NSArray *)listObj) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    MKProductStateDetailModel *m = [[MKProductStateDetailModel alloc] initWithDictionary:item];
                    if (m) [arr addObject:m];
                }
            }
            _amountDetailList = [arr copy];
        } else if ([listObj isKindOfClass:[NSDictionary class]]) {
            MKProductStateDetailModel *m = [[MKProductStateDetailModel alloc] initWithDictionary:(NSDictionary *)listObj];
            _amountDetailList = m ? @[m] : @[];
        } else {
            _amountDetailList = @[];
        }
    }
    return self;
}

@end

@implementation MKProductStateResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _resultCode = [dictionary[@"resultCode"] integerValue];
        _resultMsg = [dictionary[@"resultMsg"] copy] ?: @"";
        NSDictionary *dataDict = dictionary[@"data"];
        if ([dataDict isKindOfClass:[NSDictionary class]]) {
            _data = [[MKProductStateDataModel alloc] initWithDictionary:dataDict];
        }
    }
    return self;
}

- (BOOL)isSuccess {
    return self.resultCode == 200;
}

@end
