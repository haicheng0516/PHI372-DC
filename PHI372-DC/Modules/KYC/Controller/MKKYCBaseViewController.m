//
//  MKKYCBaseViewController.m
//

#import "MKKYCBaseViewController.h"
#import "MKConstants.h"
#import "MKKYCInputCell.h"
#import "MKKYCPickerCell.h"
#import "MKBottomSheetView.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKKYCInitResponse.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKKYCBaseViewController ()
@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong, readwrite) UIButton *continueButton;
@property (nonatomic, strong, readwrite) MKKYCProgressBarView *progressBar;
@end

@implementation MKKYCBaseViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        _formItems = [NSMutableArray array];
        _currentStep = 1;     // 默认第 1 步, 子类 init 时 override
        _showsProgressBar = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // View 底层用浅 #F8F8F7, tableView 用米色 #E9E9E4 做内嵌面板
    self.view.backgroundColor = kColorBackground;
    [self setupUI];
    [self loadFormItems];
}

#pragma mark - Setup

- (void)setupUI {
    // 1) 进度条 — 不在 tableView 内, 浮在 navbar 和 panel 之间. 左右距屏幕 20pt
    //    独立页 (Payment / BankCardEdit) 设 showsProgressBar=NO 隐藏
    self.progressBar = [[MKKYCProgressBarView alloc] init];
    self.progressBar.totalSteps = 4;             // KYC 固定 4 步
    self.progressBar.currentStep = self.currentStep;
    self.progressBar.hidden = !self.showsProgressBar;
    [self.view addSubview:self.progressBar];
    [self.progressBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight + 12);
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
        make.height.mas_equalTo(self.showsProgressBar ? 21 : 0);
    }];

    // 2) TableView (米色面板)
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = kColorCardSecondary;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = 91;          // Pencil: 75pt card + 8pt top/bottom padding = 91
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    // 底部 inset 给 Continue 按钮预留空间 (56 + 24 上下 padding)
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 56 + 32, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.layer.cornerRadius = 16;
    self.tableView.layer.masksToBounds = YES;
    [MKKYCInputCell registerForTableView:self.tableView];
    [MKKYCPickerCell registerForTableView:self.tableView];
    [self.view addSubview:self.tableView];
    CGFloat tableTopOffset = self.showsProgressBar ? 12 : 16;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressBar.mas_bottom).offset(tableTopOffset);
        make.left.equalTo(self.view).offset(18);
        make.right.equalTo(self.view).offset(-18);
        make.bottom.equalTo(self.view).offset(-kBottomSafeHeight - 12);
    }];

    // 3) Continue 按钮 — 浮在 tableView 内底端 (视觉上包在面板里)
    self.continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.continueButton.backgroundColor = kColorPrimary;
    self.continueButton.layer.cornerRadius = 28;
    [self.continueButton setTitle:[self continueButtonTitle] forState:UIControlStateNormal];
    [self.continueButton setTitleColor:kColorWhite forState:UIControlStateNormal];
    self.continueButton.titleLabel.font = kFontButtonLarge;
    [self.continueButton addTarget:self action:@selector(continueAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.continueButton];
    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        // Pencil: button x=36 screen, tableView x=18 → offset 18 within tableView
        make.left.equalTo(self.tableView).offset(18);
        make.right.equalTo(self.tableView).offset(-18);
        make.bottom.equalTo(self.tableView).offset(-16);
        make.height.mas_equalTo(56);
    }];
}

- (void)setCurrentStep:(NSInteger)currentStep {
    _currentStep = currentStep;
    self.progressBar.currentStep = currentStep;
}

#pragma mark - 子类可重写

- (NSString *)continueButtonTitle { return @"Continue"; }
- (void)continueAction { /* override */ }
- (void)loadFormItems  { /* override: 装填 self.formItems 然后 [self.tableView reloadData] */ }

#pragma mark - 拦截返回 → 弹确认 (覆盖 Base 的默认 pop)

- (void)onBackTapped {
    [self showBackConfirmDialog];
}

#pragma mark - 通用方法: 校验

- (BOOL)validateFormItems {
    // 照搬 259: 提交前对 selectedValue 先 trim 再 length 判 (全空格也算未填), 通过后回写
    for (MKKYCItemModel *item in self.formItems) {
        if (item.isRequired != 1) continue;
        NSString *raw = item.selectedValue ?: @"";
        NSString *value = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (value.length == 0) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Please complete %@", item.itemName]];
            [SVProgressHUD dismissWithDelay:2.0];
            return NO;
        }
        // trim 后回写, 后续 buildSubmitData 直接取到干净值
        if (![raw isEqualToString:value]) {
            item.selectedValue = value;
        }
        if (item.regularExpression.length > 0) {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", item.regularExpression];
            if (![pred evaluateWithObject:value]) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Invalid format for %@", item.itemName]];
                [SVProgressHUD dismissWithDelay:2.0];
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - 通用方法: 拉表单字段 (/kyc/four/search-iterm)

- (void)requestFormItems {
    if (self.kycId.length == 0) {
        NSLog(@"[MKKYCBase] requestFormItems 跳过, kycId 为空 (class=%@)", NSStringFromClass([self class]));
        return;
    }
    [SVProgressHUD show];
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{}
                            requestData:@{@"kycId": self.kycId}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/search-iterm"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCInitResponse *r = [[MKKYCInitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [strongSelf.formItems removeAllObjects];
            if (r.kycItemList.count > 0) {
                [strongSelf.formItems addObjectsFromArray:r.kycItemList];
            }
            [strongSelf.tableView reloadData];
            if ([strongSelf respondsToSelector:@selector(onFormItemsLoaded)]) {
                [(id)strongSelf performSelector:@selector(onFormItemsLoaded)];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Failed to load"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (NSDictionary<NSString *, NSString *> *)collectFormValues {
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (MKKYCItemModel *item in self.formItems) {
        if (item.itemCode.length == 0) continue;
        out[item.itemCode] = item.selectedKey ?: item.selectedValue ?: @"";
    }
    return [out copy];
}

#pragma mark - 通用方法: 滚到下一行 + 自动 focus / 弹 picker

- (void)scrollToNextRowAfterIndex:(NSInteger)index {
    NSInteger nextIndex = index + 1;
    if (nextIndex >= (NSInteger)self.formItems.count) return;

    NSIndexPath *nextPath = [NSIndexPath indexPathForRow:nextIndex inSection:0];
    [self.tableView scrollToRowAtIndexPath:nextPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:YES];

    MKKYCItemModel *nextItem = self.formItems[nextIndex];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if ([nextItem isPickerType]) {
            [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:nextPath];
        } else {
            UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:nextPath];
            if ([nextCell isKindOfClass:[MKKYCInputCell class]]) {
                [((MKKYCInputCell *)nextCell).inputField becomeFirstResponder];
            }
        }
    });
}

#pragma mark - 通用方法: 返回确认

- (void)showBackConfirmDialog {
    [self.view endEditing:YES];
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeBackConfirm config:nil];
    kWeakSelf
    sheet.onConfirmTapped = ^{
        kStrongSelf
        [strongSelf.navigationController popToRootViewControllerAnimated:YES];
    };
    [sheet show];
}

@end
