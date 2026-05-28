//
//  MKRejectWebViewController.h
//  PHI372-DC
//
//  拒量输出 H5 容器。继承 MKWebViewViewController, 加 JS 注入 + ScriptMessageHandler。
//  H5 通过 window.webkit.messageHandlers.native.postMessage("thirdUrl=URL&type=ad")
//  通知原生跳外部浏览器, 原生上报埋点 502。
//

#import "MKWebViewViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKRejectWebViewController : MKWebViewViewController

@end

NS_ASSUME_NONNULL_END
