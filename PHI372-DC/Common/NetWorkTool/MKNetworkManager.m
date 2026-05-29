//  MKNetworkManager.m
//    - JSON 上行/下行用 AFJSONRequest/ResponseSerializer
//    - 每次请求 setValue UA forHTTPHeaderField
//    - 全局 resultCode 拦截: 2000001/2000002/2002001 → 重新登录; 2009006 → 强更
//    - 强更弹窗用 MKBottomSheetView

#import "MKNetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import <UIKit/UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "MKCommonParams.h"
#import "MKEncryptManager.h"
#import "MKLoginManager.h"
#import "MKAppVersionResponse.h"
#import "MKBottomSheetView.h"
#import "MKAppEnvironment.h"
// 注: MKSignInViewController 走 NSClassFromString 软引用, 不硬 import,
//     避免 Common → Modules 反向依赖(模板提升时 Common 要单独可编译)

// 需要重登的 resultCode (token 过期/被踢)
static NSArray<NSString *> *kMKNeedLoginErrorCodes = nil;
// 强更 resultCode
static NSString * const kMKForceUpdateResultCode = @"2009006";
static NSString * const kMKAppVersionPath        = @"/app/v3/app/version";

@implementation MKNetworkManager {
    AFHTTPSessionManager *_manager;
    BOOL _isRequestingVersionCheck;
    BOOL _hasShownForceUpdateAlert;
}

+ (void)initialize {
    if (self == [MKNetworkManager class]) {
        kMKNeedLoginErrorCodes = @[@"2000001", @"2000002", @"2002001"];
    }
}

+ (instancetype)sharedManager {
    static MKNetworkManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[MKNetworkManager alloc] initPrivate];
    });
    return mgr;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        _manager = [AFHTTPSessionManager manager];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"text/html", nil];
        _manager.requestSerializer.timeoutInterval = 30.0;

        // 走 MKAppEnvironment 读 Info.plist 的 MKBaseURL, 每个项目改 Info.plist 即可
        self.baseURLString = [MKAppEnvironment baseURL];
    }
    return self;
}

#pragma mark - User-Agent

- (NSString *)buildUserAgent {
    MKCommonParams *cfg = [MKCommonParams shared];
    NSString *osVersion = [UIDevice currentDevice].systemVersion ?: @"";
    NSString *deviceModel = [[UIDevice currentDevice] model] ?: @"iPhone";
    NSString *appId = cfg.appId ?: @"App";
    NSString *appVersion = cfg.appDisplayVersion ?: @"1.0.0";
    return [NSString stringWithFormat:@"%@/%@ (Apple;Mobile;%@;iOS %@)",
            appId, appVersion, deviceModel, osVersion];
}

#pragma mark - Error Code Handling

- (BOOL)shouldNavigateToLoginWithResultCode:(NSString *)resultCode {
    if (!resultCode) return NO;
    return [kMKNeedLoginErrorCodes containsObject:resultCode];
}

- (void)handleNeedLoginError:(NSString *)resultCode {
    NSLog(@"[MKNet] Need re-login, code: %@", resultCode);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self navigateToLoginPage];
    });
}

#pragma mark - Navigation (强更/需重登时找 topVC)

- (void)navigateToLoginPage {
    // 软引用业务 Sign-In VC, 不强 import(模板可单编 Common)
    Class signInClass = NSClassFromString(@"MKSignInViewController");
    if (!signInClass) {
        NSLog(@"[MKNet] MKSignInViewController 类未链接, 跳过 navigateToLoginPage");
        return;
    }
    UIViewController *currentVC = [self topViewController];
    if ([currentVC isKindOfClass:signInClass]) return;

    UIViewController *loginVC = [[signInClass alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginVC];
    navController.navigationBarHidden = YES;
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    if (navController.interactivePopGestureRecognizer) {
        navController.interactivePopGestureRecognizer.enabled = NO;
    }
    [currentVC presentViewController:navController animated:YES completion:nil];
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = nil;
    for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
        if (windowScene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) { keyWindow = window; break; }
            }
        }
    }
    UIViewController *root = keyWindow.rootViewController;
    return [self topViewControllerWithRoot:root];
}

- (UIViewController *)topViewControllerWithRoot:(UIViewController *)root {
    if ([root isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerWithRoot:((UITabBarController *)root).selectedViewController];
    } else if ([root isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerWithRoot:((UINavigationController *)root).visibleViewController];
    } else if (root.presentedViewController) {
        return [self topViewControllerWithRoot:root.presentedViewController];
    }
    return root;
}

#pragma mark - POST

- (void)post:(NSString *)path
      params:(NSDictionary *)params
     success:(MKNetworkSuccess)success
     failure:(MKNetworkFailure)failure {
    [self post:path params:params headers:nil success:success failure:failure];
}

