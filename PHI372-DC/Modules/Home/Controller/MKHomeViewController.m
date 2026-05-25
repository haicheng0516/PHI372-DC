//
//  MKHomeViewController.m
//  PHI372-DC
//
//  对齐 334 RDHomeViewController:
//   - viewWillAppear 触发 5 个 API: version + config + suphome + product/list + user/info
//   - userStatus==10 → 显示装饰图 + sticky Apply Now; 否则显示产品列表
//   - 弹窗优先级队列: ForceUpdate > WithdrawPending > ReloanTip
//

#import "MKHomeViewController.h"
#import "MKConstants.h"
#import "MKHomeHeaderView.h"
#import "MKHomeFooterView.h"
#import "MKHomeNoticeCell.h"
#import "MKHomeDecorationCell.h"
#import "MKHomeProductCell.h"
#import "MKHomeKYCTipCardView.h"
#import "MKOrderListViewController.h"
#import "MKOrderDetailViewController.h"
#import "NSString+MKAmount.h"
#import "MKProductStateResponse.h"
#import "MKReloanFlowHandler.h"
#import "MKSeamlessOrderManager.h"
#import "MKHomeBankCardViewController.h"
#import "MKProfileViewController.h"
#import "MKProfileContactViewController.h"
#import "MKKYCIDViewController.h"
#import "MKKYCPersonalViewController.h"
#import "MKKYCFinanceViewController.h"
#import "MKKYCContactViewController.h"
#import "MKProductApplyViewController.h"
#import "MKProductTermModel.h"
#import "MKBottomSheetView.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKLoginManager.h"
#import "MKHomeResponse.h"
#import "MKProductInfoModel.h"
#import "MKAppConfigModel.h"
#import "MKAppConfigManager.h"
#import "MKAppVersionResponse.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>

static BOOL sHasShownUpdateAlertThisLaunch = NO;
static BOOL sHasShownReloanTipThisLaunch = NO;

@interface MKHomeViewController () <UITableViewDataSource, UITableViewDelegate, MKReloanFlowHandlerDelegate, MKSeamlessOrderManagerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MKHomeHeaderView *headerView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *applyButton;

// 数据
@property (nonatomic, strong, nullable) MKHomeDataModel *homeData;
@property (nonatomic, copy) NSArray<MKProductInfoModel *> *productList;
@property (nonatomic, assign) BOOL showEmpty;             // userStatus == 10
@property (nonatomic, assign) BOOL isRequestingKYCStatus;
@property (nonatomic, assign) BOOL isRequestingProductTerm;

// 弹窗队列
@property (nonatomic, assign) BOOL isVersionCheckCompleted;
@property (nonatomic, assign) BOOL isShowingNormalUpdateAlert;
@property (nonatomic, assign) BOOL isShowingWithdrawalAlert;
@property (nonatomic, assign) BOOL isCheckingReloanTip;
@property (nonatomic, assign) BOOL hasViewDisappeared;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *pendingAlertQueue;

// 复借: handler 管理 seamless order, 当前 reloan sheet 引用
@property (nonatomic, strong, nullable) MKReloanFlowHandler *reloanHandler;
@property (nonatomic, strong, nullable) MKBottomSheetView *currentReloanSheet;
@end

@implementation MKHomeViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
        _showEmpty = YES;                       // 默认显示 empty 直到 suphome 返回
        _productList = @[];
        _pendingAlertQueue = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self setupBottomBar];
    [self setupTableView];
    [self refreshBottomBarVisibility];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isShowingWithdrawalAlert = NO;
    self.isShowingNormalUpdateAlert = NO;
    self.isVersionCheckCompleted = NO;
    self.hasViewDisappeared = NO;
    [self.pendingAlertQueue removeAllObjects];

    [self requestAppVersion];
    [self requestAppConfig];
    [self requestHomeData];
    [self requestProductList];
    [self requestUserInfo];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.hasViewDisappeared = YES;
}

#pragma mark - UI

