//
//  MKProductTermModel.m
//  PHI372-DC
//

#import "MKProductTermModel.h"

#pragma mark - MKProductTermItemModel

@implementation MKProductTermItemModel
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _applicationDate = [self strVal:dict[@"applicationDate"]];
        _expirationDate = [self strVal:dict[@"expirationDate"] ?: dict[@"dueDate"]];
        _repaymentAmount = [self strVal:dict[@"repaymentAmount"]];
        _interestAmountDue = [self strVal:dict[@"interestAmountDue"]];
        _principalAmountDue = [self strVal:dict[@"principalAmountDue"]];
    }
    return self;
}
- (NSString *)strVal:(id)val { return val ? [NSString stringWithFormat:@"%@", val] : nil; }
@end

#pragma mark - MKTermDetailModel

@implementation MKTermDetailModel
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _productTermUnit = [dict[@"productTermUnit"] integerValue];
        _feeAmount = [self strVal:dict[@"feeAmount"]];
        _taxAmount = [self strVal:dict[@"taxAmount"]];
        _arrivalAmount = [self strVal:dict[@"arrivalAmount"]];
        _interestAmount = [self strVal:dict[@"interestAmount"]];
        _repaymentAmount = [self strVal:dict[@"repaymentAmount"]];
        _borrowingDate = [self strVal:dict[@"borrowingDate"]];
        _repaymentDate = [self strVal:dict[@"repaymentDate"]];
        _loanTerm = [dict[@"loanTerm"] integerValue];
        _showTerm = [dict[@"showTerm"] integerValue];
        _EMITenure = [dict[@"EMITenure"] integerValue];
        _EMIAmount = [self strVal:dict[@"EMIAmount"]];

        NSArray *itemArr = dict[@"productTermItemList"];
        if ([itemArr isKindOfClass:[NSArray class]]) {
            NSMutableArray *items = [NSMutableArray array];
            for (NSDictionary *d in itemArr) {
                MKProductTermItemModel *item = [[MKProductTermItemModel alloc] initWithDictionary:d];
                if (item) [items addObject:item];
            }
            _productTermItemList = [items copy];
        }
    }
    return self;
}
- (NSString *)strVal:(id)val { return val ? [NSString stringWithFormat:@"%@", val] : nil; }

- (NSString *)displayTermText {
    NSString *unit = (self.productTermUnit == 2) ? @"Months" : @"Days";
    return [NSString stringWithFormat:@"%ld %@", (long)self.showTerm, unit];
}
@end

#pragma mark - MKAmountDetailModel

@implementation MKAmountDetailModel
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _loanAmount = [NSString stringWithFormat:@"%@", dict[@"loanAmount"] ?: @""];

        NSArray *termArr = dict[@"termDetailList"];
        if ([termArr isKindOfClass:[NSArray class]]) {
            NSMutableArray *terms = [NSMutableArray array];
            for (NSDictionary *d in termArr) {
                MKTermDetailModel *term = [[MKTermDetailModel alloc] initWithDictionary:d];
                if (term) [terms addObject:term];
            }
            _termDetailList = [terms copy];
        }
    }
    return self;
}

- (NSString *)displayAmountText {
    double value = self.loanAmount.doubleValue;
    if (value <= 0) {
        return self.loanAmount.length > 0 ? [@"₱ " stringByAppendingString:self.loanAmount] : @"₱ --";
    }
    NSNumberFormatter *fmt = [NSNumberFormatter new];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    fmt.maximumFractionDigits = 0;
    NSString *formatted = [fmt stringFromNumber:@(value)] ?: self.loanAmount;
    return [NSString stringWithFormat:@"₱ %@", formatted];
}
@end

#pragma mark - MKProductTermDataModel

@implementation MKProductTermDataModel
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _originalDictionary = [dict copy];
        _productId = [NSString stringWithFormat:@"%@", dict[@"productId"] ?: @""];
        _productName = [NSString stringWithFormat:@"%@", dict[@"productName"] ?: @""];
        _productLogo = [NSString stringWithFormat:@"%@", dict[@"productLogo"] ?: @""];
        _productTermUnit = [dict[@"productTermUnit"] integerValue];

        NSArray *amountArr = dict[@"amountDetailList"];
        if ([amountArr isKindOfClass:[NSArray class]]) {
            NSMutableArray *amounts = [NSMutableArray array];
            for (NSDictionary *d in amountArr) {
                MKAmountDetailModel *amount = [[MKAmountDetailModel alloc] initWithDictionary:d];
                if (amount) [amounts addObject:amount];
            }
            _amountDetailList = [amounts copy];
        }
    }
    return self;
}

- (BOOL)isMultiAmount {
    return self.amountDetailList.count > 1;
}

- (NSArray<MKAmountDetailModel *> *)sortedAmountDetailList {
    if (!self.isMultiAmount) return self.amountDetailList ?: @[];
    // 从大到小 (照搬 259 ProductApplicationController:294-303)
    return [self.amountDetailList sortedArrayUsingComparator:^NSComparisonResult(MKAmountDetailModel *a, MKAmountDetailModel *b) {
        double va = a.loanAmount.doubleValue;
        double vb = b.loanAmount.doubleValue;
        if (va < vb) return NSOrderedDescending;
        if (va > vb) return NSOrderedAscending;
        return NSOrderedSame;
    }];
}
@end
