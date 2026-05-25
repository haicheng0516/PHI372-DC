//
//  MKProductInfoModel.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKProductInfoModel : NSObject

@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, copy) NSString *productLogo;
@property (nonatomic, copy) NSString *productLabel;
@property (nonatomic, copy, nullable) NSString *lowestLoanInterestRate;
@property (nonatomic, copy, nullable) NSString *productApplicantsNumber;
@property (nonatomic, copy) NSString *lowAmount;
@property (nonatomic, copy) NSString *highAmount;
@property (nonatomic, copy) NSString *highestTerm;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
