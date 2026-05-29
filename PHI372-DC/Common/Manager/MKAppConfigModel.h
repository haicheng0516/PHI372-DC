//
//  MKAppConfigModel.h
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
/// 好评引导开关: "0"-关 / "1"-全部展示 / "2"-仅老客展示(nil/默认按全部展示)
@property (nonatomic, copy, nullable) NSString *feedbackGuidance;
/// 拒量输出 H5 链接。不为空时，4 个触发场景命中后跳此 URL 而非走原流程。
@property (nonatomic, copy, nullable) NSString *rejectH5;

+ (instancetype)modelWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