- (void)setupBottomBar {
    self.bottomBar = [UIView new];
    self.bottomBar.backgroundColor = kColorBackground;
    [self.view addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(kScaleH(86));
    }];

    self.applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.applyButton.backgroundColor = kColorPrimary;
    self.applyButton.layer.cornerRadius = kScaleH(28);
    [self.applyButton setTitle:@"Apply Now" forState:UIControlStateNormal];
    [self.applyButton setTitleColor:kColorWhite forState:UIControlStateNormal];
    self.applyButton.titleLabel.font = kFontButtonLarge;
    [self.applyButton addTarget:self action:@selector(applyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.applyButton];
    [self.applyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomBar).offset(kScaleW(36));
        make.right.equalTo(self.bottomBar).offset(-kScaleW(36));
        make.top.equalTo(self.bottomBar);
        make.height.mas_equalTo(kScaleH(56));
    }];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = kColorBackground;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) self.tableView.sectionHeaderTopPadding = 0;
    [MKHomeNoticeCell registerForTableView:self.tableView];
    [MKHomeDecorationCell registerForTableView:self.tableView];
    [MKHomeProductCell registerForTableView:self.tableView];
    [self.view insertSubview:self.tableView belowSubview:self.bottomBar];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.bottomBar.mas_top);
    }];

    self.headerView = [[MKHomeHeaderView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, [MKHomeHeaderView height])];
    __weak typeof(self) wself = self;
    self.headerView.onIconTapped = ^(MKHomeIconKind kind) {
        UIViewController *next = nil;
        switch (kind) {
            case MKHomeIconKindBank:    next = [MKHomeBankCardViewController new]; break;
            case MKHomeIconKindOrder:   next = [MKOrderListViewController new]; break;
            case MKHomeIconKindContact: next = [MKProfileContactViewController new]; break;
            case MKHomeIconKindMe:      next = [MKProfileViewController new]; break;
        }
        if (next) [wself.navigationController pushViewController:next animated:YES];
    };
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = [[MKHomeFooterView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, [MKHomeFooterView height])];
}

- (void)refreshBottomBarVisibility {
    self.bottomBar.hidden = !self.showEmpty;
    [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(self.showEmpty ? kScaleH(86) : 0);
    }];
}

#pragma mark - 弹窗队列

- (void)enqueueAlert:(dispatch_block_t)block {
    [self.pendingAlertQueue addObject:[block copy]];
}

- (void)flushPendingAlertsIfNeeded {
    if (!self.isVersionCheckCompleted) return;
    if (self.isShowingNormalUpdateAlert) return;
    if (self.isShowingWithdrawalAlert) return;
    if (self.pendingAlertQueue.count == 0) return;
    dispatch_block_t b = self.pendingAlertQueue.firstObject;
    [self.pendingAlertQueue removeObjectAtIndex:0];
    if (b) b();
}

#pragma mark - API 1: 版本检查

- (void)requestAppVersion {
    if (sHasShownUpdateAlertThisLaunch) {
        self.isVersionCheckCompleted = YES;
        [self flushPendingAlertsIfNeeded];
        return;
    }
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/app/version"
                                    params:body
                                   success:^(id resp) {
        MKAppVersionResponse *r = [[MKAppVersionResponse alloc] initWithDictionary:resp];
        // Home 只处理"普通新版本提示" (latestVersion 字段, 用户可 Cancel).
        // 强更链路 (latestForceVersion 字段) 由 MKNetworkManager 拦截 resultCode==2009006 后触发, 不在 Home 这条路径里.
        if ([r isSuccess] && r.latestVersion.length > 0 && [wself needUpdateToVersion:r.latestVersion]) {
            sHasShownUpdateAlertThisLaunch = YES;
            [wself showNormalUpdateAlertWithContent:r.latestVersionContent url:r.latestVersionUrl];
        } else {
            wself.isVersionCheckCompleted = YES;
            [wself flushPendingAlertsIfNeeded];
        }
    } failure:^(NSError *error) {
        wself.isVersionCheckCompleted = YES;
        [wself flushPendingAlertsIfNeeded];
    }];
}

- (BOOL)needUpdateToVersion:(NSString *)latestVersion {
    NSString *cur = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0";
    return ([cur compare:latestVersion options:NSNumericSearch] == NSOrderedAscending);
}

- (void)showNormalUpdateAlertWithContent:(NSString *)content url:(NSString *)url {
    self.isShowingNormalUpdateAlert = YES;
    self.isVersionCheckCompleted = YES;
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeNormalUpdate config:nil];
    __weak typeof(self) wself = self;
    sheet.onConfirmTapped = ^{
        wself.isShowingNormalUpdateAlert = NO;
        if (url.length > 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
        }
        [wself flushPendingAlertsIfNeeded];
    };
    sheet.onCancelTapped = ^{
        wself.isShowingNormalUpdateAlert = NO;
        [wself flushPendingAlertsIfNeeded];
    };
    [sheet show];
}

