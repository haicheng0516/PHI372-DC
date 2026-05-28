//
//  MKRejectFlowCoordinator.m
//  PHI372-DC
//

#import "MKRejectFlowCoordinator.h"
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKRejectWebViewController.h"
#import <UIKit/UIKit.h>

@implementation MKRejectFlowCoordinator

+ (BOOL)shouldTriggerRejectFlow {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.rejectH5;
    return url.length > 0;
}

+ (void)presentRejectH5FromVC:(UIViewController *)host {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.rejectH5;
    if (url.length == 0 || !host.navigationController) return;

    MKRejectWebViewController *web = [[MKRejectWebViewController alloc] initWithURL:url title:nil];
    [host.navigationController pushViewController:web animated:YES];
}

@end
