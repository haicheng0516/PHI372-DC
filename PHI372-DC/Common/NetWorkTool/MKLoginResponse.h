//
//  MKLoginResponse.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>
#import "MKLoginUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKLoginResponse : NSObject

@property (nonatomic, strong, nullable) MKLoginUserInfo *data;
@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy) NSString *resultMsg;
@property (nonatomic, assign) long long timestamp;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
