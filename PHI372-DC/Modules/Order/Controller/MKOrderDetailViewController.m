//
//  MKOrderDetailViewController.m
//

#import "MKOrderDetailViewController.h"
#import "MKConstants.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKOrderDetailModel.h"
#import "MKWithdrawnDetailModel.h"
#import "MKOrderStatusMapper.h"
#import "MKLoanProductHeroView.h"
#import "MKDetailRowsView.h"
#import "MKRepaymentPlanButton.h"
#import "MKOrderDetailBottomBar.h"
#import "MKBottomSheetView.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/SDWebImage.h>

#pragma mark - 数字/日期格式

static NSString *MKFmtMoney(NSString *raw) {
    if (!raw) return @"0";
    NSNumberFormatter *f = [NSNumberFormatter new];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    f.maximumFractionDigits = 0;
    return [f stringFromNumber:@([raw doubleValue])] ?: raw;
}

static NSString *MKFmtMoneyP(NSString *raw) {
    return [NSString stringWithFormat:@"₱ %@", MKFmtMoney(raw)];
}

#pragma mark - 行字段定义

// label, hasInfo
typedef struct {
    __unsafe_unretained NSString *label;
    BOOL hasInfo;
} MKDetailRowDef;

@interface MKOrderDetailViewController ()
@property (nonatomic, copy) NSString *orderId;

@property (nonatomic, strong, nullable) MKOrderDetailModel       *orderDetailModel;
@property (nonatomic, strong, nullable) MKWithdrawnDetailModel   *withdrawnDetailModel;
@property (nonatomic, assign) NSInteger selectedAmountIndex;
@property (nonatomic, assign) NSInteger selectedTermIndex;

@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) MKLoanProductHeroView *hero;
@property (nonatomic, strong) MKRepaymentPlanButton *repayPlanBtn;

@property (nonatomic, strong) UIView *detailCard;          // 白色大圆角容器
@property (nonatomic, strong) UIImageView *bankLogoView;
@property (nonatomic, strong) UILabel *bankAccountLabel;
@property (nonatomic, strong) UIView *bankDivider;
@property (nonatomic, strong) MKDetailRowsView *detailRows;

@property (nonatomic, strong) UILabel *bottomMessageLabel;
@property (nonatomic, strong) MKOrderDetailBottomBar *bottomBar;
@end

@implementation MKOrderDetailViewController

- (instancetype)initWithOrderId:(NSString *)orderId {
    if (self = [super init]) {
        _orderId = [orderId copy];
        self.navBarStyle = MKNavBarStyleNone;
        _selectedAmountIndex = 0;
        _selectedTermIndex = 0;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self setupGradient];
    [self setupHeader];
    [self setupScroll];
    [self setupBottomBar];
}

- (void)setupGradient {
    // 顶部渐变: 与订单列表/首页同款 (#385330 → kColorBackground), 占顶部 484h
    self.gradient = [CAGradientLayer layer];
    self.gradient.frame = CGRectMake(0, 0, kScreenWidth, kScaleH(484));
    self.gradient.colors = @[ (id)kColorPrimary.CGColor, (id)kColorBackground.CGColor ];
    self.gradient.locations = @[ @(0.27), @(0.53) ];
    self.gradient.startPoint = CGPointMake(0.5, 0);
    self.gradient.endPoint = CGPointMake(0.5, 1);
    [self.view.layer addSublayer:self.gradient];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [self loadOrderDetail];
}

#pragma mark - Setup

