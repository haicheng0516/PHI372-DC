//
//  MKProductApplyViewController.m
//  PHI372-DC
//
//  对齐 259 ProductApplicationController:
//    - selectionMode 由 home 路由时按 amountDetailList.count == 1 决定
//    - 多金额: amount chevron + picker, 切换重置 selectedTermDetail = newAmount.termList[0]
//    - 单金额: amount 静态展示, 不响应点击
//    - term chevron: 永远独立按 当前 amount.termDetailList.count > 1 判断
//

#import "MKProductApplyViewController.h"
#import "MKConstants.h"
#import "NSString+MKAmount.h"
#import "MKLoanInfoCell.h"
#import "MKLoanProductModel.h"
#import "MKProductTermModel.h"
#import "MKPayAccountModel.h"
#import "MKAppConfigManager.h"
#import "MKAppConfigModel.h"
#import "MKToastView.h"
#import "MKBottomSheetView.h"
#import "MKProductSuccessViewController.h"
#import "MKDataCaptureViewController.h"
#import "MKWebViewViewController.h"
#import "MKKYCBankCardEditViewController.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKSeamlessOrderManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKProductApplyViewController () <UITableViewDataSource, UITableViewDelegate, MKSeamlessOrderManagerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) MKLoanInfoCell *infoCell;

@property (nonatomic, strong, nullable) MKAmountDetailModel *selectedAmountDetail;
@property (nonatomic, strong, nullable) MKTermDetailModel *selectedTermDetail;
@property (nonatomic, strong, nullable) MKPayAccountModel *selectedAccount;

/// 多金额时: 按 loanAmount 从大到小排序后的 amount list (对齐 259 line 294-303)
/// 单金额时: 不使用
@property (nonatomic, strong) NSArray<MKAmountDetailModel *> *sortedAmounts;

@property (nonatomic, strong) NSArray<MKPayAccountModel *> *cards;

/// 数据抓取蒙层 (通讯录上传期间 modal overlay)
@property (nonatomic, strong, nullable) MKDataCaptureViewController *dataCaptureVC;
@end

@implementation MKProductApplyViewController

- (instancetype)init {
    return [self initWithTermData:nil mode:MKLoanAmountSelectionModeSingle];
}

- (instancetype)initWithTermData:(MKProductTermDataModel *)termData
                            mode:(MKLoanAmountSelectionMode)mode {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleLight;
        self.navTitle = @"Loan details";
        _termData = termData;
        _selectionMode = mode;
        [self resolveDefaultSelection];
    }
    return self;
}

/// 对齐 259 initializeAmountSelectionMode: 默认 amount = 最大, term = 该 amount termList[0]
- (void)resolveDefaultSelection {
    if (!self.termData) return;
    if (self.selectionMode == MKLoanAmountSelectionModeMultiple) {
        self.sortedAmounts = [self.termData sortedAmountDetailList];
        self.selectedAmountDetail = self.sortedAmounts.firstObject;
    } else {
        self.selectedAmountDetail = self.termData.amountDetailList.firstObject;
    }
    self.selectedTermDetail = self.selectedAmountDetail.termDetailList.firstObject;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestPayAccountList];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = kColorBackground;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self.tableView registerClass:[MKLoanInfoCell class] forCellReuseIdentifier:@"info"];
}

#pragma mark - DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MKLoanInfoCell *c = [tableView dequeueReusableCellWithIdentifier:@"info" forIndexPath:indexPath];
    self.infoCell = c;
    [c configureWithProduct:[self currentProductModel]];
    __weak typeof(self) wself = self;
    c.onAmountSubLabelTapped = ^(UIView *anchor) {
        [MKToastView showText:@"Calculated based on your loan amount, loan term, and the interest rate of the current product."];
    };
    c.onTermCapsuleTapped = ^{ [wself showTermPickerSheet]; };
    // 多金额才注册 amount picker handler
    if (self.selectionMode == MKLoanAmountSelectionModeMultiple) {
        c.onAmountChevronTapped = ^{ [wself showAmountPickerSheet]; };
    }
    c.onAccountTapped = ^{ [wself bankAccountAction]; };
    c.onAmountInfoTapped = ^(NSInteger row, UIView *anchor) {
        NSArray *tips = @[
            @"This is the amount you will receive after deduction of interest and service fee.",
            @"Interest is calculated based on your loan amount, loan term, and the interest rate of the current product.",
            @"A one-time service fee for processing your application."
        ];
        if (row < tips.count) { [MKToastView showText:tips[row]]; }
    };
    c.onRepaymentPlanTapped = ^{ [wself showRepaymentPlanSheet]; };
    c.onTermsLinkTapped = ^{ [wself pushTermsWebView]; };
    c.onApplyTapped = ^{ [wself applyAction]; };
    return c;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [MKLoanInfoCell cellHeight];
}

#pragma mark - Model

