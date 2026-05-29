//
//  MKAppEnvironment.h
//
//  项目专属配置统一读取入口。所有差异化值(appId/salt/baseURL/merchantId)
//  都走 Info.plist, 每个项目只改 Info.plist 4 个键, 源码不动。
//
//  新增配置项时:
//    1. Info.plist 加键, 命名前缀 MK
//    2. 这里加 + 类方法读它
//    3. 用的地方走 [MKAppEnvironment xxx], 禁止散落 [bundle objectForInfoDictionaryKey:]
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKAppEnvironment : NSObject

/// 接口签名用的 appId, Info.plist 键 `MKAppID`。
+ (NSString *)appId;

/// HMAC 盐, Info.plist 键 `MKSalt`。
+ (NSString *)salt;

/// 接口根域, Info.plist 键 `MKBaseURL`。
+ (NSString *)baseURL;

/// app/config 接口的商户号, Info.plist 键 `MKMerchantID`。
+ (NSString *)merchantId;

@end

NS_ASSUME_NONNULL_END
