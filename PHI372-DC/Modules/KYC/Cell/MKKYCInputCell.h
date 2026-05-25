//
//  MKKYCInputCell.h
//  PHI372-DC
//
//  KYC 表单输入 Cell - 移植自 334 RDKYCInputCell, UI 适配 PHI372 设计.
//

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MKKYCInputCellTextChangeBlock)(NSString *text);

@interface MKKYCInputCell : MKBaseTableViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UITextField *inputField;
@property (nonatomic, copy, nullable) MKKYCInputCellTextChangeBlock textChangeBlock;
@property (nonatomic, copy, nullable) void(^onReturnPressed)(void);

/// 最大字符长度, 0 = 不限制. 照搬 259 FormInputCell 思路, shouldChangeCharactersInRange 拦截超长
@property (nonatomic, assign) NSUInteger maxLength;

- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder;
- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder value:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