- (MKLoanProductModel *)currentProductModel {
    MKLoanProductModel *m;
    if (self.termData && self.selectedAmountDetail && self.selectedTermDetail) {
        m = [MKLoanProductModel modelFromTermData:self.termData
                                     amountDetail:self.selectedAmountDetail
                                       termDetail:self.selectedTermDetail];
    } else {
        m = (self.selectionMode == MKLoanAmountSelectionModeMultiple)
            ? [MKLoanProductModel mockMultiAmount]
            : [MKLoanProductModel mockSingleAmount];
    }
    // isMultiAmount 来自 selectionMode (覆盖工厂方法默认的 termData.isMultiAmount)
    m.isMultiAmount = (self.selectionMode == MKLoanAmountSelectionModeMultiple);
    m.bankAccount = self.selectedAccount.displayName;
    return m;
}

#pragma mark - /payAccountInfo/list

- (void)requestPayAccountList {
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/payAccountInfo/list"
                                    params:body
                                   success:^(id resp) {
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            NSDictionary *data = resp[@"data"];
            NSArray *list = [data isKindOfClass:[NSDictionary class]] ? data[@"payAccountInfoList"] : nil;
            wself.cards = [MKPayAccountModel modelsFromList:list];
            MKPayAccountModel *defaultCard = nil;
            for (MKPayAccountModel *c in wself.cards) {
                if (c.defaultFlag) { defaultCard = c; break; }
            }
            if (!defaultCard) defaultCard = wself.cards.firstObject;
            wself.selectedAccount = defaultCard;
            [wself.tableView reloadData];
        }
    } failure:^(NSError *e) { /* 静默 */ }];
}

#pragma mark - Pickers

- (void)showAmountPickerSheet {
    if (self.sortedAmounts.count == 0) return;
    NSMutableArray *titles = [NSMutableArray array];
    NSInteger currentIdx = 0;
    for (NSInteger i = 0; i < self.sortedAmounts.count; i++) {
        MKAmountDetailModel *a = self.sortedAmounts[i];
        [titles addObject:[a displayAmountText]];
        if (a == self.selectedAmountDetail) currentIdx = i;
    }
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeCommonPicker
                                                          config:@{ @"title": @"Loan Amount",
                                                                    @"items": titles,
                                                                    @"selectedIndex": @(currentIdx) }];
    __weak typeof(self) wself = self;
    sheet.onSelected = ^(NSInteger idx, id value) {
        if (idx < wself.sortedAmounts.count) {
            wself.selectedAmountDetail = wself.sortedAmounts[idx];
            // 对齐 259 line 467-469: 切金额自动重置到该 amount 的 termList[0]
            wself.selectedTermDetail = wself.selectedAmountDetail.termDetailList.firstObject;
            [wself.tableView reloadData];
        }
    };
    [sheet show];
}

- (void)showTermPickerSheet {
    NSArray<MKTermDetailModel *> *terms = self.selectedAmountDetail.termDetailList;
    if (terms.count <= 1) return;   // 对齐 259 line 700-702
    NSMutableArray *titles = [NSMutableArray array];
    NSInteger currentIdx = 0;
    for (NSInteger i = 0; i < terms.count; i++) {
        [titles addObject:[terms[i] displayTermText]];
        if (terms[i] == self.selectedTermDetail) currentIdx = i;
    }
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeCommonPicker
                                                          config:@{ @"title": @"Loan Tenure",
                                                                    @"items": titles,
                                                                    @"selectedIndex": @(currentIdx) }];
    __weak typeof(self) wself = self;
    sheet.onSelected = ^(NSInteger idx, id value) {
        if (idx < terms.count) {
            wself.selectedTermDetail = terms[idx];
            [wself.tableView reloadData];
        }
    };
    [sheet show];
}

#pragma mark - Bank Account

- (void)bankAccountAction {
    // 对齐 259 line 505-510: 无卡 → 直跳加卡页
    if (self.cards.count == 0) {
        [self pushBankCardEditPage];
        return;
    }
    NSMutableArray *titles = [NSMutableArray array];
    for (MKPayAccountModel *c in self.cards) [titles addObject:c.displayName ?: @"Bank account"];
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeBankCardSelect
                                                          config:@{ @"items": titles }];
    __weak typeof(self) wself = self;
    sheet.onSelected = ^(NSInteger idx, id value) {
        if (idx < wself.cards.count) {
            wself.selectedAccount = wself.cards[idx];
            [wself.tableView reloadData];
        }
    };
    sheet.onConfirmTapped = ^{ [wself pushBankCardEditPage]; };
    [sheet show];
}

