//
//  MKKYCInitResponse.m
//

#import "MKKYCInitResponse.h"

@implementation MKKYCInitResponse

- (instancetype)initWithDictionary:(id)dict {
    return [self initWithDictionary:dict listKey:@"kycItemList"];
}

- (instancetype)initWithDictionary:(id)dict listKey:(NSString *)listKey {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        NSDictionary *d = (NSDictionary *)dict;
        _resultCode = [d[@"resultCode"] integerValue];
        _resultMsg = d[@"resultMsg"];
        NSDictionary *data = d[@"data"];
        NSArray *list = nil;
        if ([data isKindOfClass:[NSDictionary class]]) list = data[listKey];
        if (![list isKindOfClass:[NSArray class]]) list = @[];

        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *itemDict in list) {
            MKKYCItemModel *item = [[MKKYCItemModel alloc] initWithDictionary:itemDict];
            if (item) [items addObject:item];
        }
        [items sortUsingComparator:^NSComparisonResult(MKKYCItemModel *a, MKKYCItemModel *b) {
            return a.itemSort - b.itemSort;
        }];
        _kycItemList = [items copy];
    }
    return self;
}

- (BOOL)isSuccess { return self.resultCode == 200; }

@end
