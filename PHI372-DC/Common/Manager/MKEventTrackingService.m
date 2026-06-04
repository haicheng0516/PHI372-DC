//
//  MKEventTrackingService.m
//
//  全局埋点上报. 后端按 OpenAPI 校验 data 字段必须完整, 即使无值也要 "NULL" 占位,
//  否则签名校验失败或上报丢. eventCode/eventContent/remark1/remark2/remark3 全部参与签名.
//

#import "MKEventTrackingService.h"
#import "MKEncryptManager.h"
#import "MKNetworkManager.h"

static NSString * const kMKBuriedPointNullValue = @"NULL";

@implementation MKEventTrackingService

+ (void)recordEventWithCode:(NSString *)eventCode {
    if (eventCode.length == 0) {
        NSLog(@"⚠️ [Bury] eventCode 为空，跳过上报");
        return;
    }

    NSDictionary *payload = @{
        @"eventCode":    eventCode,
        @"eventContent": kMKBuriedPointNullValue,
        @"remark1":      kMKBuriedPointNullValue,
        @"remark2":      kMKBuriedPointNullValue,
        @"remark3":      kMKBuriedPointNullValue,
    };
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:payload
                                                                               requestData:payload];

    [[MKNetworkManager sharedManager] post:@"/app/v3/bury/record"
                                    params:body
                                   success:^(id _Nullable responseObject) {
        BOOL ok = NO;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *resultCode = [responseObject objectForKey:@"resultCode"];
            ok = (resultCode != nil && resultCode.integerValue == 200);
        }
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
