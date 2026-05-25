//
//  UIImage+MKOrientation.h
//  PHI372-DC
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (MKOrientation)

/// 修复图片的EXIF方向信息，返回正确方向的图片
- (UIImage *)fixOrientation;

/// 根据设备方向旋转图片
- (UIImage *)rotateBasedOnDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

/// 将图片旋转指定角度
- (UIImage *)rotateByDegrees:(CGFloat)degrees;

@end

NS_ASSUME_NONNULL_END
