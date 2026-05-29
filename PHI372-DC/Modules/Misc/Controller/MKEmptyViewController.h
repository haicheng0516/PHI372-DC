//
//  MKEmptyViewController.h
//
//  空白页 — Figma 3:1325
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKEmptyViewController : MKBaseViewController
/// 指定空白文字的便捷初始化
- (instancetype)initWithTitle:(NSString *)title emptyText:(NSString *)emptyText;
@end

NS_ASSUME_NONNULL_END
