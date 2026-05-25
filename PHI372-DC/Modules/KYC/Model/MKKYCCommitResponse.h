//
//  MKKYCCommitResponse.h
//  PHI372-DC
//
//  KYC 各步提交接口的通用响应 (/personal /work /contact /liveness).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCCommitResponse : NSObject

@property (nonatomic, assign) NSInteger resultCode;
@property (nonatomic, copy, nullable) NSString *resultMsg;

- (instancetype)initWithDictionary:(id _Nullable)dict;
- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
