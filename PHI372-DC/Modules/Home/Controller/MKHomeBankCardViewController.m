//  MKHomeBankCardViewController.m
//  PHI372-DC — Pencil bPx5L 首页-银行卡 (银行卡列表)
//    viewWillAppear → POST /app/v3/payAccountInfo/list (空 body) → 拉真实卡列表
//    卡片右上 Default radio 点击 → POST /app/v3/payAccountInfo/setDefault → reload
//    卡片 Submit (Edit) → push MKKYCBankCardEditViewController.bankCardBindId
//    Add 按钮 → push MKKYCBankCardEditViewController (新建模式, bindId=0)

#import "MKHomeBankCardViewController.h"
#import "MKConstants.h"
#import "MKBankCardItemView.h"
#import "MKHintBannerView.h"
#import "MKKYCBankCardEditViewController.h"
#import "MKPayAccountModel.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKHomeBankCardViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *cardsContainer;          // 装动态生成的卡 view
@property (nonatomic, strong) NSMutableArray<MKBankCardItemView *> *cardViews;
@property (nonatomic, strong) NSArray<MKPayAccountModel *> *cards;
@property (nonatomic, strong) MKHintBannerView *hint;
@property (nonatomic, strong) UIButton *addButton;
@end

@implementation MKHomeBankCardViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Bank Account";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self setupBaseLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestPayAccountList];
}

#pragma mark - Setup

- (void)setupBaseLayout {
    self.cardViews = [NSMutableArray array];

    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = kColorBackground;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *m) {
        m.top.equalTo(self.view).offset(kNavBarHeight);
        m.left.right.equalTo(self.view);
        m.bottom.equalTo(self.view).offset(-kBottomSafeHeight - kScaleH(92));
    }];

    // Hint banner (Pencil IyZv2 文字, 19,110 339×89)
    NSString *hintText = @"You may link multiple receiving accounts. If the default account is unavailable, we will automatically switch to the backup account to ensure a successful disbursement.";
    CGFloat hintH = [MKHintBannerView heightForText:hintText];
    self.hint = [[MKHintBannerView alloc] initWithText:hintText];
    self.hint.frame = CGRectMake(kScaleW(18), kScaleH(12), kScaleW(339), hintH);
    [self.scrollView addSubview:self.hint];

    // 卡片容器
    self.cardsContainer = [UIView new];
    self.cardsContainer.frame = CGRectMake(0, CGRectGetMaxY(self.hint.frame) + kScaleH(14), kScreenWidth, 0);
    [self.scrollView addSubview:self.cardsContainer];

    // Add 按钮 (固定底部, 描边)
    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addButton.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(76),
                                       kScaleW(303), kScaleH(56));
    self.addButton.backgroundColor = [UIColor clearColor];
    self.addButton.layer.borderColor = kColorPrimary.CGColor;
    self.addButton.layer.borderWidth = 2;
    self.addButton.layer.cornerRadius = kScaleH(28);
    [self.addButton setTitle:@"Add" forState:UIControlStateNormal];
    [self.addButton setTitleColor:kColorPrimary forState:UIControlStateNormal];
    self.addButton.titleLabel.font = kFontSemibold(16);
    [self.addButton addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addButton];
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
            [wself rebuildCardViews];
        } else {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Load failed"];
            [SVProgressHUD dismissWithDelay:2.0];
        }
    } failure:^(NSError *e) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
        [SVProgressHUD dismissWithDelay:2.0];
    }];
}

- (void)rebuildCardViews {
    // 清空旧 view
    for (MKBankCardItemView *v in self.cardViews) [v removeFromSuperview];
    [self.cardViews removeAllObjects];

    CGFloat y = 0;
    CGFloat cardH = [MKBankCardItemView cardHeight];
    for (NSInteger i = 0; i < self.cards.count; i++) {
        MKPayAccountModel *m = self.cards[i];
        MKBankCardItemView *card = [[MKBankCardItemView alloc]
            initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), cardH)];
        card.bankName   = m.bankCode ?: @"";
        card.cardNumber = m.cardNumber ?: @"";
        card.holderName = m.accountName ?: @"";
        card.isDefault  = m.defaultFlag;
        card.selected   = m.defaultFlag;
        __weak typeof(self) wself = self;
        card.onSelected = ^{ [wself setAsDefault:m]; };
        card.onSubmitTapped = ^{ [wself pushEditPageForCard:m]; };
        [self.cardsContainer addSubview:card];
        [self.cardViews addObject:card];
        y += cardH + kScaleH(10);
    }

    self.cardsContainer.frame = CGRectMake(0, CGRectGetMaxY(self.hint.frame) + kScaleH(14),
                                            kScreenWidth, y);
    self.scrollView.contentSize = CGSizeMake(kScreenWidth, CGRectGetMaxY(self.cardsContainer.frame));
}

#pragma mark - /payAccountInfo/setDefault

- (void)setAsDefault:(MKPayAccountModel *)card {
    if (card.defaultFlag) return;   // 已是默认, 不重复请求
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{
        @"recordId": @(card.recordId),
        @"defaultFlag": @"1"
    }];
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/payAccountInfo/setDefault"
                                    params:body
                                   success:^(id resp) {
        [SVProgressHUD dismiss];
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            [wself requestPayAccountList];   // 刷新列表
        } else {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Set default failed"];
            [SVProgressHUD dismissWithDelay:2.0];
        }
    } failure:^(NSError *e) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
        [SVProgressHUD dismissWithDelay:2.0];
    }];
}

#pragma mark - Navigation

- (void)pushEditPageForCard:(MKPayAccountModel *)card {
    MKKYCBankCardEditViewController *vc = [[MKKYCBankCardEditViewController alloc] init];
    vc.bankCardBindId = card.bankCardBindId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addTapped {
    // 新建模式: bankCardBindId=0, BankCardEditVC 内部根据此 flag 走 /save 而非 /update
    MKKYCBankCardEditViewController *vc = [[MKKYCBankCardEditViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
