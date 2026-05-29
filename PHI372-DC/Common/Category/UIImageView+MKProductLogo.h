//
//  UIImageView+MKProductLogo.h
//
//  产品 logo 加载 + 失败兜底色块。
//  加载成功 → 显示图, backgroundColor 自动清成 clearColor。
//  加载失败 / URL 为空 → 保留 fallback 兜底色块, 不留白方块。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (MKProductLogo)

/// 加载 URL 图, 失败/空时保留 fallback 兜底色块。
/// @param urlString  图 URL, nil/空时直接展示 fallback。
/// @param fallback   兜底色, 一般传 kColorPrimary。
- (void)mk_setProductLogoURL:(nullable NSString *)urlString
               fallbackColor:(UIColor *)fallback;

@end

NS_ASSUME_NONNULL_END
