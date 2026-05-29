//
//  MKEventTrackingService.m
//  PHI372-DC
//

#import "MKEventTrackingService.h"
#import "MKEncryptManager.h"
#import "MKNetworkManager.h"

@implementation MKEventTrackingService

+ (void)recordEventWithCode:(NSString *)eventCode {
    if (eventCode.length == 0) {
        NSLog(@"⚠️ [Bury] eventCode 为空，跳过上报");
        return;
    }

    // eventCode 参与签名，同时作为 data 上报
    NSDictionary *payload = @{ @"eventCode": eventCode };
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:payload
                                                                               requestData:payload];

    [[MKNetworkManager sharedManager] post:@"/app/v3/bury/record"
                                    params:body
                                   success:^(id _Nullable responseObject) {
        BOOL ok = ([responseObject isKindOfClass:[NSDictionary class]]
                   && [responseObject[@"resultCode"] integerValue] == 200);
        if (ok) {
            NSLog(@"✅ [Bury] 埋点 %@ 上报成功", eventCode);
        } else {
            NSLog(@"❌ [Bury] 埋点 %@ 上报失败: %@", eventCode,
                  [responseObject isKindOfClass:[NSDictionary class]] ? responseObject[@"resultMsg"] : @"unknown");
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"❌ [Bury] 埋点 %@ 上报网络错误: %@", eventCode, error.localizedDescription);
    }];
}

@end