- (void)setupHeader {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, kStatusBarHeight, kScreenWidth, 44)];
    title.text = @"Loan Details";
    title.textAlignment = NSTextAlignmentCenter;
    title.font = kFontSemibold(18);
    title.textColor = kColorWhite;
    [self.view addSubview:title];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(kScaleW(20), kStatusBarHeight, 44, 44);
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
    UIImage *img = [[UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [back setImage:img forState:UIControlStateNormal];
    back.tintColor = kColorWhite;
    back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [back addTarget:self action:@selector(onBackTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
}

- (void)setupScroll {
    self.scroll = [UIScrollView new];
    self.scroll.backgroundColor = [UIColor clearColor];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scroll];
    [self.scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);  // 下方动态留位给 bottomBar
    }];

    self.hero = [[MKLoanProductHeroView alloc] initWithVariant:MKHeroVariantCompact];
    [self.scroll addSubview:self.hero];

    // 黄绿 Repayment plan 横条 — 覆盖在 hero 卡底部 (Pencil yellowbar y=227..283, hero y=112..283)
    // 圆角 14 (rect 风格, 非 Apply 页的 pill 28)
    self.repayPlanBtn = [MKRepaymentPlanButton new];
    self.repayPlanBtn.layer.cornerRadius = kScaleH(14);
    [self.repayPlanBtn addTarget:self action:@selector(onRepayPlanTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scroll addSubview:self.repayPlanBtn];

    // 明细容器: 浅灰 #E9E9E4 (NOT white)
    self.detailCard = [UIView new];
    self.detailCard.backgroundColor = MKHexColor(0xE9E9E4);
    self.detailCard.layer.cornerRadius = kScaleH(14);
    self.detailCard.clipsToBounds = YES;
    [self.scroll addSubview:self.detailCard];

    self.bankLogoView = [UIImageView new];
    self.bankLogoView.contentMode = UIViewContentModeScaleAspectFit;
    self.bankLogoView.image = [UIImage imageNamed:@"mk_bank_logo"];
    [self.detailCard addSubview:self.bankLogoView];

    self.bankAccountLabel = [UILabel new];
    self.bankAccountLabel.font = kFontRegular(14);
    self.bankAccountLabel.textColor = MKHexColor(0x171718);
    self.bankAccountLabel.textAlignment = NSTextAlignmentRight;
    [self.detailCard addSubview:self.bankAccountLabel];

    self.bankDivider = [UIView new];
    self.bankDivider.backgroundColor = MKHexColor(0xD1D1CF);  // Pencil ZPx5n
    [self.detailCard addSubview:self.bankDivider];

    // detailRows 在 didLoadData 时按字段集动态创建

    self.bottomMessageLabel = [UILabel new];
    self.bottomMessageLabel.font = kFontRegular(13);
    self.bottomMessageLabel.textColor = MKHexColor(0x999999);
    self.bottomMessageLabel.numberOfLines = 0;
    [self.scroll addSubview:self.bottomMessageLabel];

    // Hero 回调 (待提现态触发金额/期限选择)
    __weak typeof(self) wself = self;
    self.hero.onAmountChevronTapped  = ^{ [wself showAmountPicker]; };
    self.hero.onTermCapsuleTapped    = ^{ [wself showTermPicker]; };
}

- (void)setupBottomBar {
    self.bottomBar = [MKOrderDetailBottomBar new];
    self.bottomBar.hidden = YES;
    __weak typeof(self) wself = self;
    self.bottomBar.onPrimaryTapped   = ^{ [wself onBottomPrimaryTapped]; };
    self.bottomBar.onSecondaryTapped = ^{ [wself onBottomSecondaryTapped]; };
    [self.view addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@0);  // 动态调整
    }];
}

#pragma mark - API

- (void)loadOrderDetail {
    if (self.orderId.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"Missing orderId"];
        return;
    }
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSMutableDictionary *signData = [NSMutableDictionary dictionary];
    signData[@"orderId"] = self.orderId;
    NSMutableDictionary *reqData = [signData mutableCopy];
    reqData[@"appType"] = @"DC";
    if (self.productId.length > 0) reqData[@"productId"] = self.productId;

    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:signData
                                                                              requestData:reqData];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/order/detail"
                                     params:body
                                    success:^(id resp) {
        if (![resp isKindOfClass:[NSDictionary class]]) {
            [SVProgressHUD showErrorWithStatus:@"Invalid response"]; return;
        }
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code != 200) {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Failed to load detail"];
            return;
        }
        NSDictionary *data = resp[@"data"];
        if (![data isKindOfClass:[NSDictionary class]]) {
            [SVProgressHUD showErrorWithStatus:@"Invalid data"]; return;
        }
        wself.orderDetailModel = [[MKOrderDetailModel alloc] initWithDictionary:data];
        NSInteger status = wself.orderDetailModel.orderDetail.orderStatus;
        if (status == 32) {
            [wself loadWithdrawnDetail];
        } else {
            [SVProgressHUD dismiss];
            [wself renderUI];
        }
    } failure:^(NSError *e) {
        [SVProgressHUD showErrorWithStatus:e.localizedDescription ?: @"Network error"];
    }];
}

