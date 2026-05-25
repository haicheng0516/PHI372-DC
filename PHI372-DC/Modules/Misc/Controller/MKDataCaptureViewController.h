//
//  MKDataCaptureViewController.h
//  PHI372-DC
//
//  数据抓取进度蒙层 — Figma 3:1670
//  下单后通讯录上传期间作为 modal overlay 显示, 动态更新进度
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKDataCaptureViewController : MKBaseViewController

/// 当前进度 0~100, 默认 0
@property (nonatomic, assign) NSInteger progress;

/// 设置进度 + 动画到位
- (void)setProgress:(NSInteger)progress animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
