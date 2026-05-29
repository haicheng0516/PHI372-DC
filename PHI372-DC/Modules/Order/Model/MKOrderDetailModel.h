//  MKOrderDetailModel.h
//  /app/v3/order/detail 响应 data
//  仅保留详情页用到的字段; 其他状态/扩展字段后续补

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - product 子段

@interface MKOrderDetailProduct : NSObject
@property (nonatomic, copy, nullable) NSString *productId;
@property (nonatomic, copy, nullable) NSString *productLogo;
@property (nonatomic, copy, nullable) NSString *productName;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

#pragma mark - bankCard 子段

@interface MKOrderDetailBankCard : NSObject
@property (nonatomic, copy, nullable) NSString *accountNo;     // 已脱敏 (e.g. 4523 **** 8451 5238)
@property (nonatomic, copy, nullable) NSString *accountName;
@property (nonatomic, assign) NSInteger bankCode;
@property (nonatomic, copy, nullable) NSString *bankName;
@property (nonatomic, assign) NSInteger bindId;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

#pragma mark - orderDetail 子段 (主要字段)

@interface MKOrderDetailInfo : NSObject
@property (nonatomic, copy, nullable) NSString *orderId;
@property (nonatomic, assign) NSInteger orderStatus;
@property (nonatomic, copy, nullable) NSString *loanAmount;            // 借款金额
@property (nonatomic, copy, nullable) NSString *applyDate;             // 申请日期
@property (nonatomic, copy, nullable) NSString *dueDate;               // 到期日期
@property (nonatomic, copy, nullable) NSString *payoutDate;            // 放款日期
@property (nonatomic, copy, nullable) NSString *repaymentDate;         // 结清日期
@property (nonatomic, assign) NSInteger loanTerm;                       // 借款期限
@property (nonatomic, assign) NSInteger loanTermUnit;                   // 1=天 2=月
@property (nonatomic, assign) NSInteger showTerm;                       // 展示期限值
@property (nonatomic, copy, nullable) NSString *receiptAmount;          // 到账金额 (Amount received)
@property (nonatomic, copy, nullable) NSString *interestAmount;         // Interest
@property (nonatomic, copy, nullable) NSString *feeAmount;              // Service fee
@property (nonatomic, copy, nullable) NSString *taxAmount;
@property (nonatomic, copy, nullable) NSString *shouldRepaymentAmount;  // 应还
@property (nonatomic, copy, nullable) NSString *alreadyRepaymentAmount; // 已还
@property (nonatomic, copy, nullable) NSString *totalRepaymentAmount;   // Total repayment
@property (nonatomic, copy, nullable) NSString *reductionAmount;        // Amount of deduction
@property (nonatomic, copy, nullable) NSString *penaltyAmount;          // 罚金
@property (nonatomic, copy, nullable) NSString *dueExtensionFeeAmount;  // Deferment charge
@property (nonatomic, copy, nullable) NSString *EMIAmount;
@property (nonatomic, assign) NSInteger EMITenure;
@property (nonatomic, assign) NSInteger ifExtension;
@property (nonatomic, assign) NSInteger extensionTimes;
@property (nonatomic, assign) NSInteger penaltyDays;
/// 还款计划 productTermItemList — 原始字典数组, 让 RepaymentPlan 弹窗自取
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *productTermItemList;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

#pragma mark - 顶层

@interface MKOrderDetailModel : NSObject
@property (nonatomic, strong, nullable) MKOrderDetailProduct  *product;
@property (nonatomic, strong, nullable) MKOrderDetailBankCard *bankCard;
@property (nonatomic, strong, nullable) MKOrderDetailInfo     *orderDetail;
@property (nonatomic, assign) NSInteger  isWillingRepay;  // 1=是, 2=否
@property (nonatomic, copy, nullable) NSString *message;  // 顶部描述
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