- (void)post:(NSString *)path
      params:(NSDictionary *)params
     headers:(NSDictionary<NSString *, NSString *> *)headers
     success:(MKNetworkSuccess)success
     failure:(MKNetworkFailure)failure {

    NSString *urlString = path;
    if (self.baseURLString.length > 0 && ![path.lowercaseString hasPrefix:@"http"]) {
        urlString = [NSString stringWithFormat:@"%@%@", self.baseURLString, path];
    }

    // UA 每次请求都设
    NSString *ua = [self buildUserAgent];
    [_manager.requestSerializer setValue:ua forHTTPHeaderField:@"User-Agent"];

    if (headers) {
        for (NSString *key in headers) {
            [_manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }

    NSLog(@"[POST] %@", urlString);
    NSLog(@"[Request Body] %@", params);

    __weak typeof(self) wself = self;
    [_manager POST:urlString
        parameters:params
           headers:nil
          progress:nil
           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;

        NSLog(@"[Response] %@", responseObject);

        NSString *resultCode = @"";
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resp = (NSDictionary *)responseObject;
            resultCode = [NSString stringWithFormat:@"%@", resp[@"resultCode"] ?: @""];
            if ([sself shouldNavigateToLoginWithResultCode:resultCode]) {
                [sself handleNeedLoginError:resultCode];
            }
        }

        // 强更: 任意接口 resultCode==2009006 → 拉版本 + 弹强更; 吞掉 success
        if ([resultCode isEqualToString:kMKForceUpdateResultCode]) {
            if (![path isEqualToString:kMKAppVersionPath]) {
                dispatch_async(dispatch_get_main_queue(), ^{ [sself triggerForceUpdateFlow]; });
            } else {
                NSLog(@"[MKNet] %@ 自身返回 2009006, 跳过递归", kMKAppVersionPath);
            }
            return;
        }

        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[Error] %@", error.localizedDescription);
        if (failure) failure(error);
    }];
}

#pragma mark - File Upload

- (void)uploadFile:(NSString *)path
            params:(NSDictionary *)params
          fileData:(NSData *)fileData
          fileName:(NSString *)fileName
          mimeType:(NSString *)mimeType
           headers:(NSDictionary<NSString *, NSString *> *)headers
          progress:(void(^)(NSProgress *progress))progress
           success:(MKNetworkSuccess)success
           failure:(MKNetworkFailure)failure {

    NSString *urlString = path;
    if (self.baseURLString.length > 0 && ![path.lowercaseString hasPrefix:@"http"]) {
        urlString = [NSString stringWithFormat:@"%@%@", self.baseURLString, path];
    }

    AFHTTPSessionManager *uploadManager = [AFHTTPSessionManager manager];
    uploadManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    uploadManager.responseSerializer = [AFJSONResponseSerializer serializer];
    uploadManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", @"text/html", nil];
    uploadManager.requestSerializer.timeoutInterval = 60.0;

    [uploadManager.requestSerializer setValue:[self buildUserAgent] forHTTPHeaderField:@"User-Agent"];
    if (headers) {
        for (NSString *key in headers) {
            [uploadManager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }

    if (!fileName || fileName.length == 0) fileName = @"file";
    if (!mimeType || mimeType.length == 0) mimeType = @"image/jpeg";

    // data 字段是 dict → 序列化成 string 放到 multipart 表单里
    NSMutableDictionary *formParams = [NSMutableDictionary dictionary];
    for (NSString *key in params) {
        id value = params[key];
        if ([key isEqualToString:@"data"] && [value isKindOfClass:[NSDictionary class]]) {
            NSError *err = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&err];
            formParams[key] = (jsonData && !err) ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"{}";
        } else {
            formParams[key] = value;
        }
    }

    NSLog(@"[Upload] %@ size=%lu", urlString, (unsigned long)fileData.length);

    __weak typeof(self) wself = self;
    [uploadManager POST:urlString
             parameters:formParams
                headers:nil
constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:fileData name:@"file" fileName:fileName mimeType:mimeType];
    }
               progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) progress(uploadProgress);
    }
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"[Upload Success] %@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *resultCode = [NSString stringWithFormat:@"%@", responseObject[@"resultCode"] ?: @""];
            if ([wself shouldNavigateToLoginWithResultCode:resultCode]) {
                [wself handleNeedLoginError:resultCode];
            }
        }
        if (success) success(responseObject);
    }
                failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[Upload Error] %@", error.localizedDescription);
        if (failure) failure(error);
    }];
}

#pragma mark - Force Update Flow

- (void)triggerForceUpdateFlow {
    if (_hasShownForceUpdateAlert) return;
    if (_isRequestingVersionCheck) return;
    _isRequestingVersionCheck = YES;

    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [self post:kMKAppVersionPath params:body success:^(id resp) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        sself->_isRequestingVersionCheck = NO;
        MKAppVersionResponse *r = [[MKAppVersionResponse alloc] initWithDictionary:resp];
        if (r.latestForceVersion.length == 0 && r.latestForceVersionContent.length == 0) {
            NSLog(@"[MKNet] 收到 2009006 但 latestForceVersion* 全空, 跳过强更弹窗");
            return;
        }
        [sself showForceUpdateAlertWithResponse:r];
    } failure:^(NSError *e) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        sself->_isRequestingVersionCheck = NO;
        NSLog(@"[MKNet] 强更版本检查失败: %@", e.localizedDescription);
    }];
}

- (void)showForceUpdateAlertWithResponse:(MKAppVersionResponse *)r {
    if (_hasShownForceUpdateAlert) return;
    _hasShownForceUpdateAlert = YES;

    NSString *url = r.latestForceVersionUrl ?: @"";
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeForceUpdate config:nil];
    sheet.onConfirmTapped = ^{
        if (url.length > 0) {
            NSString *target = url;
            NSString *lower = target.lowercaseString;
            if (![lower hasPrefix:@"http://"] && ![lower hasPrefix:@"https://"]) {
                target = [@"https://" stringByAppendingString:target];
            }
            NSURL *u = [NSURL URLWithString:target];
            if (u) [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
        }
    };
    [sheet show];
}

@end
