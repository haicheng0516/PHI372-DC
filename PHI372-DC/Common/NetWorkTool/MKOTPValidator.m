//
//  MKOTPValidator.m
//

#import "MKOTPValidator.h"

@implementation MKOTPValidator

+ (BOOL)validateCode:(NSString *)code {
    if (code.length == 0) return NO;
    NSString *filtered = [self filterCode:code];
    if (filtered.length != 6) return NO;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^\\d{6}$"];
    return [predicate evaluateWithObject:filtered];
}

+ (NSString *)filterCode:(NSString *)code {
    if (code.length == 0) return @"";
    NSCharacterSet *notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[code componentsSeparatedByCharactersInSet:notDigits] componentsJoinedByString:@""];
}

+ (nullable NSString *)validationErrorMessage:(NSString *)code {
    if (code.length == 0) return @"Please enter OTP";
    NSString *filtered = [self filterCode:code];
    if (filtered.length != code.length) return @"OTP should contain only digits";
    if (filtered.length != 6) return @"OTP must be 6 digits";
    return nil;
}

+ (BOOL)shouldChangeText:(NSString *)currentText
                 inRange:(NSRange)range
       replacementString:(NSString *)string {
    if (string.length == 0) return YES;

    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inputSet = [NSCharacterSet characterSetWithCharactersInString:string];
    if (![digits isSupersetOfSet:inputSet]) return NO;

    NSString *newText = [currentText stringByReplacingCharactersInRange:range withString:string];
    return newText.length <= 6;
}

@end
