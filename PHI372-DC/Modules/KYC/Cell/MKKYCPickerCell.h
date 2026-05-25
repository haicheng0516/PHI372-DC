//
//  MKKYCPickerCell.h
//  PHI372-DC
//
//  KYC 表单选择 Cell - 移植自 334 RDKYCPickerCell, UI 适配 PHI372 设计.
//

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCPickerCell : MKBaseTableViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *valueLabel;
@property (nonatomic, copy, nullable) void(^tapBlock)(void);

- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder;
- (void)setSelectedValue:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
