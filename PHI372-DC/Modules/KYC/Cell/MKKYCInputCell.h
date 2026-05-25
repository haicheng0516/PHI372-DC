//  MKKYCInputCell.h
//  PHI372-DC

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MKKYCInputCellTextChangeBlock)(NSString *text);

@interface MKKYCInputCell : MKBaseTableViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UITextField *inputField;
@property (nonatomic, copy, nullable) MKKYCInputCellTextChangeBlock textChangeBlock;
@property (nonatomic, copy, nullable) void(^onReturnPressed)(void);

@property (nonatomic, assign) NSUInteger maxLength;

- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder;
- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder value:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
