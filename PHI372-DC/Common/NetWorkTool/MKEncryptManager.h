//
//  MKEncryptManager.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKEncryptManager : NSObject

+ (instancetype)sharedManager;

/// Generate request body with encryption method 1
- (NSDictionary *)generateRequestBody:(NSDictionary *)data;

/// Generate request body with custom sign data (encryption method 1)
- (NSDictionary *)generateRequestBodyWithSignData:(NSDictionary *)dataForSign
                                      requestData:(NSDictionary *)dataForRequest;

/// Generate request body with encryption method 3
- (NSDictionary *)generateRequestBodyForEncryptionThree:(NSDictionary *)data;

/// Generate request body with custom sign data (encryption method 3)
- (NSDictionary *)generateRequestBodyForEncryptionThreeWithSignData:(NSDictionary *)dataForSign
                                                        requestData:(NSDictionary *)dataForRequest;

@end

NS_ASSUME_NONNULL_END
