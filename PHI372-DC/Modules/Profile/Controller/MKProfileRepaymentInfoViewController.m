//
//  MKProfileRepaymentInfoViewController.m
//  PHI372-DC — Figma 3:1296 还款须知
//
//  hint banner + 2 contact rows + 一个大文档卡 (3 段落)
//

#import "MKProfileRepaymentInfoViewController.h"

@implementation MKProfileRepaymentInfoViewController

- (instancetype)init {
    NSArray *items = @[
        [MKDocPageItem hintWithText:@"For the safety of your funds, please read the repayment instructions carefully before proceeding with repayment."],
        [MKDocPageItem websiteWithURL:@"https://bj.XXX.xXX"],
        [MKDocPageItem emailWithAddress:@"XXcash@Hotmail.com"],
        [MKDocPageItem docWithSectionTitle:nil
                                      body:@"When making repayments, we kindly request you to first use the app to obtain the repayment link or reference number. Repayment through unofficial channels may not be credited correctly.\n\nIf someone contacts you to split the total repayment amount into multiple payments or to repay via private accounts, please do not comply. All payments must go through the official repayment channels listed in the app.\n\nIf you encounter any suspicious situations during the repayment process, please contact our customer service immediately through the official website or email above."],
    ];
    return [super initWithTitle:@"Repayment Instructions" items:items];
}

@end
