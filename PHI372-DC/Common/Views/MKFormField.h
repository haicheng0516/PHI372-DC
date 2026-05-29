//
//  MKFormField.h
//  通用表单输入组件 - 支持 input 和 picker 两种模式
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKFormFieldType) {
    MKFormFieldTypeInput,   // 文本输入
    MKFormFieldTypePicker,  // 下拉选择（带右箭头）
};

@interface MKFormField : UIView

@property (nonatomic, assign, readonly) MKFormFieldType fieldType;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, strong, readonly) UILabel *valueLabel;
@property (nonatomic, copy, nullable) void(^pickerTapBlock)(void);

- (instancetype)initWithType:(MKFormFieldType)type;
- (void)setTitle:(NSString *)title placeholder:(NSString *)placeholder;
- (void)setSelectedValue:(NSString *)value;
- (NSString *)inputValue;

/// 字段总高度（标题 + 间距 + 输入框）
+ (CGFloat)fieldHeight;

@end

NS_ASSUME_NONNULL_END
