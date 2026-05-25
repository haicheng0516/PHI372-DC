//
//  MKLoanProductModel.h
//  PHI372-DC
//
//  Loan details 页展示层 Model. 由后端 termV3 response 通过工厂方法生成.
//  字段命名对齐 259 接口 (termDetailList 子字段).
//

#import <Foundation/Foundation.h>
@class MKProductTermDataModel;
@class MKAmountDetailModel;
@class MKTermDetailModel;

NS_ASSUME_NONNULL_BEGIN

@interface MKLoanProductModel : NSObject

// ---- 产品基本 ----
@property (nonatomic, copy, nullable) NSString *productName;
@property (nonatomic, copy, nullable) NSString *productLogo;
@property (nonatomic, copy) NSString *displayAmount;             // "₱ 50,000"
@property (nonatomic, copy) NSString *termText;                  // "180 Days"
@property (nonatomic, copy) NSString *amountSubLabel;            // multi: "Please select loan amount manually" / single: "loan amount"

// ---- 模式 ----
@property (nonatomic, assign) BOOL isMultiAmount;
@property (nonatomic, assign) BOOL isMultiTerm;   // 当前 amountDetail.termDetailList.count > 1

// ---- 银行卡 ----
@property (nonatomic, copy, nullable) NSString *bankAccount;     // nil = 未选

// ---- 5 行明细 (来自当前选中 termDetail) ----
@property (nonatomic, copy, nullable) NSString *arrivalAmount;
@property (nonatomic, copy, nullable) NSString *interestAmount;
@property (nonatomic, copy, nullable) NSString *feeAmount;
@property (nonatomic, copy, nullable) NSString *borrowingDate;
@property (nonatomic, copy, nullable) NSString *repaymentDate;

#pragma mark - 工厂方法

/// 从接口数据生成展示模型
/// @param data termV3 response.data
/// @param amountDetail 当前选中的金额项 (多金额时调用方决定, 单金额时取唯一项)
/// @param termDetail 当前选中的期限项 (调用方决定)
+ (instancetype)modelFromTermData:(MKProductTermDataModel *)data
                     amountDetail:(MKAmountDetailModel *)amountDetail
                       termDetail:(MKTermDetailModel *)termDetail;

#pragma mark - Mock (开发期 fallback)

+ (instancetype)mockMultiAmount;
+ (instancetype)mockSingleAmount;

@end

NS_ASSUME_NONNULL_END
