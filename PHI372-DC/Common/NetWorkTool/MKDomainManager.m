//
//  MKDomainManager.m
//

#import "MKDomainManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

#pragma mark - 配置源 model

@interface MKDomainConfigSource : NSObject
@property (nonatomic, assign) MKDomainConfigSourceType type;
@property (nonatomic, copy)   NSString *url;
@property (nonatomic, assign) NSInteger priority;
@end

@implementation MKDomainConfigSource
+ (instancetype)sourceWithType:(MKDomainConfigSourceType)type
                           url:(NSString *)url
                      priority:(NSInteger)priority {
    MKDomainConfigSource *s = [[self alloc] init];
    s.type = type; s.url = url ?: @""; s.priority = priority;
    return s;
}
@end

#pragma mark - MKDomainManager

@interface MKDomainManager ()
@property (nonatomic, strong) NSArray<MKDomainConfigSource *> *configSources;
@property (nonatomic, assign) NSInteger currentSourceIndex;
@property (nonatomic, copy)   NSString *cacheKeyAPI;
@property (nonatomic, copy)   NSString *cacheKeyH5;
@property (nonatomic, copy)   NSString *cacheKeySourceType;
@end

@implementation MKDomainManager

+ (instancetype)sharedManager {
    static MKDomainManager *inst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ inst = [[self alloc] initPrivate]; });
    return inst;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        _currentSourceIndex = -1;

        // 项目隔离: NSUserDefaults key 拼上 bundle id, 同设备装多个 App 不串数据
        NSString *bid = [NSBundle mainBundle].bundleIdentifier ?: @"unknown";
        _cacheKeyAPI        = [NSString stringWithFormat:@"mk_domain_api_%@", bid];
        _cacheKeyH5         = [NSString stringWithFormat:@"mk_domain_h5_%@", bid];
        _cacheKeySourceType = [NSString stringWithFormat:@"mk_domain_source_type_%@", bid];

        // ⚠️ 配置源 URL 必须每个项目独立填, 不要多项目共用!
        // 留空数组 → 跳过远程下发, MKNetworkManager 直接用 Info.plist MKBaseURL
        _configSources = @[
            // 示例(留空 TODO, 接入时按优先级填实际 raw 链接):
            // [MKDomainConfigSource sourceWithType:MKDomainConfigSourceTypeGitHub
            //                                  url:@"https://raw.githubusercontent.com/<owner>/<repo>/main/config.txt"
            //                             priority:1],
            // [MKDomainConfigSource sourceWithType:MKDomainConfigSourceTypeGitee
            //                                  url:@"https://gitee.com/<owner>/<repo>/raw/master/config.txt"
            //                             priority:2],
            // [MKDomainConfigSource sourceWithType:MKDomainConfigSourceTypePastebin
            //                                  url:@"https://pastebin.com/raw/<id>"
            //                             priority:3],
        ];

        NSLog(@"[MKDomain] init, cached API: %@, sources: %lu", [self getAPI] ?: @"(nil)", (unsigned long)_configSources.count);
    }
    return self;
}

#pragma mark - 缓存读写

- (NSString *)getAPI { return [[NSUserDefaults standardUserDefaults] stringForKey:self.cacheKeyAPI]; }
- (NSString *)getH5  { return [[NSUserDefaults standardUserDefaults] stringForKey:self.cacheKeyH5]; }

- (void)setCachedAPI:(NSString *)v {
    if (v.length > 0) [[NSUserDefaults standardUserDefaults] setObject:v forKey:self.cacheKeyAPI];
    else              [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cacheKeyAPI];
}

- (void)setCachedH5:(NSString *)v {
    if (v.length > 0) [[NSUserDefaults standardUserDefaults] setObject:v forKey:self.cacheKeyH5];
    else              [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cacheKeyH5];
}

- (NSString *)getCurrentSourceType {
    NSString *t = [[NSUserDefaults standardUserDefaults] stringForKey:self.cacheKeySourceType];
    return t.length > 0 ? t : @"Unknown";
}

- (void)setCachedSourceType:(NSString *)v {
    if (v.length > 0) [[NSUserDefaults standardUserDefaults] setObject:v forKey:self.cacheKeySourceType];
    else              [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cacheKeySourceType];
}

- (NSInteger)getSourceCount { return self.configSources.count; }

#pragma mark - 源类型名

