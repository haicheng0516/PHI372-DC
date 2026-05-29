//  NSString+MKAmount.m

#import "NSString+MKAmount.h"

@implementation NSString (MKAmount)

- (NSString *)rd_formattedAmount {
    if (self.length == 0) return self;

    // 去除非数字和小数点
    NSString *cleaned = self;
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:cleaned];
    if ([number isEqualToNumber:[NSDecimalNumber notANumber]]) {
        return self;
    }

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.groupingSeparator = @",";
    formatter.maximumFractionDigits = 2;
    NSString *result = [formatter stringFromNumber:number];
    return result ?: self;
}

- (NSString *)rd_formattedPesoAmount {
    return [NSString stringWithFormat:@"₱ %@", [self rd_formattedAmount]];
}

- (NSString *)mk_formattedAmount {
    return [self rd_formattedAmount];
}

- (NSString *)mk_formattedPesoAmount {
    return [self rd_formattedPesoAmount];
}

- (NSString *)mk_formattedRate {
    if (self.length == 0) return @"";
    NSNumberFormatter *rateFormatter = [[NSNumberFormatter alloc] init];
    rateFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    rateFormatter.minimumFractionDigits = 0;
    rateFormatter.maximumFractionDigits = 2;
    rateFormatter.groupingSeparator = @",";
    rateFormatter.usesGroupingSeparator = YES;
    NSNumber *number = [rateFormatter numberFromString:self];
    if (number) {
        return [rateFormatter stringFromNumber:number] ?: self;
    }
    return self;
}

@end
