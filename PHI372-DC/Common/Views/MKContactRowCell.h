//
//  MKContactRowCell.h
//  PHI372-DC — Figma 3:1281 / 3:1296 / 3:1527 通用联系行
//
//  尺寸: 339×60 (横排)
//  背景 #E9E9E4 圆角 14
//  内容: icon 42×42 @ (9,9) + value 文字 (#385330 16pt) + copy 按钮 24×24 (右内边距 17)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MKContactRowKind) {
    MKContactRowKindWebsite,   // 网址
    MKContactRowKindEmail,     // 邮箱
};

@interface MKContactRowCell : UIControl
@property (nonatomic, copy) void (^onCopyTapped)(NSString *value);
- (instancetype)initWithKind:(MKContactRowKind)kind value:(NSString *)value;
+ (CGFloat)cellHeight;  // 60
@end

NS_ASSUME_NONNULL_END
