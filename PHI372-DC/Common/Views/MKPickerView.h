//
//  MKPickerView.h
//  PHI372-DC
//  选择列表弹框 - 匹配设计稿"弹框-选择"样式
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MKPickerSelectBlock)(NSInteger index, NSString *value);
typedef void(^MKPickerCancelBlock)(void);

@interface MKPickerView : UIView

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, strong) NSArray<NSString *> *options;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy, nullable) MKPickerSelectBlock selectBlock;
@property (nonatomic, copy, nullable) MKPickerCancelBlock cancelBlock;

/// 便捷弹出方法
+ (void)showWithTitle:(NSString *)title
              options:(NSArray<NSString *> *)options
        selectedIndex:(NSInteger)index
             onSelect:(MKPickerSelectBlock)selectBlock;

/// 带取消回调的弹出方法
+ (void)showWithTitle:(NSString *)title
              options:(NSArray<NSString *> *)options
        selectedIndex:(NSInteger)index
             onSelect:(MKPickerSelectBlock)selectBlock
             onCancel:(nullable MKPickerCancelBlock)cancelBlock;

- (void)show;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
