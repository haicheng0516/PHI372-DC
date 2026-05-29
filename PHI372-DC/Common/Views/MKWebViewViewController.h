//
//  MKWebViewViewController.h
//
//  通用 WKWebView 容器, 用于展示协议链接 / 隐私政策 / 客服等外部内容.
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKWebViewViewController : MKBaseViewController

- (instancetype)initWithURL:(nullable NSString *)urlString title:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
