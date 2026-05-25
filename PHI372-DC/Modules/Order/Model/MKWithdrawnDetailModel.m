//
//  MKWithdrawnDetailModel.m
//

#import "MKWithdrawnDetailModel.h"

static NSString *MKStrFrom(id v) {
    if (!v || v == NSNull.null) return nil;
    return [NSString stringWithFormat:@"%@", v];
}

@implementation MKWithdrawnTermItem
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _expirationDate     = MKStrFrom(d[@"expirationDate"]);
        _repaymentAmount    = MKStrFrom(d[@"repaymentAmount"]);
        _interestAmountDue  = MKStrFrom(d[@"interestAmountDue"]);
        _principalAmountDue = MKStrFrom(d[@"principalAmountDue"]);
    }
    return self;
}
@end

@implementation MKWithdrawnTermDetail
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _productTermUnit = [d[@"productTermUnit"] integerValue];
        _feeAmount       = MKStrFrom(d[@"feeAmount"]);
        _taxAmount       = MKStrFrom(d[@"taxAmount"]);
        _arrivalAmount   = MKStrFrom(d[@"arrivalAmount"]);
        _interestAmount  = MKStrFrom(d[@"interestAmount"]);
        _repaymentAmount = MKStrFrom(d[@"repaymentAmount"]);
        _borrowingDate   = MKStrFrom(d[@"borrowingDate"]);
        _repaymentDate   = MKStrFrom(d[@"repaymentDate"]);
        _loanTerm        = [d[@"loanTerm"] integerValue];
        _showTerm        = [d[@"showTerm"] integerValue];
        _EMIRepayDate    = MKStrFrom(d[@"EMIRepayDate"]);
        _EMIAmount       = MKStrFrom(d[@"EMIAmount"]);
        _EMITenure       = MKStrFrom(d[@"EMITenure"]);
        _EMIs            = MKStrFrom(d[@"EMIs"]);
        NSMutableArray *items = [NSMutableArray array];
        id list = d[@"productTermItemList"];
        if ([list isKindOfClass:[NSArray class]]) {
            for (id it in list) {
                if ([it isKindOfClass:[NSDictionary class]]) {
                    [items addObject:[[MKWithdrawnTermItem alloc] initWithDictionary:it]];
                }
            }
        }
        _productTermItemList = items.count > 0 ? items : nil;
    }
    return self;
}
- (NSString *)displayTermText {
    NSInteger show = _showTerm > 0 ? _showTerm : _loanTerm;
    NSString *unit = (_productTermUnit == 2) ? @"Months" : @"Days";
    return [NSString stringWithFormat:@"%ld %@", (long)show, unit];
}
@end

@implementation MKWithdrawnAmountDetail
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _loanAmount = MKStrFrom(d[@"loanAmount"]);
        NSMutableArray *terms = [NSMutableArray array];
        id list = d[@"termDetailList"];
        if ([list isKindOfClass:[NSArray class]]) {
            for (id it in list) {
                if ([it isKindOfClass:[NSDictionary class]]) {
                    [terms addObject:[[MKWithdrawnTermDetail alloc] initWithDictionary:it]];
                }
            }
        }
        _termDetailList = terms.count > 0 ? terms : nil;
    }
    return self;
}
- (NSString *)displayAmountText {
    double v = [_loanAmount doubleValue];
    NSNumberFormatter *f = [NSNumberFormatter new];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    f.maximumFractionDigits = 0;
    NSString *s = [f stringFromNumber:@(v)] ?: _loanAmount;
    return [NSString stringWithFormat:@"₱ %@", s];
}
@end

@implementation MKWithdrawnBankCard
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _bindId      = MKStrFrom(d[@"bindId"]);
        _accountNo   = MKStrFrom(d[@"accountNo"]);
        _accountName = MKStrFrom(d[@"accountName"]);
        _bankName    = MKStrFrom(d[@"bankName"]);
        _bankCode    = MKStrFrom(d[@"bankCode"]);
    }
    return self;
}
@end

@implementation MKWithdrawnDetailModel
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _productId       = MKStrFrom(d[@"productId"]);
        _orderId         = MKStrFrom(d[@"orderId"]);
        _productName     = MKStrFrom(d[@"productName"]);
        _productLogo     = MKStrFrom(d[@"productLogo"]);
        _productTermUnit = [d[@"productTermUnit"] integerValue];
        _productHotline  = MKStrFrom(d[@"productHotline"]);

        NSMutableArray *cards = [NSMutableArray array];
        id cl = d[@"bankCardList"];
        if ([cl isKindOfClass:[NSArray class]]) {
            for (id it in cl) {
                if ([it isKindOfClass:[NSDictionary class]]) {
                    [cards addObject:[[MKWithdrawnBankCard alloc] initWithDictionary:it]];
                }
            }
        }
        _bankCardList = cards.count > 0 ? cards : nil;

        NSMutableArray *amounts = [NSMutableArray array];
        id al = d[@"amountDetailList"];
        if ([al isKindOfClass:[NSArray class]]) {
            for (id it in al) {
                if ([it isKindOfClass:[NSDictionary class]]) {
                    [amounts addObject:[[MKWithdrawnAmountDetail alloc] initWithDictionary:it]];
                }
            }
        }
        _amountDetailList = amounts.count > 0 ? amounts : nil;
    }
    return self;
}
@end
