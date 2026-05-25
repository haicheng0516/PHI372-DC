//
//  MKToastView.m
//  PHI372-DC
//

#import "MKToastView.h"
#import "MKConstants.h"

@implementation MKToastView

+ (void)showText:(NSString *)text {
    [self showText:text duration:2.5];
}

+ (void)showText:(NSString *)text duration:(NSTimeInterval)duration {
    if (text.length == 0) return;

    UIWindow *host = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { host = w; break; }
                }
                if (host) break;
            }
        }
    }
    if (!host) host = [UIApplication sharedApplication].windows.firstObject;
    if (!host) return;

    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    container.layer.cornerRadius = kScaleH(19);
    container.layer.masksToBounds = YES;
    container.alpha = 0;
    [host addSubview:container];

    UILabel *label = [UILabel new];
    label.text = text;
    label.font = kFontRegular(14);
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [container addSubview:label];

    // 测量
    CGFloat maxW = host.bounds.size.width - kScaleW(56) * 2;
    CGSize fit = [label sizeThatFits:CGSizeMake(maxW - kScaleW(14), CGFLOAT_MAX)];
    CGSize containerSize = CGSizeMake(MIN(maxW, fit.width + kScaleW(28)), fit.height + kScaleH(26));
    CGFloat x = (host.bounds.size.width - containerSize.width) * 0.5;
    CGFloat y = (host.bounds.size.height - containerSize.height) * 0.5;
    container.frame = CGRectMake(x, y, containerSize.width, containerSize.height);
    label.frame = CGRectMake(kScaleW(14), kScaleH(13), containerSize.width - kScaleW(28), fit.height);

    [UIView animateWithDuration:0.22 animations:^{
        container.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.22 animations:^{
                container.alpha = 0;
            } completion:^(BOOL finished2) {
                [container removeFromSuperview];
            }];
        });
    }];
}

@end