- (void)pushBankCardEditPage {
    MKKYCBankCardEditViewController *vc = [[MKKYCBankCardEditViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushTermsWebView {
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.conditionsHref;
    if (url.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"Terms link not configured"];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }
    MKWebViewViewController *vc = [[MKWebViewViewController alloc] initWithURL:url title:@"Terms of the loans"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showRepaymentPlanSheet {
    // ISO 日期 "2026-05-31" → Pencil 风格 "May 31, 2026"
    static NSDateFormatter *isoFmt;
    static NSDateFormatter *prettyFmt;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        isoFmt = [NSDateFormatter new];
        isoFmt.dateFormat = @"yyyy-MM-dd";
        isoFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        prettyFmt = [NSDateFormatter new];
        prettyFmt.dateFormat = @"MMM dd, yyyy";
        prettyFmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
    NSMutableArray *plans = [NSMutableArray array];
    for (MKProductTermItemModel *item in self.selectedTermDetail.productTermItemList) {
        NSString *dateStr = item.expirationDate ?: @"";
        NSDate *d = [isoFmt dateFromString:dateStr];
        if (d) dateStr = [prettyFmt stringFromDate:d];
        [plans addObject:@{
            @"date": dateStr.length > 0 ? dateStr : @"--",
            @"amount":    [item.repaymentAmount     mk_formattedPesoAmount] ?: @"--",
            @"principal": [item.principalAmountDue  mk_formattedPesoAmount] ?: @"--",
            @"interest":  [item.interestAmountDue   mk_formattedPesoAmount] ?: @"--",
        }];
    }
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeRepaymentPlan
                                                          config:@{ @"plans": plans }];
    [sheet show];
}

- (void)applyAction {
    if (!self.infoCell.termsAccepted) {
        [SVProgressHUD showErrorWithStatus:@"Please agree to the terms and conditions"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }
    if (!self.selectedAccount) {
        [SVProgressHUD showErrorWithStatus:@"Please add a receiving account"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }
    if (!self.termData || !self.selectedAmountDetail || !self.selectedTermDetail) {
        [SVProgressHUD showErrorWithStatus:@"Loan info incomplete, please retry"];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }

    MKSeamlessOrderParams *params = [MKSeamlessOrderParams new];
    params.productId          = self.termData.productId;
    params.selectedAmount     = self.selectedAmountDetail.loanAmount;
    params.selectedShowTerm   = self.selectedTermDetail.showTerm;
    params.bankCardBindId     = self.selectedAccount.bankCardBindId;
    params.termResponseData   = self.termData.originalDictionary;

    [SVProgressHUD showWithStatus:@"Submitting..."];
    MKSeamlessOrderManager *mgr = [MKSeamlessOrderManager sharedManager];
    mgr.delegate = self;
    [mgr startSeamlessOrderWithParams:params];
}

#pragma mark - MKSeamlessOrderManagerDelegate
//  对齐 259 ProductApplicationController:
//    - fail / shouldShowMessage 静默 (不弹错误, 与首页保持一致)
//    - 用户取消定位 → 只关 HUD, 不返回, 让用户重试
//    - 用户取消通讯录 / 取消整个流程 → 关 HUD + pop 返回
//    - 通讯录上传中显示 MKDataCaptureViewController, 流程完成弹 Success 模态

- (void)seamlessOrderManager:(id)manager didSubmitOrderSuccess:(NSString *)orderId {
    [SVProgressHUD showWithStatus:@"Processing..."];
}

- (void)seamlessOrderManager:(id)manager didUpdateContactUploadProgress:(NSInteger)progress {
    [SVProgressHUD dismiss];
    if (!self.dataCaptureVC) {
        self.dataCaptureVC = [[MKDataCaptureViewController alloc] init];
        self.dataCaptureVC.progress = progress;
        [self presentViewController:self.dataCaptureVC animated:YES completion:nil];
    } else {
        [self.dataCaptureVC setProgress:progress animated:YES];
    }
}

- (void)seamlessOrderManager:(id)manager didCompleteWithOrderId:(NSString *)orderId {
    [SVProgressHUD dismiss];
    void (^showSuccess)(void) = ^{
        MKProductSuccessViewController *succ = [[MKProductSuccessViewController alloc] init];
        [self presentViewController:succ animated:YES completion:nil];
    };
    if (self.dataCaptureVC) {
        [self.dataCaptureVC dismissViewControllerAnimated:YES completion:^{
            self.dataCaptureVC = nil;
            showSuccess();
        }];
    } else {
        showSuccess();
    }
}

- (void)seamlessOrderManager:(id)manager didFailWithError:(NSError *)error {
    [SVProgressHUD dismiss];
    if (self.dataCaptureVC) {
        [self.dataCaptureVC dismissViewControllerAnimated:YES completion:nil];
        self.dataCaptureVC = nil;
    }
}
- (void)seamlessOrderManager:(id)manager shouldShowMessage:(NSString *)message {
    // 与 259 保持一致: 不做处理
}
- (void)seamlessOrderManagerDidCancel:(id)manager {
    [SVProgressHUD dismiss];
    if (self.dataCaptureVC) {
        [self.dataCaptureVC dismissViewControllerAnimated:YES completion:nil];
        self.dataCaptureVC = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)seamlessOrderManagerDidCancelLocationPermission:(id)manager {
    [SVProgressHUD dismiss];
}
- (void)seamlessOrderManagerDidCancelContactsPermission:(id)manager {
    [SVProgressHUD dismiss];
    if (self.dataCaptureVC) {
        [self.dataCaptureVC dismissViewControllerAnimated:YES completion:nil];
        self.dataCaptureVC = nil;
    }
}

@end
