//
//  MKProductSuccessViewController.m
//  PHI372-DC — Figma 3:1394 产品申请-申请成功
//
//  使用通用 MKResultView (Se_success icon + Success! + 副标题 + Confirm)
//

#import "MKProductSuccessViewController.h"
#import "MKConstants.h"
#import "MKResultView.h"
#import "MKHomeViewController.h"
#import "MKNavigationController.h"
#import <Masonry/Masonry.h>

@implementation MKProductSuccessViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    MKResultView *r = [[MKResultView alloc] initWithKind:MKResultKindSuccess
                                                    title:@"Success!"
                                                 subtitle:@"Your application is under review. Once approved, the money will be credited to your bank account."
                                             primaryTitle:@"Confirm"
                                           secondaryTitle:nil];
    __weak typeof(self) wself = self;
    r.onPrimaryTapped = ^{ [wself backToHome]; };
    [self.view addSubview:r];
    [r mas_makeConstraints:^(MASConstraintMaker *m) { m.edges.equalTo(self.view); }];
}

- (void)backToHome {
    MKHomeViewController *home = [[MKHomeViewController alloc] init];
    MKNavigationController *nav = [[MKNavigationController alloc] initWithRootViewController:home];
    UIWindow *win = self.view.window;
    [UIView transitionWithView:win duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ win.rootViewController = nav; }
                    completion:nil];
}

@end
