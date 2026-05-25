//
//  MKKYCProgressBarView.h
//  PHI372-DC
//
//  KYC 顶部进度条 — Figma 设计是带斜条纹的胶囊形, 含浅底 + 深色填充段.
//  本占位实现: 浅绿底胶囊 + 深绿填充 (UIImageView placeholder).
//  待补正版条纹素材后, 把 stripePattern 属性赋为图片即可.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCProgressBarView : UIView

/// KYC 共 4 步: Personal=1, Finance=2, Contact=3, ID=4
@property (nonatomic, assign) NSInteger totalSteps;     // 默认 4
@property (nonatomic, assign) NSInteger currentStep;    // 1-based

/// 后续替换真条纹素材时设进来
@property (nonatomic, strong, nullable) UIImage *stripePattern;

@end

NS_ASSUME_NONNULL_END
