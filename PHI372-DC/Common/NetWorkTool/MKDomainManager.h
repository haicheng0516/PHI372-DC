//
//  MKDomainManager.h
//
//  动态域名管理器:
//    - 启动时从远程配置源(GitHub raw / Gitee raw / Pastebin raw 等开放平台)拉真实 API/H5 域名
//    - 配置源列表按优先级降级, 任意一个能拉到就停
//    - 拉到的域名缓存到 NSUserDefaults, 下次冷启动有缓存先用缓存 + 后台静默刷新
//    - 域名在 raw 文本里做轻度混淆(Sea 前缀 / City 后缀), 运行时去掉再加 https://
//    - 单次请求失败时, 业务层可调 tryNextSourceWithCompletion 切下一个源 + 重试
//
//  接入流程:
//    1. 准备一个或多个开放平台 raw 文本(GitHub/Gitee/Pastebin 等), 文本格式见 README
//    2. 在 -initPrivate 里把这些 URL 按优先级填进 _configSources
//    3. SceneDelegate.willConnectToSession 调 loadConfigWithCompletion: 触发首次加载
//    4. 关键路径(申请/订单/拒量等)调 MKNetworkManager postWithDomainFailover: 享受请求级容灾
//
//  配置源文本格式示例(纯文本, 一行一个键值对, # 开头是注释):
//    api_url: SeapiCity.example.com
//    h5_url:  Seh5City.example.com
//
//  注意:
//    - 配置源 URL 列表是项目专属, 多个项目共用同一个 URL 会导致后端串数据
//    - NSUserDefaults key 已加 bundleIdentifier 后缀做项目隔离, 同设备多 App 不互串
//    - 无配置源(列表全空)时 loadConfigWithCompletion: 直接回调 NO, 不阻塞启动,
//      MKNetworkManager 会回落到 Info.plist MKBaseURL
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 配置源类型
typedef NS_ENUM(NSInteger, MKDomainConfigSourceType) {
    MKDomainConfigSourceTypeGitHub = 0,
    MKDomainConfigSourceTypeGitee,
    MKDomainConfigSourceTypePastebin,
    MKDomainConfigSourceTypeCustom,
};

@interface MKDomainManager : NSObject

+ (instancetype)sharedManager;

/// 取缓存的 API 域名(带 https:// 前缀)。无缓存返回 nil。
- (NSString * _Nullable)getAPI;

/// 取缓存的 H5 域名(带 https:// 前缀)。无缓存返回 nil。
- (NSString * _Nullable)getH5;

/// 当前命中的配置源名称(GitHub/Gitee/Pastebin/Custom/Unknown)。
- (NSString *)getCurrentSourceType;

/// 配置源总数。供外部计算请求级 failover 最大重试次数。
- (NSInteger)getSourceCount;

/// 加载配置。
///   - 有缓存 → 立即回调 success=YES + 后台静默刷新
///   - 无缓存 → 阻塞按优先级遍历配置源, 拿到第一个成功就停
///   - 全失败/无配置源 → 回调 success=NO
- (void)loadConfigWithCompletion:(void(^ _Nullable)(BOOL success))completion;

/// 切到下一个配置源并重新拉取。请求级 failover 用。
///   - 还有下一个源 → 拉取成功后回调 (YES, newDomain)
///   - 没有更多源 → 回调 (NO, nil)
- (void)tryNextSourceWithCompletion:(void(^)(BOOL success, NSString * _Nullable newDomain))completion;

/// 强制清缓存后从头加载(忽略缓存)。
- (void)refreshConfigWithCompletion:(void(^ _Nullable)(BOOL success))completion;

/// 清缓存(API + H5 + 源类型)。
- (void)clearCache;

/// 拼接完整 API URL(getAPI + path)。
- (NSString *)buildAPIURL:(NSString *)path;

/// 拼接完整 H5 URL(getH5 + path)。
- (NSString *)buildH5URL:(NSString *)path;

/// 当前环境判断(域名含 test/dev/sandbox 视为 TEST, 否则 PROD)。
- (NSString *)getEnvironment;

@end

NS_ASSUME_NONNULL_END
