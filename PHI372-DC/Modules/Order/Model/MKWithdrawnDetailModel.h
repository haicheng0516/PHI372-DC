//
//  MKWithdrawnDetailModel.h
//  PHI372-DC — /app/v3/order/withdrawn/detail 响应 data
//
//  对齐 259 SCWithdrawnDetailModel — 仅当 orderStatus==32 时调
//  data 含 amountDetailList[], 每项含 termDetailList[]; 用户可在详情页重选金额/期限
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKWithdrawnTermItem : NSObject
@property (nonatomic, copy, nullable) NSString *expirationDate;
@property (nonatomic, copy, nullable) NSString *repaymentAmount;
@property (nonatomic, copy, nullable) NSString *interestAmountDue;
@property (nonatomic, copy, nullable) NSString *principalAmountDue;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface MKWithdrawnTermDetail : NSObject
@property (nonatomic, assign) NSInteger productTermUnit;
@property (nonatomic, copy, nullable) NSString *feeAmount;
@property (nonatomic, copy, nullable) NSString *taxAmount;
@property (nonatomic, copy, nullable) NSString *arrivalAmount;
@property (nonatomic, copy, nullable) NSString *interestAmount;
@property (nonatomic, copy, nullable) NSString *repaymentAmount;
@property (nonatomic, copy, nullable) NSString *borrowingDate;
@property (nonatomic, copy, nullable) NSString *repaymentDate;
@property (nonatomic, assign) NSInteger loanTerm;
@property (nonatomic, assign) NSInteger showTerm;
@property (nonatomic, strong, nullable) NSArray<MKWithdrawnTermItem *> *productTermItemList;
@property (nonatomic, copy, nullable) NSString *EMIRepayDate;
@property (nonatomic, copy, nullable) NSString *EMIAmount;
@property (nonatomic, copy, nullable) NSString *EMITenure;
@property (nonatomic, copy, nullable) NSString *EMIs;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
/// 显示文本: "180 Days" / "6 Months"
- (NSString *)displayTermText;
@end

@interface MKWithdrawnAmountDetail : NSObject
@property (nonatomic, copy, nullable) NSString *loanAmount;
@property (nonatomic, strong, nullable) NSArray<MKWithdrawnTermDetail *> *termDetailList;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
/// 显示文本: "₱ 50,000"
- (NSString *)displayAmountText;
@end

@interface MKWithdrawnBankCard : NSObject
@property (nonatomic, copy, nullable) NSString *bindId;
@property (nonatomic, copy, nullable) NSString *accountNo;
@property (nonatomic, copy, nullable) NSString *accountName;
@property (nonatomic, copy, nullable) NSString *bankName;
@property (nonatomic, copy, nullable) NSString *bankCode;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface MKWithdrawnDetailModel : NSObject
@property (nonatomic, copy, nullable) NSString *productId;
@property (nonatomic, copy, nullable) NSString *orderId;
@property (nonatomic, copy, nullable) NSString *productName;
@property (nonatomic, copy, nullable) NSString *productLogo;
@property (nonatomic, assign) NSInteger productTermUnit;
@property (nonatomic, copy, nullable) NSString *productHotline;
@property (nonatomic, strong, nullable) NSArray<MKWithdrawnBankCard *> *bankCardList;
@property (nonatomic, strong, nullable) NSArray<MKWithdrawnAmountDetail *> *amountDetailList;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
