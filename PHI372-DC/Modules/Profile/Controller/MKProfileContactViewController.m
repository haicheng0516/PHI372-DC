//
//  MKProfileContactViewController.m
//  Figma 3:1281 联系我们
//
//  hint banner + website row + email row(网址/邮箱来自 app/config)
//

#import "MKProfileContactViewController.h"
#import "MKAppConfigManager.h"

@implementation MKProfileContactViewController

- (instancetype)init {
    return [super initWithTitle:@"Contact Us" items:@[]];
}

- (void)viewDidLoad {
    self.items = [self buildItems];
    [super viewDidLoad];
    // 配置未就绪 → 拉取后刷新网址/邮箱
    if (![[MKAppConfigManager sharedManager] hasAppConfig]) {
        __weak typeof(self) wself = self;
        [[MKAppConfigManager sharedManager] loadConfigWithCompletion:^(MKAppConfigModel *config) {
            wself.items = [wself buildItems];
            [wself reloadDocItems];
        }];
    }
}

- (NSArray *)buildItems {
    MKAppConfigModel *cfg = [MKAppConfigManager sharedManager].currentAppConfig;
    return @[
        [MKDocPageItem hintWithText:@"If you have any questions, please save the proof and contact customer service."],
        [MKDocPageItem websiteWithURL:cfg.officialWebsiteUrl ?: @""],
        [MKDocPageItem emailWithAddress:cfg.appEmail ?: @""],
    ];
}

@end
