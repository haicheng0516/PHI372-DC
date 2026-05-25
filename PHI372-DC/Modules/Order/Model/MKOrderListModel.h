//
//  MKOrderListModel.h
//  PHI372-DC — /app/v3/order/list 单条订单
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKOrderListModel : NSObject

/// 接口字段 (对齐 259 OrderModel)
@property (nonatomic, copy)   NSString  *orderId;
@property (nonatomic, copy)   NSString  *productId;
@property (nonatomic, copy)   NSString  *productName;
@property (nonatomic, copy)   NSString  *loanAmount;
@property (nonatomic, assign) NSInteger  orderStatus;
@property (nonatomic, copy)   NSString  *applyDate;
@property (nonatomic, copy, nullable) NSString *loanDate;
@property (nonatomic, copy, nullable) NSString *dueDate;
@property (nonatomic, copy, nullable) NSString *repayDate;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
