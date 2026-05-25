//  MKProductStateDetailModel.h
//  PHI372-DC — /app/v3/product/state 响应 data.amountDetailList 元素

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKProductStateDetailModel : NSObject

@property (nonatomic, copy) NSString *loanAmount;
@property (nonatomic, copy) NSString *productLogo;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, assign) NSInteger userType;
@property (nonatomic, copy) NSString *productId;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