#pragma mark - API 2: App Config

- (void)requestAppConfig {
    NSMutableDictionary *body = [[[MKEncryptManager sharedManager] generateRequestBody:@{}] mutableCopy];
    body[@"merchantId"] = @"phi372-dc";   // TODO: 用户后续给真实商户号则替换
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/app/config"
                                    params:body
                                   success:^(id resp) {
        NSLog(@"[Home] app/config raw=%@", resp);
        if ([resp isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = resp[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                MKAppConfigModel *cfg = [MKAppConfigModel modelWithDictionary:data];
                [MKAppConfigManager sharedManager].currentAppConfig = cfg;
                NSLog(@"[Home] fjtip=%@", cfg.dynamicParameter.fjtip);
            }
            if (wself.homeData && wself.homeData.appUserType == 2) {
                [wself checkAndShowReloanTip];
            }
        }
    } failure:^(NSError *e) {}];
}

#pragma mark - API 3: Home Data (suphome)

- (void)requestHomeData {
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/user/suphome"
                                    params:body
                                   success:^(id resp) {
        NSLog(@"[Home] suphome raw=%@", resp);
        MKHomeResponse *r = [[MKHomeResponse alloc] initWithDictionary:resp];
        if ([r isSuccess] && r.data) {
            NSLog(@"[Home] userStatus=%ld appUserType=%ld promptCopy=%@ withdrawalOrderId=%@",
                  (long)r.data.userStatus, (long)r.data.appUserType, r.data.promptCopy, r.data.withdrawalOrderId);
            wself.homeData = r.data;
            wself.showEmpty = (r.data.userStatus == 10);
            [MKLoginManager sharedManager].kycCompleted = (r.data.userStatus != 10);
            [wself refreshBottomBarVisibility];
            [wself.tableView reloadData];
            if (r.data.withdrawalOrderId.length > 0) {
                // 照搬 334 RDHomeVC L325-326: 同时传 productId 给弹窗
                [wself showWithdrawalAlertWithOrderId:r.data.withdrawalOrderId
                                            productId:r.data.withdrawalProductId ?: @""];
            }
            if (r.data.appUserType == 2) {
                [wself checkAndShowReloanTip];
            }
        }
    } failure:^(NSError *e) {
        NSLog(@"[Home] suphome failed: %@", e.localizedDescription);
    }];
}

#pragma mark - API 4: Product List

- (void)requestProductList {
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/product/list"
                                    params:body
                                   success:^(id resp) {
        NSLog(@"[Home] product/list raw=%@", resp);
        MKProductListResponse *r = [[MKProductListResponse alloc] initWithDictionary:resp];
        NSLog(@"[Home] product/list count=%lu", (unsigned long)r.productInfoList.count);
        if ([r isSuccess] && r.productInfoList.count > 0) {
            wself.productList = r.productInfoList;
            [wself.tableView reloadData];
        }
    } failure:^(NSError *e) {
        NSLog(@"[Home] product/list failed: %@", e.localizedDescription);
    }];
}

#pragma mark - API 5: User Info (adid 不参与签名)

- (void)requestUserInfo {
    NSDictionary *dataForSign = @{};
    NSDictionary *dataForReq = @{ @"adid": @"" };
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:dataForSign requestData:dataForReq];
    [[MKNetworkManager sharedManager] post:@"/app/v3/user/info"
                                    params:body
                                   success:^(id resp) {
        // 用户名暂存到 NSLog (后续 Profile 用)
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            NSDictionary *d = resp[@"data"];
            NSLog(@"[Home] user/info name=%@ phone=%@", d[@"name"], d[@"phone"]);
        }
    } failure:^(NSError *e) {}];
}

#pragma mark - Apply Now → KYC Status

