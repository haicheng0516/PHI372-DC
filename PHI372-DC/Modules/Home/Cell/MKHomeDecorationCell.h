//
//  MKHomeDecorationCell.h
//
//  首页装饰图 Cell — 用于 BeforeKYC 中部插画 (mk_home_partners 等).
//

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeDecorationCell : MKBaseTableViewCell
- (void)configureImage:(NSString *)imageName;
+ (CGFloat)rowHeight;
@end

NS_ASSUME_NONNULL_END
