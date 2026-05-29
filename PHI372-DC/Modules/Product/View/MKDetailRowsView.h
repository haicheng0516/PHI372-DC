//
//  MKDetailRowsView.h
//
//  Loan 详情多行容器, 装多个 MKDetailRow
//

#import <UIKit/UIKit.h>
#import "MKDetailRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKDetailRowsView : UIView

/// 每项 config = @{ @"label": NSString, @"hasInfo": NSNumber(BOOL) }
- (instancetype)initWithRowConfigs:(NSArray<NSDictionary *> *)configs;

/// 按顺序设置 5 行的 value
- (void)setValues:(NSArray<NSString *> *)values;

/// 点击任意一行的 ⓘ 图标
@property (nonatomic, copy, nullable) void(^onInfoTapped)(NSInteger row, UIView *anchor);

/// 容器总高度
+ (CGFloat)viewHeightForCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
