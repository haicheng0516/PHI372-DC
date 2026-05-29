//
//  MKWebViewViewController.m
//

#import "MKWebViewViewController.h"
#import "MKConstants.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKWebViewViewController () <WKNavigationDelegate>
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

@end
