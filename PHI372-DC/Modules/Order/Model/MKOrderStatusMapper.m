//
//  MKOrderStatusMapper.m
//

#import "MKOrderStatusMapper.h"
#import "MKConstants.h"
#import "MKOrderListModel.h"

@implementation MKOrderStatusMapper

+ (NSInteger)sectionForStatus:(NSInteger)status {
    switch (status) {
        case 10: case 20: case 32: case 36:
            return MKOrderSectionSubmitApplication;
        case 30: case 50:
            return MKOrderSectionProcessing;
        case 60: case 61: case 63:
            return MKOrderSectionPendingRepayment;
        case 31: case 70: case 71: case 99:
            return MKOrderSectionCompleted;
        default:
            return -1;  // 未知状态过滤掉
    }
}

+ (NSString *)chipTextForStatus:(NSInteger)status {
    switch (status) {
        case 10: case 20: return @"Unfinished Application";
        case 32:          return @"To be withdrawn";
        case 36:          return @"Change bank account";
        case 30:          return @"Under review";
        case 50:          return @"Loan processing";
        case 60: case 63: return @"Pending Repayment";
        case 61:          return @"Overdue";
        case 70: case 71: return @"Pay off";
        case 31:          return @"Reject";
        case 99:          return @"Cancel";
        default:          return @"";
    }
}

+ (UIColor *)chipColorForStatus:(NSInteger)status {
    switch (status) {
        case 10: case 20: return MKHexColor(0x532C6E);  // Unfinished Application
        case 32:          return MKHexColor(0x0A7F93);  // To be withdrawn
        case 36:          return MKHexColor(0x6E1758);  // Change bank account
        case 30:          return MKHexColor(0x11722E);  // Under review
        case 50:          return MKHexColor(0x527217);  // Loan processing
        case 60: case 63: return MKHexColor(0xAF5D00);  // Pending Repayment
        case 61:          return MKHexColor(0xA0721B);  // Overdue
        case 70: case 71: return MKHexColor(0x2054B7);  // Pay off
        case 31:          return MKHexColor(0x8A1315);  // Reject
        case 99:          return MKHexColor(0x5F5F5F);  // Cancel
        default:          return [UIColor grayColor];
    }
}

+ (NSString *)dateLabelForStatus:(NSInteger)status {
    switch (status) {
        case 60: case 61: case 63: return @"Payment date:";
        case 99:                    return @"Repayment date:";
        default:                    return @"Date of application:";
    }
}

+ (NSString *)dateValueForStatus:(NSInteger)status fromModel:(MKOrderListModel *)model {
    switch (status) {
        case 60: case 61: case 63: return model.dueDate ?: @"";
        case 99:                    return model.repayDate ?: @"";
        default:                    return model.applyDate ?: @"";
    }
}

@end
