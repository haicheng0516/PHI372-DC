//
//  MKAppVersionResponse.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKAppVersionResponse : NSObject

/// 普通更新 (Home 主动调, 客户端版本号比较后弹 NormalUpdate)
@property (nonatomic, copy) NSString *latestVersion;
@property (nonatomic, copy) NSString *latestVersionContent;
@property (nonatomic, copy) NSString *latestVersionUrl;

/// 强制更新 (NetworkManager 拦截 resultCode 2009006 时触发, 字段空表示无强更)
@property (nonatomic, copy) NSString *latestForceVersion;
@property (nonatomic, copy) NSString *latestForceVersionContent;
@property (nonatomic, copy) NSString *latestForceVersionUrl;

@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy) NSString *resultMsg;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
