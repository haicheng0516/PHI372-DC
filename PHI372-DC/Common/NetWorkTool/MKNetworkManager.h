//  MKNetworkManager.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MKNetworkSuccess)(id _Nullable responseObject);
typedef void(^MKNetworkFailure)(NSError *error);

@interface MKNetworkManager : NSObject

+ (instancetype)sharedManager;

/// 基础 URL (开发期写死 test 环境)
@property (nonatomic, copy) NSString *baseURLString;

/// POST JSON (params 已经过 MKEncryptManager 包装)
- (void)post:(NSString *)path
      params:(NSDictionary * _Nullable)params
     success:(MKNetworkSuccess)success
     failure:(MKNetworkFailure)failure;

/// POST JSON + 自定义 headers
- (void)post:(NSString *)path
      params:(NSDictionary * _Nullable)params
     headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
     success:(MKNetworkSuccess)success
     failure:(MKNetworkFailure)failure;

/// 上传文件 (multipart/form-data) — 用于头像/身份证/活体图等
- (void)uploadFile:(NSString *)path
            params:(NSDictionary * _Nullable)params
          fileData:(NSData *)fileData
          fileName:(NSString * _Nullable)fileName
          mimeType:(NSString * _Nullable)mimeType
           headers:(NSDictionary<NSString *, NSString *> * _Nullable)headers
          progress:(void(^ _Nullable)(NSProgress *progress))progress
           success:(MKNetworkSuccess)success
           failure:(MKNetworkFailure)failure;

@end

NS_ASSUME_NONNULL_END
