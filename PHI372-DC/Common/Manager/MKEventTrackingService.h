//
//  MKEventTrackingService.h
//
//  埋点上报: POST /app/v3/bury/record { eventCode }(eventCode 参与签名)。
//  通知权限场景: 600=授权 / 601=拒绝。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKEventTrackingService : NSObject

/// 上报一个埋点事件。eventCode 如 @"600" / @"601"。
+ (void)recordEventWithCode:(NSString *)eventCode;

@end

NS_ASSUME_NONNULL_END
