//  MKDeviceTool.h
//  PHI372-DC

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKDeviceTool : NSObject

/// 采集全部设备信息（40+ 字段），附带 orderId
+ (NSDictionary *)collectDeviceInfoWithOrderId:(NSString *)orderId;

/// 采集通讯录，按批次分组返回二维数组
/// @param maxCount 最大总条数
/// @param perCount 每批条数
+ (NSArray<NSArray<NSDictionary *> *> *)collectContactsWithMaxCount:(NSInteger)maxCount
                                                           perCount:(NSInteger)perCount;

@end

NS_ASSUME_NONNULL_END
