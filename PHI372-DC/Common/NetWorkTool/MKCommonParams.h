//
//  MKCommonParams.h
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKCommonParams : NSObject

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *salt;
@property (nonatomic, copy) NSString *secretKey;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *clientVersion;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, assign) NSInteger os;
@property (nonatomic, copy) NSString *clientLanguage;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appDisplayVersion;

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
