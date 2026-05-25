//
//  MKHomeProductCell.h
//  PHI372-DC
//
//  首页产品 Cell — 包 MKHomeProductCardView (Figma 339×126 + 间距 12pt).
//

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeProductCell : MKBaseTableViewCell
- (void)configureName:(NSString *)name quota:(NSString *)quota rate:(NSString *)rate logoUrl:(nullable NSString *)logoUrl;
@property (nonatomic, copy, nullable) void(^onApplyTapped)(void);
+ (CGFloat)rowHeight;
@end

NS_ASSUME_NONNULL_END