- (void)loadWithdrawnDetail {
    NSMutableDictionary *signData = [NSMutableDictionary dictionary];
    signData[@"orderId"] = self.orderId;
    NSMutableDictionary *reqData = [signData mutableCopy];
    if (self.productId.length > 0) reqData[@"productId"] = self.productId;
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:signData
                                                                              requestData:reqData];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/order/withdrawn/detail"
                                     params:body
                                    success:^(id resp) {
        [SVProgressHUD dismiss];
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            NSDictionary *data = resp[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                wself.withdrawnDetailModel = [[MKWithdrawnDetailModel alloc] initWithDictionary:data];
                [wself computeDefaultWithdrawnSelection];
            }
        }
        [wself renderUI];
    } failure:^(NSError *e) {
        [SVProgressHUD dismiss];
        // 失败 fallback 只用 orderDetailModel 渲染
        [wself renderUI];
    }];
}

- (void)computeDefaultWithdrawnSelection {
    self.selectedAmountIndex = 0;
    self.selectedTermIndex = 0;
    // 若 orderDetailModel.orderDetail.loanAmount 命中某 amountDetail, 默认选它
    NSString *targetLoanAmount = self.orderDetailModel.orderDetail.loanAmount;
    if (targetLoanAmount.length > 0) {
        for (NSInteger i = 0; i < self.withdrawnDetailModel.amountDetailList.count; i++) {
            MKWithdrawnAmountDetail *a = self.withdrawnDetailModel.amountDetailList[i];
            if ([a.loanAmount isEqualToString:targetLoanAmount]) {
                self.selectedAmountIndex = i;
                break;
            }
        }
    }
    // term 命中 orderDetail.showTerm
    NSInteger targetShowTerm = self.orderDetailModel.orderDetail.showTerm;
    if (targetShowTerm > 0
        && self.selectedAmountIndex < (NSInteger)self.withdrawnDetailModel.amountDetailList.count) {
        MKWithdrawnAmountDetail *a = self.withdrawnDetailModel.amountDetailList[self.selectedAmountIndex];
        for (NSInteger j = 0; j < a.termDetailList.count; j++) {
            if (a.termDetailList[j].showTerm == targetShowTerm) {
                self.selectedTermIndex = j;
                break;
            }
        }
    }
}

#pragma mark - 选中态访问器

- (nullable MKWithdrawnAmountDetail *)selectedAmountDetail {
    NSArray *list = self.withdrawnDetailModel.amountDetailList;
    if (self.selectedAmountIndex >= (NSInteger)list.count) return nil;
    return list[self.selectedAmountIndex];
}

- (nullable MKWithdrawnTermDetail *)selectedTermDetail {
    MKWithdrawnAmountDetail *a = [self selectedAmountDetail];
    if (self.selectedTermIndex >= (NSInteger)a.termDetailList.count) return nil;
    return a.termDetailList[self.selectedTermIndex];
}

#pragma mark - Render

