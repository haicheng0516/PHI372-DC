//
//  NSString+MKEncrypt.h
//  PHI372-DC
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MKEncrypt)

+ (NSString *)rd_md5:(NSString *)input;
+ (NSString *)rd_hmacSHA256:(NSString *)data key:(NSString *)key;
+ (NSString *)rd_randomNonce16;
+ (NSString *)rd_currentTimeMillisString;
+ (NSString *)rd_safeString:(id)obj;
+ (id)rd_normalizeJSONObject:(id)obj;

@end

NS_ASSUME_NONNULL_END