- (void)applyTapped {
    if (self.isRequestingKYCStatus) return;
    self.isRequestingKYCStatus = YES;
    [SVProgressHUD showWithStatus:@"Loading..."];
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/status"
                                    params:body
                                   success:^(id resp) {
        wself.isRequestingKYCStatus = NO;
        [SVProgressHUD dismiss];
        MKKYCStatusResponse *r = [[MKKYCStatusResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [wself navigateToKYCStep:r.willExecuteStepNumber];
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Failed"];
        }
    } failure:^(NSError *e) {
        wself.isRequestingKYCStatus = NO;
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (void)navigateToKYCStep:(NSString *)step {
    UIViewController *vc;
    if ([step isEqualToString:@"2"]) vc = [MKKYCFinanceViewController new];
    else if ([step isEqualToString:@"3"]) vc = [MKKYCContactViewController new];
    else if ([step isEqualToString:@"4"]) vc = [MKKYCIDViewController new];
    else vc = [MKKYCPersonalViewController new];   // step "1" 或默认
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Product Apply

- (void)applyProductAtIndex:(NSInteger)index {
    if (index >= self.productList.count) return;
    if (self.isRequestingProductTerm) return;
    MKProductInfoModel *p = self.productList[index];
    if (p.productId.length == 0) return;

    self.isRequestingProductTerm = YES;
    [SVProgressHUD showWithStatus:@"Loading..."];
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{ @"productId": p.productId }];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/product/termV3"
                                    params:body
                                   success:^(id resp) {
        wself.isRequestingProductTerm = NO;
        [SVProgressHUD dismiss];
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code == 200) {
            // 对齐 259 navigateToProductApplicationControllerWithResponse:
            // home 层按 amountDetailList.count==1 决定 selectionMode, 然后 push 同一个 VC
            id rawData = resp[@"data"];
            MKProductTermDataModel *termData = [rawData isKindOfClass:[NSDictionary class]]
                ? [[MKProductTermDataModel alloc] initWithDictionary:rawData]
                : nil;
            MKLoanAmountSelectionMode mode = (termData.amountDetailList.count == 1)
                ? MKLoanAmountSelectionModeSingle
                : MKLoanAmountSelectionModeMultiple;
            UIViewController *next = [[MKProductApplyViewController alloc] initWithTermData:termData mode:mode];
            [wself.navigationController pushViewController:next animated:YES];
        } else if (code == 6230002 || code == 6230003) {
            [wself showExistingOrderAlert];
        } else {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Request failed"];
        }
    } failure:^(NSError *e) {
        wself.isRequestingProductTerm = NO;
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (void)showExistingOrderAlert {
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeExistingOrder config:nil];
    __weak typeof(self) wself = self;
    sheet.onConfirmTapped = ^{
        [wself.navigationController pushViewController:[MKOrderListViewController new] animated:YES];
    };
    [sheet show];
}

#pragma mark - 待提现弹窗 (priority 2)

- (void)showWithdrawalAlertWithOrderId:(NSString *)orderId productId:(NSString *)productId {
    if (self.hasViewDisappeared) return;
    NSString *safeOrderId = [orderId copy];
    NSString *safeProductId = [productId copy];
    if (!self.isVersionCheckCompleted || self.isShowingNormalUpdateAlert) {
        __weak typeof(self) wself = self;
        [self enqueueAlert:^{ [wself showWithdrawalAlertWithOrderId:safeOrderId productId:safeProductId]; }];
        return;
    }
    if (self.isShowingWithdrawalAlert) return;
    self.isShowingWithdrawalAlert = YES;
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeWithdrawPending config:nil];
    __weak typeof(self) wself = self;
    sheet.onConfirmTapped = ^{
        wself.isShowingWithdrawalAlert = NO;
        // Confirm 后跳订单详情 (待提现 status=32, 内部按 status 自适应渲染)
        MKOrderDetailViewController *vc = [[MKOrderDetailViewController alloc] initWithOrderId:safeOrderId];
        vc.productId = safeProductId;
        [wself.navigationController pushViewController:vc animated:YES];
        [wself flushPendingAlertsIfNeeded];
    };
    sheet.onCancelTapped = ^{
        wself.isShowingWithdrawalAlert = NO;
        [wself flushPendingAlertsIfNeeded];
    };
    [sheet show];
}

#pragma mark - 复借弹窗 (priority 3) — 照搬 334 RDHomeVC L606-707

- (void)checkAndShowReloanTip {
    if (self.isCheckingReloanTip) return;
    if (sHasShownReloanTipThisLaunch) return;
    if (self.hasViewDisappeared) return;
    if (![[MKLoginManager sharedManager] isLoggedIn]) return;

    // 334 L613: config 还没回来 → 等 requestAppConfig 回调后会再次触发
    MKAppConfigModel *cfg = [MKAppConfigManager sharedManager].currentAppConfig;
    if (!cfg) return;
    if (![cfg.dynamicParameter.fjtip isEqualToString:@"on"]) return;

    self.isCheckingReloanTip = YES;
    [self requestProductStateAndShowTip];
}

- (void)requestProductStateAndShowTip {
    if (sHasShownReloanTipThisLaunch) {
        self.isCheckingReloanTip = NO;
        return;
    }
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{}];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/product/state"
                                    params:body
                                   success:^(id resp) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        sself.isCheckingReloanTip = NO;
        if (sHasShownReloanTipThisLaunch) return;

        MKProductStateResponse *response = [[MKProductStateResponse alloc] initWithDictionary:resp];
        if (![response isSuccess] || !response.data || response.data.amountDetailList.count == 0) return;

        MKProductStateDetailModel *detail = response.data.amountDetailList.firstObject;
        if (detail.productName.length == 0 || detail.loanAmount.length == 0 || detail.productId.length == 0) return;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (sself.hasViewDisappeared) return;
            if (sHasShownReloanTipThisLaunch) return;
            [sself showReloanAlertWithProductDetail:detail];
        });
    } failure:^(NSError *error) {
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        sself.isCheckingReloanTip = NO;
    }];
}

