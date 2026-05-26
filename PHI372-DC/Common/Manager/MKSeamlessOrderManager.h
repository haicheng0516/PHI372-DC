//  MKSeamlessOrderManager.h
//  PHI372-DC
//  流程: 加载配置 → 定位权限 → 提交订单 → 设备上传 → 通讯录上传 → ready

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKSeamlessOrderState) {
    MKSeamlessOrderStateIdle = 0,
    MKSeamlessOrderStateLoadingConfig,
    MKSeamlessOrderStateCheckingLocation,
    MKSeamlessOrderStateGettingLocation,
    MKSeamlessOrderStateSubmittingOrder,
    MKSeamlessOrderStateUploadingDevice,
    MKSeamlessOrderStateCheckingContacts,
    MKSeamlessOrderStateUploadingContacts,
    MKSeamlessOrderStateCompleting,
    MKSeamlessOrderStateSuccess,
    MKSeamlessOrderStateFailed
};

@interface MKSeamlessOrderParams : NSObject
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *selectedAmount;
/// termV3 接口原始响应数据
@property (nonatomic, strong) NSDictionary *termResponseData;
/// 首单场景: 用户选中的期限 (showTerm 数值, e.g. 7 / 180). 0 时 fallback 取 first
@property (nonatomic, assign) NSInteger selectedShowTerm;
/// 首单场景: 用户选中的银行卡 bankCardBindId. 0 时不传 (复借自动复用绑定卡)
@property (nonatomic, assign) NSInteger bankCardBindId;
@end

@protocol MKSeamlessOrderManagerDelegate <NSObject>
@optional
- (void)seamlessOrderManager:(id)manager didChangeState:(MKSeamlessOrderState)state;
- (void)seamlessOrderManager:(id)manager didSubmitOrderSuccess:(NSString *)orderId;
- (void)seamlessOrderManager:(id)manager didCompleteWithOrderId:(NSString *)orderId;
- (void)seamlessOrderManager:(id)manager didFailWithError:(NSError *)error;
- (void)seamlessOrderManager:(id)manager shouldShowMessage:(NSString *)message;
- (void)seamlessOrderManager:(id)manager didUpdateContactUploadProgress:(NSInteger)progress;
/// 即将弹出系统定位权限弹窗
- (void)seamlessOrderManagerWillShowSystemLocationPermissionAlert:(id)manager;
/// 用户取消了整个流程
- (void)seamlessOrderManagerDidCancel:(id)manager;
/// 用户取消了定位权限
- (void)seamlessOrderManagerDidCancelLocationPermission:(id)manager;
/// 用户取消了通讯录权限
- (void)seamlessOrderManagerDidCancelContactsPermission:(id)manager;
@end

@interface MKSeamlessOrderManager : NSObject

@property (nonatomic, weak, nullable) id<MKSeamlessOrderManagerDelegate> delegate;
@property (nonatomic, assign, readonly) MKSeamlessOrderState currentState;
@property (nonatomic, copy, readonly, nullable) NSString *currentOrderId;
@property (nonatomic, assign, readonly) BOOL isProcessing;

+ (instancetype)sharedManager;
- (BOOL)startSeamlessOrderWithParams:(MKSeamlessOrderParams *)params;

/// 数据抓取专用入口: 不走下单, 复用 loadConfig → location → device → contacts → ready 流程.
/// 用于订单详情页 status 10/20 (待抓取) "Submit Information" 按钮.
- (BOOL)startDataCaptureOnlyWithOrderId:(NSString *)orderId;

- (void)cancel;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
