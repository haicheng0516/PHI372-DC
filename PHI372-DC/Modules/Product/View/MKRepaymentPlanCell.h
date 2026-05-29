//
//  MKRepaymentPlanCell.h
//  Pencil b4hMw0: Repayment plan 按钮 (y=515) 303×56
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKRepaymentPlanCell : UITableViewCell

+ (CGFloat)cellHeight;
@property (nonatomic, copy, nullable) void(^onTapped)(void);

@end

NS_ASSUME_NONNULL_END
