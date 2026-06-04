//
//  MKRejectWebViewController.m
//

#import "MKRejectWebViewController.h"
#import <WebKit/WebKit.h>
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKLoginManager.h"
#import "MKCommonParams.h"
#import "MKNetworkManager.h"
#import "MKEventTrackingService.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

/// H5 ScriptMessage 名。H5 联调时需确认与前端约定值一致(占位 native)。
static NSString * const kRejectScriptMessageName = @"native";

@interface MKRejectWebViewController () <WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>
@property (nonatomic, strong) WKWebView *rejectWebView;
@property (nonatomic, strong) WKUserContentController *userContentController;
@property (nonatomic, copy)   NSString  *rejectURLString;
@end

@implementation MKRejectWebViewController

- (instancetype)initWithURL:(nullable NSString *)urlString title:(nullable NSString *)title {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleLight;
        self.navTitle = title.length > 0 ? title : @"";
        _rejectURLString = [urlString copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self setupRejectWebView];
    [self loadRejectURL];
}

- (void)setupRejectWebView {
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    self.userContentController = [[WKUserContentController alloc] init];
    [self.userContentController addScriptMessageHandler:self name:kRejectScriptMessageName];
    cfg.userContentController = self.userContentController;

    self.rejectWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.rejectWebView.navigationDelegate = self;
    self.rejectWebView.UIDelegate = self;
    self.rejectWebView.backgroundColor = [UIColor whiteColor];
    self.rejectWebView.opaque = NO;
    [self.view addSubview:self.rejectWebView];
    [self.rejectWebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)loadRejectURL {
    if (self.rejectURLString.length == 0) return;
    NSURL *url = [NSURL URLWithString:self.rejectURLString];
    if (!url) return;
    [self.rejectWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - WKNavigationDelegate

// 拦截非 http(s) scheme (tel: / mailto: / whatsapp: / gcash: 等), 交给系统打开
- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (!url) { decisionHandler(WKNavigationActionPolicyCancel); return; }
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"about"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"Please install the app first"];
            });
        }
    }];
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView != self.rejectWebView) return;
    [self injectRejectData];
}

- (void)injectRejectData {
    MKLoginManager *lm  = [MKLoginManager sharedManager];
    MKCommonParams *cp  = [MKCommonParams shared];

    NSDictionary *payload = @{
        @"appId":   cp.appId    ?: @"",
        @"salt":    cp.salt     ?: @"",
        @"mobile":  lm.mobile   ?: @"",
        @"userId":  lm.userId   ?: @"",
        @"token":   lm.token    ?: @"",
        @"baseUrl": [MKNetworkManager sharedManager].baseURLString ?: @"",
    };

    NSError *err = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
    if (err || !json) return;

    NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSString *safe = [self sanitizeJSONString:jsonString];
    NSString *jsCode = [NSString stringWithFormat:@"rejectData('%@')", safe];

    [self.rejectWebView evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[Reject] rejectData inject failed: %@", error);
        }
    }];
}

/// 转义反斜杠、单引号、换行/回车,避免破坏外层 'json' 字面量。
- (NSString *)sanitizeJSONString:(NSString *)s {
    NSString *r = [s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    r = [r stringByReplacingOccurrencesOfString:@"'"  withString:@"\\'"];
    r = [r stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    r = [r stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    return r;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kRejectScriptMessageName]) return;
    NSString *body = [message.body isKindOfClass:[NSString class]] ? (NSString *)message.body : [message.body description];
    if (![body hasPrefix:@"thirdUrl="]) return;

    // 协议: "thirdUrl=URL&type=TYPE", 按 & 分项后取首项的 thirdUrl= 值,
    // 不用全局替换"type="(URL 自身可能含 type 查询参数, 会被误删)
    NSArray<NSString *> *parts = [body componentsSeparatedByString:@"&"];
    NSString *firstPart = parts.firstObject;
    if (![firstPart hasPrefix:@"thirdUrl="]) return;
    NSString *urlString = [firstPart substringFromIndex:@"thirdUrl=".length];
    if (urlString.length == 0) return;

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;

    [MKEventTrackingService recordEventWithCode:@"502"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 在 VC 消失时主动 remove, 避免依赖 dealloc(此时 webView 可能已被 ARC 提前释放)
    [self.userContentController removeScriptMessageHandlerForName:kRejectScriptMessageName];
}

#pragma mark - WKUIDelegate (JS alert/confirm/prompt → 原生 alert)

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *_){ completionHandler(); }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction *_){ completionHandler(NO); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *_){ completionHandler(YES); }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
defaultText:(NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil
                                                                message:prompt
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.text = defaultText; }];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                        handler:^(UIAlertAction *_){ completionHandler(nil); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *_){ completionHandler(a.textFields.firstObject.text); }]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