- (NSString *)nameForSourceType:(MKDomainConfigSourceType)t {
    switch (t) {
        case MKDomainConfigSourceTypeGitHub:   return @"GitHub";
        case MKDomainConfigSourceTypeGitee:    return @"Gitee";
        case MKDomainConfigSourceTypePastebin: return @"Pastebin";
        case MKDomainConfigSourceTypeCustom:   return @"Custom";
    }
}

#pragma mark - 公开方法

- (void)loadConfigWithCompletion:(void(^)(BOOL))completion {
    // 无配置源 → 直接成功(走 Info.plist 默认值), 不阻塞启动
    if (self.configSources.count == 0) {
        NSLog(@"[MKDomain] no config sources, skip remote load");
        if (completion) completion(NO);
        return;
    }

    NSString *cached = [self getAPI];
    if (cached.length > 0) {
        NSLog(@"[MKDomain] cache hit: %@, background refresh", cached);
        // 后台静默刷新, 不阻塞业务, 失败不弹错(缓存仍可用)
        [self loadConfigFromSourceIndex:0 silent:YES completion:^(BOOL success) {
            NSLog(@"[MKDomain] background refresh: %@", success ? @"OK" : @"FAIL (cache kept)");
        }];
        if (completion) completion(YES);
    } else {
        NSLog(@"[MKDomain] no cache, blocking load...");
        [self loadConfigFromSourceIndex:0 silent:NO completion:completion];
    }
}

- (void)tryNextSourceWithCompletion:(void(^)(BOOL, NSString * _Nullable))completion {
    NSInteger next = self.currentSourceIndex + 1;
    if (next >= (NSInteger)self.configSources.count) {
        NSLog(@"[MKDomain] no more sources");
        if (completion) completion(NO, nil);
        return;
    }
    NSLog(@"[MKDomain] try next source %ld/%lu", (long)(next + 1), (unsigned long)self.configSources.count);
    __weak typeof(self) wself = self;
    [self loadConfigFromSourceIndex:next silent:NO completion:^(BOOL ok) {
        if (completion) completion(ok, ok ? [wself getAPI] : nil);
    }];
}

- (void)refreshConfigWithCompletion:(void(^)(BOOL))completion {
    NSLog(@"[MKDomain] force refresh");
    [self clearCache];
    [self loadConfigFromSourceIndex:0 silent:NO completion:completion];
}

- (void)clearCache {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cacheKeyAPI];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cacheKeyH5];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.cacheKeySourceType];
    NSLog(@"[MKDomain] cache cleared");
}

- (NSString *)buildAPIURL:(NSString *)path { return [NSString stringWithFormat:@"%@%@", [self getAPI] ?: @"", path ?: @""]; }
- (NSString *)buildH5URL:(NSString *)path  { return [NSString stringWithFormat:@"%@%@", [self getH5] ?: @"", path ?: @""]; }

- (NSString *)getEnvironment {
    NSString *api = ([self getAPI] ?: @"").lowercaseString;
    if ([api containsString:@"test"] || [api containsString:@"dev"] || [api containsString:@"sandbox"]) return @"TEST";
    return @"PROD";
}

#pragma mark - 私有: 按索引加载

- (void)loadConfigFromSourceIndex:(NSInteger)index
                           silent:(BOOL)silent
                       completion:(void(^)(BOOL))completion {
    if (index >= (NSInteger)self.configSources.count) {
        NSLog(@"[MKDomain] all %lu sources tried, fail", (unsigned long)self.configSources.count);
        if (!silent) [self showBusyHUD];
        if (completion) completion(NO);
        return;
    }
    self.currentSourceIndex = index;
    MKDomainConfigSource *src = self.configSources[index];
    NSString *name = [self nameForSourceType:src.type];

    if (src.url.length == 0) {
        NSLog(@"[MKDomain] %@ url empty, skip", name);
        [self loadConfigFromSourceIndex:index + 1 silent:silent completion:completion];
        return;
    }

    NSLog(@"[MKDomain] try %ld/%lu: %@", (long)(index + 1), (unsigned long)self.configSources.count, name);
    __weak typeof(self) wself = self;
    [self fetchConfigFromURL:src.url sourceType:src.type completion:^(BOOL ok) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        if (ok) {
            NSLog(@"[MKDomain] %@ OK, API=%@", name, [sself getAPI] ?: @"(nil)");
            if (completion) completion(YES);
        } else {
            NSLog(@"[MKDomain] %@ FAIL, try next", name);
            [sself loadConfigFromSourceIndex:index + 1 silent:silent completion:completion];
        }
    }];
}