- (void)renderUI {
    MKOrderDetailInfo *info = self.orderDetailModel.orderDetail;
    if (!info) return;
    NSInteger status = info.orderStatus;

    // Hero 底色 + 状态文案 (复用 list 同色 + chipText)
    UIColor *heroColor = [MKOrderStatusMapper chipColorForStatus:status];
    NSString *statusText = [MKOrderStatusMapper chipTextForStatus:status];
    self.hero.backgroundColor = heroColor ?: kColorPrimary;

    // Hero 金额 + 期限 — 待提现态用 withdrawnDetail 选中值, 否则用 orderDetail
    NSString *amountText;
    NSString *termText;
    BOOL multiAmount = NO, multiTerm = NO;
    if (status == 32 && self.withdrawnDetailModel) {
        MKWithdrawnAmountDetail *sa = [self selectedAmountDetail];
        MKWithdrawnTermDetail *st = [self selectedTermDetail];
        amountText = [sa displayAmountText] ?: MKFmtMoneyP(info.loanAmount);
        termText   = [st displayTermText]   ?: [self displayTermFromOrderInfo:info];
        multiAmount = (self.withdrawnDetailModel.amountDetailList.count > 1);
        multiTerm   = (sa.termDetailList.count > 1);
    } else {
        amountText = MKFmtMoneyP(info.loanAmount);
        termText   = [self displayTermFromOrderInfo:info];
    }
    self.hero.isMultiAmount = multiAmount;
    self.hero.isMultiTerm = multiTerm;

    [self.hero configureCompactAppName:self.orderDetailModel.product.productName ?: @"APPname"
                              termText:termText
                            amountText:amountText
                            statusText:statusText];
    [self.hero setProductLogoURL:self.orderDetailModel.product.productLogo];

    // Bank row — 31 审核拒绝 / 50 放款中 不显示银行卡区域 (对齐 259 shouldShowBankAccount)
    BOOL showBank = !(status == 31 || status == 50);
    NSString *acct = self.orderDetailModel.bankCard.accountNo ?: @"-";
    self.bankAccountLabel.text = acct;
    self.bankLogoView.hidden     = !showBank;
    self.bankAccountLabel.hidden = !showBank;
    self.bankDivider.hidden      = !showBank;

    // Detail rows — 按 status + 值条件动态生成 (隐藏空值行, 卡高自动收缩)
    NSArray<NSDictionary *> *rows = [self buildRowsForStatus:status info:info];
    NSMutableArray *configs = [NSMutableArray array];
    NSMutableArray *values  = [NSMutableArray array];
    for (NSDictionary *r in rows) {
        [configs addObject:@{ @"label": r[@"label"], @"hasInfo": r[@"hasInfo"] }];
        [values  addObject:r[@"value"]];
    }
    [self rebuildDetailRowsWithConfigs:configs values:values];

    // 底部描述
    self.bottomMessageLabel.text = [self bottomMessageForStatus:status];

    // 底部按钮 bar
    MKOrderDetailBottomBarMode mode = [MKOrderDetailBottomBar modeForOrderStatus:status];
    self.bottomBar.mode = mode;
    self.bottomBar.hidden = (mode == MKOrderDetailBottomBarModeNone);
    CGFloat barH = [MKOrderDetailBottomBar heightForMode:mode] + (mode == MKOrderDetailBottomBarModeNone ? 0 : kBottomSafeHeight);
    [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(barH));
    }];
    [self.scroll mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-barH);
    }];

    [self.view setNeedsLayout];
    [self relayoutBody];
}

- (NSString *)displayTermFromOrderInfo:(MKOrderDetailInfo *)info {
    NSInteger show = info.showTerm > 0 ? info.showTerm : info.loanTerm;
    NSString *unit = (info.loanTermUnit == 2) ? @"Months" : @"Days";
    return [NSString stringWithFormat:@"%ld %@", (long)show, unit];
}

- (void)rebuildDetailRowsWithConfigs:(NSArray<NSDictionary *> *)configs values:(NSArray<NSString *> *)values {
    if (self.detailRows) {
        [self.detailRows removeFromSuperview];
        self.detailRows = nil;
    }
    self.detailRows = [[MKDetailRowsView alloc] initWithRowConfigs:configs];
    [self.detailCard addSubview:self.detailRows];
    [self.detailRows setValues:values];
}

#pragma mark - status → 行集合 (动态)

/// 把字符串值视作"有值"的判定 (非空 且 数字 > 0)
static BOOL MKHasPositiveAmount(NSString *raw) {
    if (raw.length == 0) return NO;
    return [raw doubleValue] > 0.0;
}

