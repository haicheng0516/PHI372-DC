//  MKReloanFlowHandler.h
//  PHI372-DC

#import <Foundation/Foundation.h>
#import "MKSeamlessOrderManager.h"
#import "MKBottomSheetView.h"

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

/// 当前复借弹窗引用 (供 hideReloanTipAlert dismiss)
@property (nonatomic, strong, nullable) MKBottomSheetView *currentReloanAlert;

/// 请求产品状态并显示复借弹窗 (用于订单详情/商品申请页 — Home 走自己的 inline 流程)
/// @param productId  传给 /app/v3/product/state 的 productId
/// @param sheetType  弹窗类型 (MKBottomSheetTypeOrderReloan / MKBottomSheetTypeProductReloan)
- (void)requestProductStateAndShowTipWithProductId:(nullable NSString *)productId
                                         sheetType:(MKBottomSheetType)sheetType;

/// 启动无感下单 (供外部直接调用, 如首页自行构建弹窗时)
- (void)startSeamlessOrderWithProductId:(NSString *)productId selectedAmount:(NSString *)selectedAmount;
/// 隐藏当前复借弹窗
- (void)hideReloanTipAlert;
/// 重置状态
- (void)reset;

@end

NS_ASSUME_NONNULL_END
