//
//  MKBaseTableViewCell.h
//  PHI372-DC
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKBaseTableViewCell : UITableViewCell
+ (NSString *)cellIdentifier;
+ (void)registerForTableView:(UITableView *)tableView;
@end

NS_ASSUME_NONNULL_END
