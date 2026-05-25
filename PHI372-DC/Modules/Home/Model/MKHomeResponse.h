//
//  MKHomeResponse.h
//  PHI372-DC
//
//  suphome 接口响应 + 产品列表响应 + KYC状态响应
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Home Response (suphome)

@interface MKHomeDataModel : NSObject
@property (nonatomic, assign) NSInteger userStatus;       // 10=未认证
@property (nonatomic, assign) NSInteger appUserType;      // 1=新客 2=复借
@property (nonatomic, copy, nullable) NSString *promptCopy;
@property (nonatomic, assign) NSInteger hasOrder;
@property (nonatomic, copy, nullable) NSString *withdrawalOrderId;
@property (nonatomic, copy, nullable) NSString *withdrawalProductId;
@property (nonatomic, copy, nullable) NSString *firstLoanOptionLine;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface MKHomeResponse : NSObject
@property (nonatomic, strong, nullable) MKHomeDataModel *data;
@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy) NSString *resultMsg;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isSuccess;
@end

#pragma mark - Product List Response

@class MKProductInfoModel;

@interface MKProductListResponse : NSObject
@property (nonatomic, strong) NSArray<MKProductInfoModel *> *productInfoList;
@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy) NSString *resultMsg;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isSuccess;
@end

#pragma mark - KYC Status Response

@interface MKKYCStatusResponse : NSObject
@property (nonatomic, copy) NSString *willExecuteStepNumber;
@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy) NSString *resultMsg;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isSuccess;
@end

NS_ASSUME_NONNULL_END
