//
//  MKPhoneValidator.m
//

#import "MKPhoneValidator.h"

@implementation MKPhoneValidator

static NSString * const kPhoneRegexGeneral = @"^0?9\\d{9}$";

+ (BOOL)validatePhoneNumber:(NSString *)phoneNumber {
    if (!phoneNumber || phoneNumber.length == 0) return NO;
    phoneNumber = [phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", kPhoneRegexGeneral];
    return [predicate evaluateWithObject:phoneNumber];
}

+ (NSString *)filterPhoneNumber:(NSString *)phoneNumber {
    if (!phoneNumber || phoneNumber.length == 0) return phoneNumber;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]" options:0 error:nil];
    return [regex stringByReplacingMatchesInString:phoneNumber options:0 range:NSMakeRange(0, phoneNumber.length) withTemplate:@""];
}

+ (NSString *)submitPhoneNumber:(NSString *)phoneNumber {
    NSString *filtered = [self filterPhoneNumber:phoneNumber];
    filtered = [filtered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // 11位09开头 -> 去0
    if (filtered.length == 11 && [filtered hasPrefix:@"09"]) {
        return [filtered substringFromIndex:1];
    }
    return filtered;
}

+ (nullable NSString *)validationErrorMessage:(NSString *)phoneNumber {
    if (!phoneNumber || phoneNumber.length == 0) return @"Please enter your phone number";
    NSString *filtered = [self filterPhoneNumber:phoneNumber];
    if (filtered.length < 10) return @"Phone number is too short";
    if (filtered.length > 11) return @"Phone number is too long";
    if (![filtered hasPrefix:@"9"] && ![filtered hasPrefix:@"09"]) return @"Phone number must start with 9 or 09";
    if ([self validatePhoneNumber:filtered]) return nil;
    return @"Invalid phone number format";
}

+ (NSString *)normalizeFromContact:(NSString *)rawPhone {
    NSString *filtered = [self filterPhoneNumber:rawPhone] ?: @"";
    if ([filtered hasPrefix:@"63"] && filtered.length > 10) {
        filtered = [filtered substringFromIndex:2];
    }
    if ([filtered hasPrefix:@"0"] && filtered.length == 11) {
        filtered = [filtered substringFromIndex:1];
    }
    return filtered;
}

+ (BOOL)shouldChangeText:(NSString *)currentText
                 inRange:(NSRange)range
       replacementString:(NSString *)string
               maxLength:(NSUInteger)maxLength {
    if (string.length == 0) return YES;

    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inputSet = [NSCharacterSet characterSetWithCharactersInString:string];
    if (![digits isSupersetOfSet:inputSet]) return NO;

    NSString *newText = [currentText stringByReplacingCharactersInRange:range withString:string];

    NSUInteger actualMax = maxLength;
    if (newText.length > 0) {
        if ([newText hasPrefix:@"09"]) {
            actualMax = 11;
        } else if ([newText hasPrefix:@"9"]) {
            actualMax = 10;
        } else if ([newText hasPrefix:@"0"] && newText.length <= 2) {
            actualMax = 11;
        }
    }

    return newText.length <= actualMax;
}

@end
