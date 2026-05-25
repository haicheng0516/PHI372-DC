//  MKProfileAgreementViewController.m
//  N 个灰底 Doc 卡 (含 "Article N" 小节标题 + 段落)

#import "MKProfileAgreementViewController.h"

@implementation MKProfileAgreementViewController

- (instancetype)init {
    NSArray *items = @[
        [MKDocPageItem docWithSectionTitle:@"Article 1"
                                      body:@"Maximum Annual Percentage Rate: 32.8%.\n\nFor example, for a loan with a term of 90 days at the maximum APR, the total interest payable would be calculated based on the daily rate of 0.08% applied to the outstanding balance."],
        [MKDocPageItem docWithSectionTitle:@"Article 2"
                                      body:@"We offer the following loan services:\n\nLoan Amount: Up to 50,000 Pesos.\nLoan Term: 90 days to 360 days.\nService Fee: 100-400 Pesos.\nDaily Interest Rate: 0.08%.\nAll fees are clearly disclosed during application and are subject to the latest agreement signed at the time of borrowing."],
    ];
    return [super initWithTitle:@"Terms Of The Loans" items:items];
}

@end
