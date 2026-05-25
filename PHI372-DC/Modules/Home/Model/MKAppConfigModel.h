//
//  MKAppConfigModel.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKAppConfigDynamicParameter : NSObject
@property (nonatomic, copy, nullable) NSString *fjtip;
+ (instancetype)modelWithDictionary:(NSDictionary *)dict;
@end

@interface MKAppConfigModel : NSObject

@property (nonatomic, assign) NSInteger retrieveMobileContact;
@property (nonatomic, assign) NSInteger pushMaxCount;
@property (nonatomic, assign) NSInteger pushPerCount;
@property (nonatomic, strong, nullable) MKAppConfigDynamicParameter *dynamicParameter;
@property (nonatomic, copy, nullable) NSString *policyHref;
@property (nonatomic, copy, nullable) NSString *conditionsHref;
@property (nonatomic, copy, nullable) NSString *agreementHref;
@property (nonatomic, copy, nullable) NSString *appEmail;
@property (nonatomic, copy, nullable) NSString *officialWebsiteUrl;

+ (instancetype)modelWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
