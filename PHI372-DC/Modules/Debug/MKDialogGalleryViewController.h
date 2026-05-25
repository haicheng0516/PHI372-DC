//
//  MKDialogGalleryViewController.h
//  PHI372-DC — 调试: 21 种 Dialog 类型列表, 点击 row 弹对应 dialog
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKDialogGalleryViewController : MKBaseViewController
/// 用于自动化截图: 启动即展示指定类型 (1-21, 0=不自动展示)
@property (nonatomic, assign) NSInteger autoShowType;
@end

NS_ASSUME_NONNULL_END