#pragma mark - 私有: 从 URL 拉文本

- (void)fetchConfigFromURL:(NSString *)urlString
                sourceType:(MKDomainConfigSourceType)type
                completion:(void(^)(BOOL))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) { NSLog(@"[MKDomain] invalid URL: %@", urlString); if (completion) completion(NO); return; }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    req.timeoutInterval = 15;

    NSString *name = [self nameForSourceType:type];
    __weak typeof(self) wself = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;

        if (err) { NSLog(@"[MKDomain] %@ network err: %@", name, err.localizedDescription); if (completion) completion(NO); return; }

        NSInteger code = ((NSHTTPURLResponse *)resp).statusCode;
        if (code != 200) { NSLog(@"[MKDomain] %@ HTTP %ld", name, (long)code); if (completion) completion(NO); return; }

        if (!data) { NSLog(@"[MKDomain] %@ empty data", name); if (completion) completion(NO); return; }
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!text) { NSLog(@"[MKDomain] %@ decode fail", name); if (completion) completion(NO); return; }

        NSString *api = [sself parseAPIFromConfig:text];
        if (!api) { NSLog(@"[MKDomain] %@ no api parsed", name); if (completion) completion(NO); return; }

        // 校验: 去 scheme 后必须含点(简易域名格式校验)
        NSString *bare = [api stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        bare = [bare stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        if (![bare containsString:@"."]) { NSLog(@"[MKDomain] %@ invalid api: %@", name, api); if (completion) completion(NO); return; }

        [sself setCachedAPI:api];
        NSLog(@"[MKDomain] saved API: %@", api);

        NSString *h5 = [sself parseH5FromConfig:text];
        if (h5.length > 0) {
            [sself setCachedH5:h5];
            NSLog(@"[MKDomain] saved H5: %@", h5);
        }

        [sself setCachedSourceType:name];
        if (completion) completion(YES);
    }];
    [task resume];
}

#pragma mark - 私有: 解析

- (NSString *)parseAPIFromConfig:(NSString *)config {
    NSArray<NSString *> *lines = [config componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) continue;

        NSRange colon = [trimmed rangeOfString:@":"];
        if (colon.location != NSNotFound) {
            NSString *key = [[trimmed substringToIndex:colon.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *val = [[trimmed substringFromIndex:colon.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *lk = key.lowercaseString;
            if ([lk isEqualToString:@"api_url"] || [lk isEqualToString:@"api"] ||
                [lk isEqualToString:@"api_url_prod"] || [lk isEqualToString:@"api_domain"]) {
                return [self processDomainValue:val];
            }
        } else {
            NSString *p = [self processDomainValue:trimmed];
            NSString *bare = [p stringByReplacingOccurrencesOfString:@"https://" withString:@""];
            bare = [bare stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            if ([bare containsString:@"."]) return p;
        }
    }
    return nil;
}

- (NSString *)parseH5FromConfig:(NSString *)config {
    NSArray<NSString *> *lines = [config componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) continue;
        NSRange colon = [trimmed rangeOfString:@":"];
        if (colon.location == NSNotFound) continue;
        NSString *key = [[trimmed substringToIndex:colon.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *val = [[trimmed substringFromIndex:colon.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *lk = key.lowercaseString;
        if ([lk isEqualToString:@"h5_url"] || [lk isEqualToString:@"h5"] ||
            [lk isEqualToString:@"content_url"] || [lk isEqualToString:@"h5_domain"]) {
            return [self processDomainValue:val];
        }
    }
    return nil;
}

/// 处理域名值: 去 Sea 前缀 + 去 City 后缀 + 补 https://
/// (raw 文本里的轻度混淆, 防止审核员/爬虫扫到 raw 链接直接拿到真实金融域名)
- (NSString *)processDomainValue:(NSString *)value {
    if (value.length == 0) return @"";
    NSMutableString *p = [value mutableCopy];
    if ([p hasPrefix:@"Sea"])  [p deleteCharactersInRange:NSMakeRange(0, 3)];
    if ([p hasSuffix:@"City"]) [p deleteCharactersInRange:NSMakeRange(p.length - 4, 4)];
    if (![p hasPrefix:@"http://"] && ![p hasPrefix:@"https://"]) [p insertString:@"https://" atIndex:0];
    return [p copy];
}

#pragma mark - HUD

- (void)showBusyHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:@"The system is busy. Please try again in 2 minutes."];
        [SVProgressHUD dismissWithDelay:3.0];
    });
}

@end
