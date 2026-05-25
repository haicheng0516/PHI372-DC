//
//  MKHomeHeaderView.h
//  PHI372-DC
//
//  首页 tableHeaderView — 渐变背景 + Banner + Icon Grid.
//

#import <UIKit/UIKit.h>
#import "MKHomeIconGridView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeHeaderView : UIView
@property (nonatomic, copy, nullable) void(^onIconTapped)(MKHomeIconKind kind);
+ (CGFloat)height;     // Figma: gradient 0..484, 但 header 自身只到 iconGrid 底部 (255+80=335)
@end

NS_ASSUME_NONNULL_END
