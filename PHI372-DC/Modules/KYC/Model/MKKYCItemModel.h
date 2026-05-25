//
//  MKKYCItemModel.h
//  PHI372-DC
//
//  KYC 表单字段模型. 主链路 (Personal/Finance/ID/Payment/BankCardEdit) 用 -initWithDictionary: 解析
//  search-iterm / payAccountItemList 返回; Contact 用工厂方法构造固定结构再补 relation buttonList.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MKKYCButtonModel (picker 选项)

@interface MKKYCButtonModel : NSObject
@property (nonatomic, copy) NSString *buttonKey;
@property (nonatomic, copy) NSString *buttonLabel;
@property (nonatomic, assign) NSInteger buttonSort;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

#pragma mark - MKKYCItemModel (单字段)

@interface MKKYCItemModel : NSObject
@property (nonatomic, copy) NSString *itemCode;            // 字段标识 e.g. "fullName"
@property (nonatomic, copy) NSString *itemName;            // 字段显示名 e.g. "Full Name"
@property (nonatomic, assign) NSInteger itemType;          // 1=input, 其他=picker
@property (nonatomic, assign) NSInteger itemSort;
@property (nonatomic, assign) NSInteger itemStatus;
@property (nonatomic, copy, nullable) NSString *regularExpression;
@property (nonatomic, assign) NSInteger isRequired;        // 1=必填
@property (nonatomic, copy, nullable) NSString *frontPrompts;
@property (nonatomic, copy, nullable) NSString *rearPrompts;
@property (nonatomic, copy) NSArray<MKKYCButtonModel *> *buttonList;

/// 用户已选 (运行时)
@property (nonatomic, copy, nullable) NSString *selectedKey;     // 实际提交值
@property (nonatomic, copy, nullable) NSString *selectedValue;   // 显示文本
@property (nonatomic, assign) NSInteger selectedIndex;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (BOOL)isPickerType;

/// Mock 工厂方法 (无 API 时用)
+ (instancetype)inputItemWithCode:(NSString *)code name:(NSString *)name required:(BOOL)required;
+ (instancetype)pickerItemWithCode:(NSString *)code name:(NSString *)name options:(NSArray<NSString *> *)options required:(BOOL)required;

@end

NS_ASSUME_NONNULL_END
