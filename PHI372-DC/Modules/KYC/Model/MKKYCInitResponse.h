//
//  MKKYCInitResponse.h
//
//  /app/v3/kyc/four/search-iterm 返回. 解析 kycItemList → MKKYCItemModel 数组.
//

#import <Foundation/Foundation.h>
#import "MKKYCItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCInitResponse : NSObject

@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy, nullable) NSString *resultMsg;
@property (nonatomic, copy) NSArray<MKKYCItemModel *> *kycItemList;

- (instancetype)initWithDictionary:(id _Nullable)dict;
/// 自定义 list key, 用于复用此 Response 解析其他接口 (e.g. /payAccountInfo/payAccountItemList → "payAccountInfoItemDtoList").
- (instancetype)initWithDictionary:(id _Nullable)dict listKey:(NSString *)listKey;
- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
