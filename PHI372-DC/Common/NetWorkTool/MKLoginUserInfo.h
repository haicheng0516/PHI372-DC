//
//  MKLoginUserInfo.h
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKLoginUserInfo : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, assign) BOOL isRegister;
@property (nonatomic, copy, nullable) NSString *appLink;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
