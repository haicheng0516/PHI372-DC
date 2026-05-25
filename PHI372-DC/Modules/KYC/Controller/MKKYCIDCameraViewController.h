//
//  MKKYCIDCameraViewController.h
//  PHI372-DC
//
//  KYC-身份证认-拍照 — Figma 3:1126
//

#import <UIKit/UIKit.h>
#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCIDCameraViewController : MKBaseViewController
/// 照搬 334 RDKYC5: 用户确认后回传 image + 拍照瞬间设备方向, 调用方负责 fixOrientation/rotate.
/// 若 nil, confirm 走旧的 push Liveness 兜底.
@property (nonatomic, copy, nullable) void(^onImageCaptured)(UIImage *image, UIDeviceOrientation orientation);
@end

NS_ASSUME_NONNULL_END
