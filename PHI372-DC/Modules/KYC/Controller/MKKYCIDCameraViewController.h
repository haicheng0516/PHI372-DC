//  MKKYCIDCameraViewController.h
//  KYC-身份证认-拍照 — Figma 3:1126

#import <UIKit/UIKit.h>
#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCIDCameraViewController : MKBaseViewController
/// 若 nil, confirm 走旧的 push Liveness 兜底.
@property (nonatomic, copy, nullable) void(^onImageCaptured)(UIImage *image, UIDeviceOrientation orientation);
@end

NS_ASSUME_NONNULL_END
