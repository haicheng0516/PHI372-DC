//
//  MKOrderListModel.m
//

#import "MKOrderListModel.h"

@implementation MKOrderListModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        _orderId     = [NSString stringWithFormat:@"%@", dict[@"orderId"]     ?: @""];
        _productId   = [NSString stringWithFormat:@"%@", dict[@"productId"]   ?: @""];
        _productName = [NSString stringWithFormat:@"%@", dict[@"productName"] ?: @""];
        _loanAmount  = [NSString stringWithFormat:@"%@", dict[@"loanAmount"]  ?: @""];
        _orderStatus = [dict[@"orderStatus"] integerValue];
        _applyDate   = [NSString stringWithFormat:@"%@", dict[@"applyDate"]   ?: @""];

        id v;
        v = dict[@"loanDate"];  if (v && v != NSNull.null) _loanDate  = [NSString stringWithFormat:@"%@", v];
        v = dict[@"dueDate"];   if (v && v != NSNull.null) _dueDate   = [NSString stringWithFormat:@"%@", v];
        v = dict[@"repayDate"]; if (v && v != NSNull.null) _repayDate = [NSString stringWithFormat:@"%@", v];
    }
    return self;
}

@end