/// 返回 row 数组, 每项 = @{label, hasInfo, value}; 隐藏的行直接不在数组里
/// 字段子集 / 显隐规则对齐 259 UnifiedProductCell.updateVisibilityForStatusXX + Pencil 行 label
- (NSArray<NSDictionary *> *)buildRowsForStatus:(NSInteger)status info:(MKOrderDetailInfo *)info {
    NSMutableArray *rows = [NSMutableArray array];

    // 5 base rows — 所有 status 都有
    // 待提现(32) 用 withdrawnDetail 的 selectedTermDetail 数据(用户重选金额/期限后实时更新)
    NSString *received, *interest, *fee, *applyDate, *dueDate, *payoutDate;
    if (status == 32 && self.withdrawnDetailModel) {
        MKWithdrawnTermDetail *st = [self selectedTermDetail];
        received   = MKFmtMoney(st.arrivalAmount  ?: info.receiptAmount);
        interest   = MKFmtMoney(st.interestAmount ?: info.interestAmount);
        fee        = MKFmtMoney(st.feeAmount      ?: info.feeAmount);
        applyDate  = st.borrowingDate ?: info.applyDate ?: @"-";
        dueDate    = st.repaymentDate ?: info.dueDate   ?: @"-";
        payoutDate = info.payoutDate;
    } else {
        received   = MKFmtMoney(info.receiptAmount);
        interest   = MKFmtMoney(info.interestAmount);
        fee        = MKFmtMoney(info.feeAmount);
        applyDate  = info.applyDate ?: @"-";
        dueDate    = info.dueDate ?: @"-";
        payoutDate = info.payoutDate;
    }
    [rows addObject:@{ @"label":@"Amount received",     @"hasInfo":@YES, @"value":received  }];
    [rows addObject:@{ @"label":@"Interest",            @"hasInfo":@YES, @"value":interest  }];
    [rows addObject:@{ @"label":@"Service fee",         @"hasInfo":@YES, @"value":fee       }];

    // 申请时间 — 259 规则: 存在 payoutDate 时隐藏申请时间, 仅显示放款时间
    if (payoutDate.length > 0) {
        // 用同位 row "Date of application" label 显示 payoutDate (Pencil 4 个页面都没单独画 "Disbursement date" row,
        // 直接借位; 若你想分两行 row 后续再加)
        // 这里保留 "Date of application" label, 值显示 payoutDate
        [rows addObject:@{ @"label":@"Date of application", @"hasInfo":@NO, @"value":payoutDate }];
    } else {
        [rows addObject:@{ @"label":@"Date of application", @"hasInfo":@NO, @"value":applyDate }];
    }
    [rows addObject:@{ @"label":@"Due date",            @"hasInfo":@NO,  @"value":dueDate   }];

    // 扩展行 — 仅 60/63/70/61 含还款类字段
    BOOL extended = (status == 60 || status == 63 || status == 70 || status == 61);
    if (!extended) return rows;

    // Total repayment — 必显
    [rows addObject:@{ @"label":@"Total repayment",     @"hasInfo":@NO,
                       @"value":MKFmtMoney(info.totalRepaymentAmount) }];

    // Amount of deduction — 无值不显 (259 hasReduction)
    BOOL hasDeduction = MKHasPositiveAmount(info.reductionAmount);
    if (hasDeduction) {
        [rows addObject:@{ @"label":@"Amount of deduction", @"hasInfo":@NO,
                           @"value":MKFmtMoney(info.reductionAmount) }];
    }

    // Service fee (重复) — Pencil hv74X 第二个 "Service fee" 位次=已还金额 (259 alreadyRepaymentAmount)
    // 保留 Pencil label 但取值用 alreadyRepaymentAmount; 无值不显
    BOOL hasRepaid = MKHasPositiveAmount(info.alreadyRepaymentAmount);
    if (hasRepaid) {
        [rows addObject:@{ @"label":@"Service fee",     @"hasInfo":@NO,
                           @"value":MKFmtMoney(info.alreadyRepaymentAmount) }];
    }

    // Amount Due 剩余未还 — 60/63/61 显示(70 结清不显示); 减免和已还都无值则隐藏 (259 规则)
    BOOL canShowAmountDue = (status == 60 || status == 63 || status == 61) && (hasDeduction || hasRepaid);
    if (canShowAmountDue) {
        double remain = [info.totalRepaymentAmount doubleValue]
                      - [info.reductionAmount      doubleValue]
                      - [info.alreadyRepaymentAmount doubleValue];
        if (remain < 0) remain = 0;
        [rows addObject:@{ @"label":@"Amount Due",      @"hasInfo":@NO,
                           @"value":MKFmtMoney([NSString stringWithFormat:@"%.0f", remain]) }];
    }

    // Deferment charge 逾期费 — 仅 61 + 有值 (259 hasPenalty)
    BOOL hasPenalty = (status == 61) && MKHasPositiveAmount(info.penaltyAmount);
    if (hasPenalty) {
        [rows addObject:@{ @"label":@"Deferment charge", @"hasInfo":@NO,
                           @"value":MKFmtMoney(info.penaltyAmount) }];
    }

    return rows;
}

