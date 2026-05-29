//
//  MKProductInfoModel.m
//

#import "MKProductInfoModel.h"

@implementation MKProductInfoModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _productId = [NSString stringWithFormat:@"%@", dictionary[@"productId"] ?: @""];
        _productName = [NSString stringWithFormat:@"%@", dictionary[@"productName"] ?: @""];
        _productLogo = [NSString stringWithFormat:@"%@", dictionary[@"productLogo"] ?: @""];
        _productLabel = [NSString stringWithFormat:@"%@", dictionary[@"productLabel"] ?: @""];
        _lowestLoanInterestRate = dictionary[@"lowestLoanInterestRate"] ? [NSString stringWithFormat:@"%@", dictionary[@"lowestLoanInterestRate"]] : nil;
        _productApplicantsNumber = dictionary[@"productApplicantsNumber"] ? [NSString stringWithFormat:@"%@", dictionary[@"productApplicantsNumber"]] : nil;
        _lowAmount = [NSString stringWithFormat:@"%@", dictionary[@"lowAmount"] ?: @""];
        _highAmount = [NSString stringWithFormat:@"%@", dictionary[@"highAmount"] ?: @""];
        _highestTerm = [NSString stringWithFormat:@"%@", dictionary[@"highestTerm"] ?: @""];
    }
    return self;
}

@end
