//
//  MKProductStateDetailModel.m
//  PHI372-DC — 照搬 334 RDProductStateDetailModel
//

#import "MKProductStateDetailModel.h"

@implementation MKProductStateDetailModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _loanAmount = [dictionary[@"loanAmount"] isKindOfClass:[NSString class]] ? dictionary[@"loanAmount"] : @"";
        _productLogo = [dictionary[@"productLogo"] isKindOfClass:[NSString class]] ? dictionary[@"productLogo"] : @"";
        _productName = [dictionary[@"productName"] isKindOfClass:[NSString class]] ? dictionary[@"productName"] : @"";
        _userType = [dictionary[@"userType"] isKindOfClass:[NSNumber class]] ? [dictionary[@"userType"] integerValue] : 0;
        _productId = [dictionary[@"productId"] isKindOfClass:[NSString class]] ? dictionary[@"productId"] : @"";
    }
    return self;
}

@end
