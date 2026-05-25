//
//  MKProductTermModel.h
//  PHI372-DC
//
//  termV3 接口数据模型 (产品期限/金额详情) — 移植自 334 RDProductTermModel
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 还款计划项

@interface MKProductTermItemModel : NSObject
@property (nonatomic, copy, nullable) NSString *applicationDate;
@property (nonatomic, copy, nullable) NSString *expirationDate;
@property (nonatomic, copy, nullable) NSString *repaymentAmount;
@property (nonatomic, copy, nullable) NSString *interestAmountDue;
@property (nonatomic, copy, nullable) NSString *principalAmountDue;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

#pragma mark - 期限详情

@interface MKTermDetailModel : NSObject
@property (nonatomic, assign) NSInteger productTermUnit;    // 1=Days 2=Months
@property (nonatomic, copy, nullable) NSString *feeAmount;          // 服务费
@property (nonatomic, copy, nullable) NSString *taxAmount;
@property (nonatomic, copy, nullable) NSString *arrivalAmount;      // 到账金额
@property (nonatomic, copy, nullable) NSString *interestAmount;     // 利息
@property (nonatomic, copy, nullable) NSString *repaymentAmount;    // 还款金额
@property (nonatomic, copy, nullable) NSString *borrowingDate;      // 申请日期
@property (nonatomic, copy, nullable) NSString *repaymentDate;      // 还款日期
@property (nonatomic, assign) NSInteger loanTerm;                   // 实际期限(提现接口用)
@property (nonatomic, assign) NSInteger showTerm;                   // 显示期限
@property (nonatomic, assign) NSInteger EMITenure;                  // EMI期数
@property (nonatomic, copy, nullable) NSString *EMIAmount;          // EMI金额
@property (nonatomic, strong, nullable) NSArray<MKProductTermItemModel *> *productTermItemList;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
/// 拼接展示文案 (e.g. "180 Days" / "6 Months") — 由 productTermUnit + showTerm 拼装
- (NSString *)displayTermText;
@end

#pragma mark - 金额选项

@interface MKAmountDetailModel : NSObject
@property (nonatomic, copy) NSString *loanAmount;
@property (nonatomic, strong, nullable) NSArray<MKTermDetailModel *> *termDetailList;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
/// 展示金额 (千分符 + ₱ 前缀, e.g. "₱ 50,000")
- (NSString *)displayAmountText;
@end

#pragma mark - termV3 data

@interface MKProductTermDataModel : NSObject
@property (nonatomic, copy, nullable) NSString *productId;
@property (nonatomic, copy, nullable) NSString *productName;
@property (nonatomic, copy, nullable) NSString *productLogo;
@property (nonatomic, assign) NSInteger productTermUnit;    // 1=Days 2=Months
@property (nonatomic, strong, nullable) NSArray<MKAmountDetailModel *> *amountDetailList;
/// 原始接口字典 (后续传给 MKSeamlessOrderManager.termResponseData 需要)
@property (nonatomic, strong, nullable) NSDictionary *originalDictionary;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
/// 是否多金额产品 (amountDetailList.count > 1)
- (BOOL)isMultiAmount;
/// 多金额时按金额从大到小排序后的列表 (单金额时返回原列表)
- (NSArray<MKAmountDetailModel *> *)sortedAmountDetailList;
@end

NS_ASSUME_NONNULL_END
