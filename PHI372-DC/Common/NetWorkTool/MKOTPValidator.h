//
//  MKOTPValidator.h
//
//  验证码验证工具类 (6位纯数字)

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKOTPValidator : NSObject

+ (BOOL)validateCode:(NSString *)code;
+ (NSString *)filterCode:(NSString *)code;
+ (nullable NSString *)validationErrorMessage:(NSString *)code;

+ (BOOL)shouldChangeText:(NSString *)currentText
                 inRange:(NSRange)range
       replacementString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
