//
//  MKKYCLivenessViewController.h
//  PHI372-DC
//
//  KYC-活体认证中 — Figma 3:1155
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCLivenessViewController : MKBaseViewController
/// 人脸识别完成回调; 调用者负责存图. 若 nil, tap 走旧的 push Done 兜底.
@property (nonatomic, copy, nullable) void(^onLivenessCompleted)(UIImage *image);
@end

NS_ASSUME_NONNULL_END