- (NSString *)bottomMessageForStatus:(NSInteger)status {
    switch (status) {
        case 30:
            return @"Your application is currently under review, and the final loan amount depends on the credit assessment. Maintaining a good credit record can enhance the actual loan amount approved.";
        case 32:
            return @"Your application has been approved, please confirm the loan information. We will transfer the money to your bank account immediately.";
        case 60: case 61: case 63:
            return @"Please repay on time before the due date. Timely repayments will significantly increase your subsequent loan eligibility.";
        default:
            return self.orderDetailModel.message ?: @"";
    }
}

#pragma mark - 布局 (body)

- (void)relayoutBody {
    // 全部坐标对齐 Pencil cpq29/b5RSzJ/hv74X 实测值
    //   hero      Pencil y=112  339×171  r=14
    //   yellowbar Pencil y=227  339×56   r=14  (与 hero 共底, 覆盖 hero 最底 56px)
    //   detailcard Pencil y=293 339×var  r=14  fill #E9E9E4
    //     bank row 内部 offset y≈22, divider y≈58
    //     detail rows 内部 offset y=81 (Pencil 行1 y=374 - cardTop 293)
    //   paragraph Pencil y=540+ (detail card 之下 10px)
    CGFloat W = kScreenWidth;
    CGFloat cardW = kScaleW(339);
    CGFloat margin = (W - cardW) * 0.5;  // ≈ kScaleW(18)

    // Hero top = Pencil y=112 在 scroll 内的相对位置
    CGFloat heroTop = kScaleH(112) - kNavBarHeight;
    if (heroTop < 0) heroTop = 0;
    CGFloat heroH = [MKLoanProductHeroView heightForVariant:MKHeroVariantCompact];
    self.hero.frame = CGRectMake(margin, heroTop, cardW, heroH);

    // Yellow Repayment plan 条: 覆盖 hero 底部, 从 hero 顶往下 115px
    BOOL hasRepayPlan = (self.orderDetailModel.orderDetail.productTermItemList.count > 0)
                       || (self.withdrawnDetailModel.amountDetailList.count > 0);
    self.repayPlanBtn.hidden = !hasRepayPlan;
    if (hasRepayPlan) {
        CGFloat barTop = heroTop + kScaleH(115);
        CGFloat barH = [MKRepaymentPlanButton buttonHeight];
        self.repayPlanBtn.frame = CGRectMake(margin, barTop, cardW, barH);
    }

    // Detail card: hero 下 10px (Pencil 283 → 293)
    CGFloat cardTop = heroTop + kScaleH(181);

    // Detail card 内: bank row 0..66, rows 起点 81 (含 bank row); 若隐藏 bank row → 行起点 21
    NSInteger rowCount = self.detailRows ? (self.detailRows.subviews.count) : 0;
    CGFloat rowsH = (rowCount > 0) ? [MKDetailRowsView viewHeightForCount:rowCount] : 0;
    BOOL bankVisible = !self.bankLogoView.hidden;
    CGFloat rowsTopInCard = bankVisible ? kScaleH(81) : kScaleH(21);
    CGFloat cardH = rowsTopInCard + rowsH + kScaleH(24);  // rows 起点 + rows + 24 底 padding

    // Pencil 实测 (card abs y=293, 内部 = abs - cardTop=293):
    //   bank logo  abs (36,314) 38x23 → 内 (18,21)
    //   bank 号    abs (201,315)      → 内 (183,22) 右对齐
    //   divider    abs (37,352) 301x1 → 内 (19,59)
    //   row1 起点  abs (36,374)       → 内 (18,81)
    self.detailCard.frame = CGRectMake(margin, cardTop, cardW, cardH);
    self.bankLogoView.frame     = CGRectMake(kScaleW(18), kScaleH(21), kScaleW(38), kScaleH(23));
    self.bankAccountLabel.frame = CGRectMake(kScaleW(60), kScaleH(22),
                                              cardW - kScaleW(78), kScaleH(20));
    self.bankDivider.frame      = CGRectMake(kScaleW(19), kScaleH(59), kScaleW(301), 1);
    // detailRows 内部左 padding 18 (Pencil row label x=18 from card 左)
    self.detailRows.frame       = CGRectMake(kScaleW(18), rowsTopInCard,
                                              cardW - kScaleW(36), rowsH);

    CGFloat y = cardTop + cardH + kScaleH(10);

    // 底部描述 (detail card 之外, paragraph 与 card 左对齐)
    if (self.bottomMessageLabel.text.length > 0) {
        CGFloat textW = cardW;
        CGFloat textH = [self.bottomMessageLabel.text
                         boundingRectWithSize:CGSizeMake(textW, CGFLOAT_MAX)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{NSFontAttributeName: self.bottomMessageLabel.font}
                                      context:nil].size.height;
        self.bottomMessageLabel.frame = CGRectMake(margin, y, textW, ceilf(textH) + 4);
        y += textH + kScaleH(20);
    } else {
        self.bottomMessageLabel.frame = CGRectZero;
    }

    self.scroll.contentSize = CGSizeMake(W, y + kScaleH(8));
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orderDetailModel) [self relayoutBody];
}

