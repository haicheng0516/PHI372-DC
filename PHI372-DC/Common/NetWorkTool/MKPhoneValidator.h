//
//  MKPhoneValidator.h
//
//  菲律宾手机号验证工具类
//  规则: 9开头10位 或 09开头11位

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKPhoneValidator : NSObject

+ (BOOL)validatePhoneNumber:(NSString *)phoneNumber;
+ (NSString *)filterPhoneNumber:(NSString *)phoneNumber;
+ (NSString *)submitPhoneNumber:(NSString *)phoneNumber;
+ (nullable NSString *)validationErrorMessage:(NSString *)phoneNumber;

/// 通讯录原始电话归一化: 过滤非数字 + 去前导 63 + 去前导 0 → 10 位 9XXXXXXXXX
+ (NSString *)normalizeFromContact:(NSString *)rawPhone;

+ (BOOL)shouldChangeText:(NSString *)currentText
                 inRange:(NSRange)range
       replacementString:(NSString *)string
               maxLength:(NSUInteger)maxLength;

@end

NS_ASSUME_NONNULL_END
