//
//  MKPayAccountModel.h
//  PHI372-DC
//
//  /app/v3/payAccountInfo/list 响应中的单条银行卡记录.
//  跨页面复用:
//    - 下单页银行卡选择弹窗 (用 displayName)
//    - Bank Account 列表页 (用 bankCode/cardNumber/accountName 分行展示)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKPayAccountModel : NSObject

@property (nonatomic, assign) NSInteger recordId;
@property (nonatomic, assign) NSInteger bankCardBindId;
@property (nonatomic, assign) BOOL defaultFlag;       // "1" → YES
@property (nonatomic, assign) BOOL editFlag;          // "1" → YES (列表页 Edit 按钮可点)
@property (nonatomic, assign) NSInteger status;

/// 模糊匹配出的展示字段 (Pencil bPx5L 列表卡片 3 行)
@property (nonatomic, copy, nullable) NSString *bankCode;     // 第 1 行: bank/account 标识 "UDHN 0909854"
@property (nonatomic, copy, nullable) NSString *cardNumber;   // 第 2 行: 卡号 "2832 5969 4859 1236"
@property (nonatomic, copy, nullable) NSString *accountName;  // 第 3 行: 户名 "Lezama Vara Maria Fernanda"

/// 单行拼装版 (下单页弹窗用): "bankCode: ****1236"
@property (nonatomic, copy, nullable) NSString *displayName;

@property (nonatomic, strong) NSDictionary *originalDict;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

+ (NSArray<MKPayAccountModel *> *)modelsFromList:(NSArray *)rawList;

@end

NS_ASSUME_NONNULL_END
