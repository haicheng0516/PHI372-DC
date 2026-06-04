//
//  MKWebViewViewController.m
//

#import "MKWebViewViewController.h"
#import "MKConstants.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKWebViewViewController () <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, copy) NSString *urlString;
@end

@implementation MKWebViewViewController

- (instancetype)initWithURL:(NSString *)urlString title:(NSString *)title {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleLight;
        self.navTitle = title.length > 0 ? title : @"";
        _urlString = [urlString copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = kColorBackground;
    [self.view addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight);
        make.left.right.bottom.equalTo(self.view);
    }];

    if (self.urlString.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"No URL configured"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (!url) {
        [SVProgressHUD showErrorWithStatus:@"Invalid URL"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [SVProgressHUD show];
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
    [SVProgressHUD dismiss];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:@"Failed to load"];
    [SVProgressHUD dismissWithDelay:1.5];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:@"Failed to load"];
    [SVProgressHUD dismissWithDelay:1.5];
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