#pragma mark - Pickers (status 32 待提现)

- (void)showAmountPicker {
    NSArray<MKWithdrawnAmountDetail *> *list = self.withdrawnDetailModel.amountDetailList;
    if (list.count <= 1) return;
    NSMutableArray *titles = [NSMutableArray array];
    for (MKWithdrawnAmountDetail *a in list) [titles addObject:[a displayAmountText]];
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeCommonPicker
                                                         config:@{ @"title": @"Loan Amount",
                                                                   @"items": titles,
                                                                   @"selectedIndex": @(self.selectedAmountIndex) }];
    __weak typeof(self) wself = self;
    sheet.onSelected = ^(NSInteger idx, id value) {
        if (idx < list.count) {
            wself.selectedAmountIndex = idx;
            // 切金额, term 重置首项 (对齐 apply page)
            wself.selectedTermIndex = 0;
            [wself renderUI];
        }
    };
    [sheet show];
}

- (void)showTermPicker {
    MKWithdrawnAmountDetail *sa = [self selectedAmountDetail];
    NSArray<MKWithdrawnTermDetail *> *terms = sa.termDetailList;
    if (terms.count <= 1) return;
    NSMutableArray *titles = [NSMutableArray array];
    for (MKWithdrawnTermDetail *t in terms) [titles addObject:[t displayTermText]];
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeCommonPicker
                                                         config:@{ @"title": @"Loan Tenure",
                                                                   @"items": titles,
                                                                   @"selectedIndex": @(self.selectedTermIndex) }];
    __weak typeof(self) wself = self;
    sheet.onSelected = ^(NSInteger idx, id value) {
        if (idx < terms.count) {
            wself.selectedTermIndex = idx;
            [wself renderUI];
        }
    };
    [sheet show];
}

#pragma mark - 操作回调 (按钮)

- (void)onBottomPrimaryTapped {
    NSInteger status = self.orderDetailModel.orderDetail.orderStatus;
    switch (status) {
        case 32:                   [self performWithdraw]; break;
        case 60: case 61: case 63: [self performRepay]; break;
        case 36:                   [self performModifyBankCard]; break;
        case 10: case 20:          [self performDataCapture]; break;
        default:                   break;
    }
}

- (void)onBottomSecondaryTapped {
    [self performDefer];
}

- (void)performWithdraw {
    [SVProgressHUD showInfoWithStatus:@"Withdraw — TODO"];
}

- (void)performRepay {
    [SVProgressHUD showInfoWithStatus:@"Repay — TODO"];
}

- (void)performDefer {
    [SVProgressHUD showInfoWithStatus:@"Defer — TODO"];
}

- (void)performModifyBankCard {
    [SVProgressHUD showInfoWithStatus:@"Modify Bank Card — TODO"];
}

- (void)performDataCapture {
    // 待抓取数据(10/20): 在当页直接调起数据抓取流程
    [SVProgressHUD showInfoWithStatus:@"Submit Information — TODO (当页数据抓取)"];
}

- (void)onRepayPlanTapped {
    [SVProgressHUD showInfoWithStatus:@"Repayment plan — TODO"];
}

@end
