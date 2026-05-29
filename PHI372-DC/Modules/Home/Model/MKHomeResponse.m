//
//  MKHomeResponse.m
//

#import "MKHomeResponse.h"
#import "MKProductInfoModel.h"

@implementation MKHomeDataModel
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _userStatus = [dictionary[@"userStatus"] integerValue];
        _appUserType = [dictionary[@"appUserType"] integerValue];
        _promptCopy = dictionary[@"promptCopy"];
        _hasOrder = [dictionary[@"hasOrder"] integerValue];
        _withdrawalOrderId = dictionary[@"withdrawalOrderId"];
        _withdrawalProductId = dictionary[@"withdrawalProductId"];
        _firstLoanOptionLine = dictionary[@"firstLoanOptionLine"];
    }
    return self;
}
@end

@implementation MKHomeResponse
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        NSDictionary *d = dictionary[@"data"];
        if ([d isKindOfClass:[NSDictionary class]]) _data = [[MKHomeDataModel alloc] initWithDictionary:d];
        _resultCode = [dictionary[@"resultCode"] integerValue];
        _resultMsg = [dictionary[@"resultMsg"] copy] ?: @"";
    }
    return self;
}
- (BOOL)isSuccess { return self.resultCode == 200; }
@end

@implementation MKProductListResponse
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _resultCode = [dictionary[@"resultCode"] integerValue];
        _resultMsg = [dictionary[@"resultMsg"] copy] ?: @"";
        NSDictionary *d = dictionary[@"data"];
        if ([d isKindOfClass:[NSDictionary class]]) {
            NSArray *arr = d[@"productInfoList"];
            if ([arr isKindOfClass:[NSArray class]]) {
                NSMutableArray *list = [NSMutableArray array];
                for (NSDictionary *item in arr) {
                    if ([item isKindOfClass:[NSDictionary class]]) {
                        MKProductInfoModel *m = [[MKProductInfoModel alloc] initWithDictionary:item];
                        if (m) [list addObject:m];
                    }
                }
                _productInfoList = [list copy];
            }
        }
        if (!_productInfoList) _productInfoList = @[];
    }
    return self;
}
- (BOOL)isSuccess { return self.resultCode == 200; }
@end

@implementation MKKYCStatusResponse
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _resultCode = [dictionary[@"resultCode"] integerValue];
        _resultMsg = [dictionary[@"resultMsg"] copy] ?: @"";
        _willExecuteStepNumber = @"";
        NSDictionary *d = dictionary[@"data"];
        if ([d isKindOfClass:[NSDictionary class]]) {
            NSDictionary *echoMap = d[@"echoMap"];
            if ([echoMap isKindOfClass:[NSDictionary class]]) {
                _willExecuteStepNumber = [NSString stringWithFormat:@"%@", echoMap[@"willExecuteStepNumber"] ?: @""];
            }
        }
    }
    return self;
}
- (BOOL)isSuccess { return self.resultCode == 200; }
@end
