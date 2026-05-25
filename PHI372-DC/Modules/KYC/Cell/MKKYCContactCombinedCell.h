//
//  MKKYCContactCombinedCell.h
//  PHI372-DC
//
//  Figma 紧急联系人 — Name + Phone 合并卡 (上下两行 + 中间分隔线 + 一个 chevron).
//  上半 Name: 不可编辑, 点击触发 onPickContact 调通讯录 (回填 name + phone).
//  下半 Phone: UITextField, 自由输入.
//

#import "MKBaseTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCContactCombinedCell : MKBaseTableViewCell

@property (nonatomic, strong, readonly) UITextField *phoneField;

- (void)configWithName:(nullable NSString *)name phone:(nullable NSString *)phone;

/// 点击 Name 区域 (上半)
@property (nonatomic, copy, nullable) void (^onPickContactTapped)(void);
/// Phone 输入变化
@property (nonatomic, copy, nullable) void (^onPhoneChanged)(NSString *phone);

@end

NS_ASSUME_NONNULL_END
