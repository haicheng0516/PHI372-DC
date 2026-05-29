//
//  MKToastView.h
//
//  通用吐司 / Tooltip 提示.
//  Pencil b4hMw0 中间灰色块"Calculated based on..."就是这个,默认 2.5 秒自动消失.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKToastView : NSObject

/// 在 keyWindow 中央显示一条 toast, 默认 2.5 秒自动消失
+ (void)showText:(NSString *)text;

/// 自定义停留时长
+ (void)showText:(NSString *)text duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