- (void)showReloanAlertWithProductDetail:(MKProductStateDetailModel *)detail {
    // 版本检查未完成 / 普升 / 待提现弹窗中 → 入队
    if (!self.isVersionCheckCompleted || self.isShowingNormalUpdateAlert || self.isShowingWithdrawalAlert) {
        __weak typeof(self) wself = self;
        [self enqueueAlert:^{ [wself showReloanAlertWithProductDetail:detail]; }];
        return;
    }
    if (sHasShownReloanTipThisLaunch) return;
    sHasShownReloanTipThisLaunch = YES;

    if (!self.reloanHandler) {
        self.reloanHandler = [[MKReloanFlowHandler alloc] init];
        self.reloanHandler.delegate = self;
        self.reloanHandler.seamlessOrderDelegate = self;
    }

    NSLog(@"[Reloan] show sheet with product=%@ amount=%@ logo=%@",
          detail.productName, detail.loanAmount, detail.productLogo);

    // 注入产品详情到 sheet config (MKBottomSheetView buildReloan 读取 productAmount/productName/productLogoURL)
    NSString *amountFormatted = [detail.loanAmount mk_formattedPesoAmount];
    NSDictionary *cfg = @{
        @"productName": detail.productName ?: @"",
        @"productAmount": amountFormatted ?: @"",
        @"productLogoURL": detail.productLogo ?: @""
    };
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeHomeReloan config:cfg];
    self.currentReloanSheet = sheet;
    self.reloanHandler.currentReloanAlert = sheet;

    __weak typeof(self) wself = self;
    NSString *capturedProductId = [detail.productId copy];
    NSString *capturedAmount = [detail.loanAmount copy];
    sheet.onConfirmTapped = ^{
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        [SVProgressHUD show];
        [sself.reloanHandler startSeamlessOrderWithProductId:capturedProductId selectedAmount:capturedAmount];
    };
    sheet.onCancelTapped = ^{
        __strong typeof(wself) sself = wself;
        if (!sself) return;
        sself.currentReloanSheet = nil;
        [sself flushPendingAlertsIfNeeded];
    };
    [sheet show];
}

#pragma mark - MKReloanFlowHandlerDelegate

- (void)reloanFlowHandlerDidStartSeamlessOrder:(id)handler {
    // SeamlessOrder 已开始 (state machine 跑起来), sheet 隐藏
    self.currentReloanSheet = nil;
}

- (void)reloanFlowHandlerDidDismiss:(id)handler {
    self.currentReloanSheet = nil;
    [self flushPendingAlertsIfNeeded];
}

#pragma mark - MKSeamlessOrderManagerDelegate (照搬 334 L711-750 简化 — 失败/完成处理)

