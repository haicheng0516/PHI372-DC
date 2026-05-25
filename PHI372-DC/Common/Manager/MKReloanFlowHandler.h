//  MKReloanFlowHandler.h
//  PHI372-DC

#import <Foundation/Foundation.h>
#import "MKSeamlessOrderManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MKReloanFlowHandlerDelegate <NSObject>
@optional
/// 复借弹窗中用户点击申请，已自动启动无感下单
- (void)reloanFlowHandlerDidStartSeamlessOrder:(id)handler;
/// 复借弹窗被用户关闭
- (void)reloanFlowHandlerDidDismiss:(id)handler;
@end

@interface MKReloanFlowHandler : NSObject

@property (nonatomic, weak, nullable) id<MKReloanFlowHandlerDelegate> delegate;
/// 无感下单的代理（传给 MKSeamlessOrderManager）
@property (nonatomic, weak, nullable) id<MKSeamlessOrderManagerDelegate> seamlessOrderDelegate;

/// 当前复借弹窗引用（外部构建弹窗时需赋值，以便 hideReloanTipAlert 正确 dismiss）
/// TODO[reloan]: 待 MKBottomSheetView 等价类型接入后改为具体类型
@property (nonatomic, strong, nullable) id currentReloanAlert;

/// 请求产品状态并显示复借弹窗
- (void)requestProductStateAndShowTipWithProductId:(nullable NSString *)productId;
/// 启动无感下单（用于外部直接调用，如首页自行构建弹窗时）
- (void)startSeamlessOrderWithProductId:(NSString *)productId selectedAmount:(NSString *)selectedAmount;
/// 隐藏当前复借弹窗
- (void)hideReloanTipAlert;
/// 重置状态
- (void)reset;

@end

NS_ASSUME_NONNULL_END
