//
//  MKHomeNoticeCell.h
//  PHI372-DC
//
//  首页提示 Cell — 包 MKHomeKYCTipCardView, 高度跟随文本自适应.
//

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeNoticeCell : MKBaseTableViewCell
- (void)configureWithText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
