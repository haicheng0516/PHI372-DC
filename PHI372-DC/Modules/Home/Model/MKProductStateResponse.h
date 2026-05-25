//
//  MKProductStateResponse.h
//  PHI372-DC — /app/v3/product/state 响应包装 (照搬 334 RDProductStateResponse)
//

#import <Foundation/Foundation.h>
#import "MKProductStateDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKProductStateDataModel : NSObject

@property (nonatomic, strong) NSArray<MKProductStateDetailModel *> *amountDetailList;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface MKProductStateResponse : NSObject

@property (nonatomic, strong, nullable) MKProductStateDataModel *data;
@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy) NSString *resultMsg;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
