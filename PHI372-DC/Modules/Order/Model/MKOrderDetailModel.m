//
//  MKOrderDetailModel.m
//

#import "MKOrderDetailModel.h"

static NSString *MKStrFrom(id v) {
    if (!v || v == NSNull.null) return nil;
    return [NSString stringWithFormat:@"%@", v];
}

#pragma mark - product

@implementation MKOrderDetailProduct
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _productId   = MKStrFrom(d[@"productId"]);
        _productLogo = MKStrFrom(d[@"productLogo"]);
        _productName = MKStrFrom(d[@"productName"] ?: d[@"product_name"]);
    }
    return self;
}
@end

#pragma mark - bankCard

@implementation MKOrderDetailBankCard
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _accountNo   = MKStrFrom(d[@"accountNo"] ?: d[@"account_no"] ?: d[@"bankAccount"] ?: d[@"bank_account"]);
        _accountName = MKStrFrom(d[@"accountName"]);
        _bankCode    = [d[@"bankCode"] integerValue];
        _bankName    = MKStrFrom(d[@"bankName"]);
        _bindId      = [d[@"bindId"] integerValue];
    }
    return self;
}
@end

#pragma mark - orderDetail

@implementation MKOrderDetailInfo
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        _orderId               = MKStrFrom(d[@"orderId"]);
        _orderStatus           = [d[@"orderStatus"] integerValue];
        _loanAmount            = MKStrFrom(d[@"loanAmount"]);
        _applyDate             = MKStrFrom(d[@"applyDate"] ?: d[@"borrowingDate"]);
        _dueDate               = MKStrFrom(d[@"dueDate"]);
        _payoutDate            = MKStrFrom(d[@"payoutDate"]);
        _repaymentDate         = MKStrFrom(d[@"repaymentDate"]);
        _loanTerm              = [d[@"loanTerm"] integerValue];
        _loanTermUnit          = [(d[@"loanTermUnit"] ?: d[@"productTermUnit"]) integerValue];
        _showTerm              = [d[@"showTerm"] integerValue];
        _receiptAmount         = MKStrFrom(d[@"receiptAmount"] ?: d[@"arrivalAmount"]);
        _interestAmount        = MKStrFrom(d[@"interestAmount"]);
        _feeAmount             = MKStrFrom(d[@"feeAmount"]);
        _taxAmount             = MKStrFrom(d[@"taxAmount"]);
        _shouldRepaymentAmount = MKStrFrom(d[@"shouldRepaymentAmount"]);
        _alreadyRepaymentAmount= MKStrFrom(d[@"alreadyRepaymentAmount"]);
        _totalRepaymentAmount  = MKStrFrom(d[@"totalRepaymentAmount"]);
        _reductionAmount       = MKStrFrom(d[@"reductionAmount"]);
        _penaltyAmount         = MKStrFrom(d[@"penaltyAmount"]);
        _dueExtensionFeeAmount = MKStrFrom(d[@"dueExtensionFeeAmount"]);
        _EMIAmount             = MKStrFrom(d[@"EMIAmount"]);
        _EMITenure             = [d[@"EMITenure"] integerValue];
        _ifExtension           = [d[@"ifExtension"] integerValue];
        _extensionTimes        = [d[@"extensionTimes"] integerValue];
        _penaltyDays           = [d[@"penaltyDays"] integerValue];
        id list = d[@"productTermItemList"];
        if ([list isKindOfClass:[NSArray class]]) _productTermItemList = list;
    }
    return self;
}
@end

#pragma mark - 顶层

@implementation MKOrderDetailModel
- (instancetype)initWithDictionary:(NSDictionary *)d {
    if (self = [super init]) {
        id p  = d[@"product"];     if ([p  isKindOfClass:[NSDictionary class]]) _product     = [[MKOrderDetailProduct alloc]  initWithDictionary:p];
        id bc = d[@"bankCard"];    if ([bc isKindOfClass:[NSDictionary class]]) _bankCard    = [[MKOrderDetailBankCard alloc] initWithDictionary:bc];
        id od = d[@"orderDetail"]; if ([od isKindOfClass:[NSDictionary class]]) _orderDetail = [[MKOrderDetailInfo alloc]     initWithDictionary:od];
        _isWillingRepay = [d[@"isWillingRepay"] integerValue];
        _message        = MKStrFrom(d[@"message"]);
    }
    return self;
}
@end