- (void)seamlessOrderManager:(id)manager didFailWithError:(NSError *)error {
    [SVProgressHUD dismiss];
    NSString *msg = error.localizedDescription ?: @"Order failed";
    [SVProgressHUD showErrorWithStatus:msg];
    [SVProgressHUD dismissWithDelay:2.0];
    if (self.reloanHandler) [self.reloanHandler hideReloanTipAlert];
}

- (void)seamlessOrderManager:(id)manager didCompleteWithOrderId:(NSString *)orderId {
    [SVProgressHUD dismiss];
    if (self.reloanHandler) [self.reloanHandler hideReloanTipAlert];
    // 完成后刷新首页数据
    [self requestHomeData];
    [self requestProductList];
}

- (void)seamlessOrderManager:(id)manager shouldShowMessage:(NSString *)message {
    if (message.length > 0) [SVProgressHUD showInfoWithStatus:message];
}

- (void)seamlessOrderManagerDidCancel:(id)manager {
    [SVProgressHUD dismiss];
    if (self.reloanHandler) [self.reloanHandler hideReloanTipAlert];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 照搬 334 RDHomeVC L506: notice 仅在 promptCopy 非空时显示
    if (section == 0) return self.homeData.promptCopy.length > 0 ? 1 : 0;
    return self.showEmpty ? 1 : self.productList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        MKHomeNoticeCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKHomeNoticeCell cellIdentifier] forIndexPath:indexPath];
        NSString *text = self.homeData.promptCopy.length > 0
            ? self.homeData.promptCopy
            : @"Please complete the KYC certifcation before using our loan service.";
        [cell configureWithText:text];
        return cell;
    }
    if (self.showEmpty) {
        MKHomeDecorationCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKHomeDecorationCell cellIdentifier] forIndexPath:indexPath];
        [cell configureImage:@"mk_home_partners"];
        return cell;
    }
    MKHomeProductCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKHomeProductCell cellIdentifier] forIndexPath:indexPath];
    MKProductInfoModel *p = self.productList[indexPath.row];
    // 照搬 334 RDHomeVC L530-534: ₱ 后空格, 千分位, 一个 ₱
    NSString *quota = [NSString stringWithFormat:@"₱ %@-%@",
                       [p.lowAmount rd_formattedAmount],
                       [p.highAmount rd_formattedAmount]];
    // 利率: 照搬 259 HomeProductCardCell L170-180 (334/372 都漏了这块)
    // API 返回的是 fraction (0.0010 = 0.10%), *100 转百分比, 最多 2 位小数, 去尾零, 空值 fallback "--"
    NSString *rate;
    if (p.lowestLoanInterestRate.length > 0) {
        double rateValue = p.lowestLoanInterestRate.doubleValue * 100.0;
        NSString *rateString = [[NSString stringWithFormat:@"%.2f", rateValue] mk_formattedRate];
        rate = rateString.length > 0 ? [NSString stringWithFormat:@"%@%%", rateString] : @"--";
    } else {
        rate = @"--";
    }
    [cell configureName:p.productName quota:quota rate:rate logoUrl:p.productLogo];
    __weak typeof(self) wself = self;
    NSInteger row = indexPath.row;
    cell.onApplyTapped = ^{ [wself applyProductAtIndex:row]; };
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        CGFloat cardW = kScreenWidth - kScaleW(18) * 2;
        NSString *text = self.homeData.promptCopy.length > 0 ? self.homeData.promptCopy
            : @"Please complete the KYC certifcation before using our loan service.";
        return [MKHomeKYCTipCardView heightForText:text cardWidth:cardW] + kScaleH(12);
    }
    if (self.showEmpty) return [MKHomeDecorationCell rowHeight];
    return [MKHomeProductCell rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [self handleNoticeTap];
        return;
    }
    if (!self.showEmpty) {
        [self applyProductAtIndex:indexPath.row];
    }
}

- (void)handleNoticeTap {
    NSInteger status = self.homeData.userStatus;
    if (status == 10) {
        [self applyTapped];   // 走 KYC 流程
    } else if (status == 100 || status == 20) {
        // 无订单 / 审核中 → 不跳转
    } else {
        [self.navigationController pushViewController:[MKOrderListViewController new] animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return CGFLOAT_MIN; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return CGFLOAT_MIN; }
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section { return nil; }
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { return nil; }

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

@end
