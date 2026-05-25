//
//  MKOrderListCell.h
//  PHI372-DC
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKOrderListCell : UITableViewCell
+ (CGFloat)cellHeight;
- (void)configureAmount:(NSString *)amount status:(NSString *)status dueDate:(NSString *)due statusColor:(UIColor *)c;
@end

NS_ASSUME_NONNULL_END
