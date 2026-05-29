//
//  MKRejectWebViewController.h
//
//  拒量输出 H5 容器。继承 MKBaseViewController, 自建 WKWebView + ScriptMessageHandler。
//  H5 通过 window.webkit.messageHandlers.native.postMessage("thirdUrl=URL&type=ad")
//  通知原生跳外部浏览器, 原生上报埋点 502。
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKRejectWebViewController : MKBaseViewController

- (instancetype)initWithURL:(nullable NSString *)urlString title:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
