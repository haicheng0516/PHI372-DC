//  MKLoanProductModel.m

#import "MKLoanProductModel.h"
#import "MKProductTermModel.h"
#import "NSString+MKAmount.h"

@implementation MKLoanProductModel

+ (instancetype)modelFromTermData:(MKProductTermDataModel *)data
                     amountDetail:(MKAmountDetailModel *)amountDetail
                       termDetail:(MKTermDetailModel *)termDetail {
    MKLoanProductModel *m = [[MKLoanProductModel alloc] init];
    m.productName = data.productName;
    m.productLogo = data.productLogo;
    m.isMultiAmount = data.isMultiAmount;
    m.isMultiTerm = amountDetail.termDetailList.count > 1;
    m.displayAmount = amountDetail ? [amountDetail displayAmountText] : @"₱ --";
    m.termText = termDetail ? [termDetail displayTermText] : @"-- Days";
    m.amountSubLabel = data.isMultiAmount ? @"Please select loan amount manually" : @"loan amount";

    m.arrivalAmount  = [termDetail.arrivalAmount  mk_formattedAmount];   // 千分位
    m.interestAmount = [termDetail.interestAmount mk_formattedAmount];   // 千分位
    // service fee: 字符串去逗号 → integer 截掉小数 (e.g. "4400.00" → "4400")
    NSString *raw = termDetail.feeAmount ?: @"0";
    NSInteger fee = [[raw stringByReplacingOccurrencesOfString:@"," withString:@""] integerValue];
    m.feeAmount      = [NSString stringWithFormat:@"%ld", (long)fee];
    m.borrowingDate  = termDetail.borrowingDate;
    m.repaymentDate  = termDetail.repaymentDate;
    return m;
}

+ (instancetype)mockMultiAmount {
    MKLoanProductModel *m = [[MKLoanProductModel alloc] init];
    m.productName = @"APPname";
    m.displayAmount = @"₱ 50,000";
    m.termText = @"180 Days";
    m.amountSubLabel = @"Please select loan amount manually";
    m.isMultiAmount = YES;
    m.arrivalAmount = @"9,900";
    m.interestAmount = @"1,440";
    m.feeAmount = @"100";
    m.borrowingDate = @"Feb 18, 2026";
    m.repaymentDate = @"Aug 18, 2026";
    return m;
}

+ (instancetype)mockSingleAmount {
    MKLoanProductModel *m = [self mockMultiAmount];
    m.amountSubLabel = @"loan amount";
    m.isMultiAmount = NO;
    return m;
}

@end
