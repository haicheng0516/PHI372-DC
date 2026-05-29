//
//  MKProfileRepaymentInfoViewController.m
//  Figma 3:1296 还款须知
//
//  hint banner + 2 contact rows + 一个大文档卡 (3 段落)。网址/邮箱来自 app/config
//

#import "MKProfileRepaymentInfoViewController.h"
#import "MKAppConfigManager.h"

@implementation MKProfileRepaymentInfoViewController

- (instancetype)init {
    return [super initWithTitle:@"Repayment Instructions" items:@[]];
}

- (void)viewDidLoad {
    self.items = [self buildItems];
    [super viewDidLoad];
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
        [MKDocPageItem hintWithText:@"For the safety of your funds, please read the repayment instructions carefully before proceeding with repayment."],
        [MKDocPageItem websiteWithURL:cfg.officialWebsiteUrl ?: @""],
        [MKDocPageItem emailWithAddress:cfg.appEmail ?: @""],
        [MKDocPageItem docWithSectionTitle:nil
                                      body:@"When making repayments, we kindly request you to first use the app to obtain the repayment link or reference number. Repayment through unofficial channels may not be credited correctly.\n\nIf someone contacts you to split the total repayment amount into multiple payments or to repay via private accounts, please do not comply. All payments must go through the official repayment channels listed in the app.\n\nIf you encounter any suspicious situations during the repayment process, please contact our customer service immediately through the official website or email above."],
    ];
}

@end
