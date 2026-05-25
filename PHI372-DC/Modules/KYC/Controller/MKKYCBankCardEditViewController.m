//
//  MKKYCBankCardEditViewController.m
//  Pencil t06hJ "Change bank account" — 双模式 (新建 + 编辑) 同一个 VC, 同一套 UI
//  接口对齐 PHI259-DC BankAccountController (Add + Modify):
//    bankCardBindId > 0 → 编辑模式:
//        POST /app/v3/payAccountInfo/list             (bankCardBindId) → 拿 recordId + 预填
//        POST /app/v3/payAccountInfo/payAccountItemList → 表单结构
//        POST /app/v3/payAccountInfo/update           (kycCommitItemList + recordId + defaultFlag)
//    bankCardBindId == 0 → 新建模式:
//        POST /app/v3/payAccountInfo/payAccountItemList → 表单结构
//        POST /app/v3/payAccountInfo/save             (kycCommitItemList + defaultFlag, 无 recordId)
//

#import "MKKYCBankCardEditViewController.h"
#import "MKConstants.h"
#import "MKKYCInputCell.h"
#import "MKKYCPickerCell.h"
#import "MKPickerView.h"
#import "MKKYCInitResponse.h"
#import "MKKYCCommitResponse.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKKYCBankCardEditViewController () <UITableViewDataSource, UITableViewDelegate>
/// /list 拿到的 recordId, 提交 /update 时必带
@property (nonatomic, copy, nullable) NSString *recordId;
/// /list 拿到的当前字段值 dict (itemCode → itemValue), 拉到表单后用于预填
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *prefillValues;
/// KYC 已认证的用户姓名 (来自 /user/info), 用于填 Name 字段并锁定不可编辑
@property (nonatomic, copy, nullable) NSString *userName;
/// Pencil: "Set as default receiving method" radio, 默认选中
@property (nonatomic, assign) BOOL isDefaultAccount;
/// Pencil: default row UI
@property (nonatomic, strong) UIView *defaultAccountRow;
@end

@implementation MKKYCBankCardEditViewController

- (instancetype)init {
    if (self = [super init]) {
        // 默认标题, 新建模式由 viewDidLoad 改为 "Add bank account"; 编辑模式保留
        self.navTitle = @"Change bank account";
        self.showsProgressBar = NO;
        _isDefaultAccount = YES;      // Pencil: 默认选中 "Set as default receiving method"
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 新建模式: 调整 nav 标题
    if (self.bankCardBindId == 0) {
        self.navTitle = @"Add bank account";
    }
}

- (NSString *)continueButtonTitle { return @"Submit"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self setupDefaultAccountRow];
    [self overrideTableHeightForPencilLayout];   // Pencil aKmfI: 表单 492 高, Submit 紧贴 toggle 下方
    [self requestUserInfo];                       // 259 对齐: KYC 已认证 name 自动填入
}

/// Pencil t06hJ 这页是"独立面板"模式 — tableView 限高 492 (而非 KYC base 默认全屏)
/// 这样 Submit 按钮紧贴 toggle 下方而不是屏幕底部
- (void)overrideTableHeightForPencilLayout {
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight + kScaleH(16));
        make.left.equalTo(self.view).offset(kScaleW(18));
        make.right.equalTo(self.view).offset(-kScaleW(18));
        make.height.mas_equalTo(kScaleH(492));   // Pencil aKmfI height
    }];
}

/// Pencil IgWRm + okf3W: "Set as default receiving method" radio row 放在 tableFooterView
- (void)setupDefaultAccountRow {
    CGFloat rowHeight = 44.0;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, rowHeight + 8)];
    footer.backgroundColor = [UIColor clearColor];

    // radio 图标占位 (Pencil: IgWRm 16x16 圆形 radio)
    UIButton *radioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    radioBtn.tag = 8001;
    [radioBtn addTarget:self action:@selector(toggleDefaultAccount) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:radioBtn];
    self.defaultAccountRow = footer;

    UIView *radioOuter = [[UIView alloc] init];
    radioOuter.layer.cornerRadius = 8;
    radioOuter.layer.borderWidth = 1.5;
    radioOuter.layer.borderColor = [UIColor colorWithRed:0x38/255.0 green:0x53/255.0 blue:0x30/255.0 alpha:1].CGColor;
    radioOuter.userInteractionEnabled = NO;
    radioOuter.tag = 8002;
    [footer addSubview:radioOuter];
    radioOuter.translatesAutoresizingMaskIntoConstraints = NO;
    // Pencil aIMwS: x=36, tableView 已从屏 x=18 起 → footer 内 leftAnchor + 18 = 屏 x=36
    [NSLayoutConstraint activateConstraints:@[
        [radioOuter.leftAnchor constraintEqualToAnchor:footer.leftAnchor constant:18],
        [radioOuter.centerYAnchor constraintEqualToAnchor:footer.topAnchor constant:rowHeight / 2],
        [radioOuter.widthAnchor constraintEqualToConstant:16],
        [radioOuter.heightAnchor constraintEqualToConstant:16]
    ]];

    UIView *radioDot = [[UIView alloc] init];
    radioDot.layer.cornerRadius = 4;
    radioDot.backgroundColor = [UIColor colorWithRed:0x38/255.0 green:0x53/255.0 blue:0x30/255.0 alpha:1];
    radioDot.tag = 8003;
    radioDot.hidden = !self.isDefaultAccount;
    [radioOuter addSubview:radioDot];
    radioDot.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [radioDot.centerXAnchor constraintEqualToAnchor:radioOuter.centerXAnchor],
        [radioDot.centerYAnchor constraintEqualToAnchor:radioOuter.centerYAnchor],
        [radioDot.widthAnchor constraintEqualToConstant:8],
        [radioDot.heightAnchor constraintEqualToConstant:8]
    ]];

    // 文字 (Pencil: okf3W, 12pt, #999999)
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Set as default receiving method";
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1];
    [footer addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [label.leftAnchor constraintEqualToAnchor:radioOuter.rightAnchor constant:8],
        [label.centerYAnchor constraintEqualToAnchor:radioOuter.centerYAnchor]
    ]];

    // 整行可点击
    radioBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [radioBtn.leftAnchor constraintEqualToAnchor:footer.leftAnchor],
        [radioBtn.rightAnchor constraintEqualToAnchor:footer.rightAnchor],
        [radioBtn.topAnchor constraintEqualToAnchor:footer.topAnchor],
        [radioBtn.heightAnchor constraintEqualToConstant:rowHeight]
    ]];

    self.tableView.tableFooterView = footer;
}

- (void)toggleDefaultAccount {
    self.isDefaultAccount = !self.isDefaultAccount;
    UIView *footer = self.defaultAccountRow;
    UIView *radioDot = [footer viewWithTag:8003];
    radioDot.hidden = !self.isDefaultAccount;
}

- (void)loadFormItems {
    if (self.bankCardBindId > 0) {
        [self requestBankCardDetail];   // → 完成后链式调 requestPayAccountItemList
    } else {
        NSLog(@"[BankCardEdit] bankCardBindId 未传入, 跳过 detail, 直接拉表单");
        [self requestPayAccountItemList];
    }
}

#pragma mark - /payAccountInfo/list → recordId + 预填值

- (void)requestBankCardDetail {
    [SVProgressHUD show];
    NSDictionary *dataForRequest = @{ @"bankCardBindId": @(self.bankCardBindId) };
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:dataForRequest];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/payAccountInfo/list"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        if ([resp isKindOfClass:[NSDictionary class]]) {
            NSDictionary *data = resp[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSArray *list = data[@"payAccountInfoList"];
                if ([list isKindOfClass:[NSArray class]] && list.count > 0) {
                    NSDictionary *first = list.firstObject;
                    if ([first isKindOfClass:[NSDictionary class]]) {
                        strongSelf.recordId = [first[@"recordId"] description];
                        strongSelf.prefillValues = [strongSelf extractFieldValuesFromDict:first];
                    }
                }
            }
        }
        [strongSelf requestPayAccountItemList];
    } failure:^(NSError *error) {
        kStrongSelf
        [SVProgressHUD showErrorWithStatus:error.localizedDescription ?: @"Failed to load card"];
        // 失败也继续拉表单, 让用户能填空白
        [strongSelf requestPayAccountItemList];
    }];
}

/// 从 /list 返回的字典里挑出非元数据字段, 作为 (itemCode → 值) 字典.
/// 接口里直接平铺所有字段, 把已知的元 key 排除.
- (NSDictionary<NSString *, NSString *> *)extractFieldValuesFromDict:(NSDictionary *)dict {
    NSSet *metaKeys = [NSSet setWithArray:@[
        @"recordId", @"bankCardBindId", @"defaultFlag", @"createTime", @"updateTime",
        @"userId", @"id", @"status"
    ]];
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (NSString *key in dict) {
        if ([metaKeys containsObject:key]) continue;
        id val = dict[key];
        if ([val isKindOfClass:[NSString class]]) {
            out[key] = val;
        } else if ([val isKindOfClass:[NSNumber class]]) {
            out[key] = [val stringValue];
        }
    }
    return [out copy];
}

#pragma mark - /payAccountInfo/payAccountItemList → 表单结构

- (void)requestPayAccountItemList {
    [SVProgressHUD show];
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:@{}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/payAccountInfo/payAccountItemList"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCInitResponse *r = [[MKKYCInitResponse alloc] initWithDictionary:resp
                                                                     listKey:@"payAccountInfoItemDtoList"];
        if ([r isSuccess]) {
            [strongSelf.formItems removeAllObjects];
            if (r.kycItemList.count > 0) {
                [strongSelf.formItems addObjectsFromArray:r.kycItemList];
            }
            [strongSelf applyPrefillIfNeeded];
            [strongSelf applyUserNameToFormItems];
            [strongSelf.tableView reloadData];
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Failed to load"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (void)applyPrefillIfNeeded {
    if (self.prefillValues.count == 0) return;
    for (MKKYCItemModel *item in self.formItems) {
        NSString *value = self.prefillValues[item.itemCode];
        if (value.length == 0) continue;
        if ([item isPickerType]) {
            // value 可能是 buttonKey 或 buttonLabel — 先尝试 key 匹配
            for (NSInteger i = 0; i < (NSInteger)item.buttonList.count; i++) {
                MKKYCButtonModel *btn = item.buttonList[i];
                if ([btn.buttonKey isEqualToString:value] || [btn.buttonLabel isEqualToString:value]) {
                    item.selectedIndex = i;
                    item.selectedKey = btn.buttonKey;
                    item.selectedValue = btn.buttonLabel;
                    break;
                }
            }
        } else {
            item.selectedValue = value;
            item.selectedKey = value;
        }
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.formItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MKKYCItemModel *item = self.formItems[indexPath.row];
    if ([item isPickerType]) {
        MKKYCPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKKYCPickerCell cellIdentifier] forIndexPath:indexPath];
        [cell configWithTitle:item.itemName placeholder:@"Please choose"];
        [cell setSelectedValue:item.selectedValue];
        kWeakSelf
        cell.tapBlock = ^{ kStrongSelf; [strongSelf showPickerForIndex:indexPath.row]; };
        return cell;
    } else {
        MKKYCInputCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKKYCInputCell cellIdentifier] forIndexPath:indexPath];
        [cell configWithTitle:item.itemName placeholder:@"Please enter" value:item.selectedValue];
        if ([item.itemCode rangeOfString:@"card" options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [item.itemCode rangeOfString:@"account" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            cell.inputField.keyboardType = UIKeyboardTypeNumberPad;
        }
        // 259 对齐: 用户名 Name 字段锁定不可编辑 (KYC 已认证, 排除 bankName)
        BOOL isNameField = [self isUserNameItemCode:item.itemCode];
        cell.inputField.enabled = !isNameField;
        cell.inputField.textColor = isNameField
            ? [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1]
            : [UIColor blackColor];
        NSInteger row = indexPath.row;
        kWeakSelf
        cell.textChangeBlock = ^(NSString *text) {
            kStrongSelf
            strongSelf.formItems[row].selectedValue = text;
            strongSelf.formItems[row].selectedKey = text;
        };
        cell.onReturnPressed = ^{ kStrongSelf; [strongSelf scrollToNextRowAfterIndex:row]; };
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MKKYCItemModel *item = self.formItems[indexPath.row];
    if ([item isPickerType]) [self showPickerForIndex:indexPath.row];
}

- (void)showPickerForIndex:(NSInteger)index {
    [self.view endEditing:YES];
    MKKYCItemModel *item = self.formItems[index];
    if (item.buttonList.count == 0) return;

    NSMutableArray *labels = [NSMutableArray array];
    for (MKKYCButtonModel *btn in item.buttonList) [labels addObject:btn.buttonLabel];

    NSInteger currentIdx = -1;
    if (item.selectedValue.length > 0) {
        NSInteger found = [labels indexOfObject:item.selectedValue];
        if (found != NSNotFound) currentIdx = found;
    }

    kWeakSelf
    [MKPickerView showWithTitle:item.itemName options:labels selectedIndex:currentIdx
                       onSelect:^(NSInteger idx, NSString *value) {
        kStrongSelf
        item.selectedIndex = idx;
        item.selectedValue = value;
        item.selectedKey = item.buttonList[idx].buttonKey;
        [strongSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                    withRowAnimation:UITableViewRowAnimationNone];
        // 级联 (照 259 BankAccountController:354-371): 选了 Account Type 后, 触发对应 list 接口填 Bank Name 选项
        if ([strongSelf isAccountTypeCode:item.itemCode]) {
            [strongSelf loadBankNameOptionsForType:value ?: item.selectedKey];
        } else {
            [strongSelf scrollToNextRowAfterIndex:index];
        }
    }];
}

#pragma mark - 级联: Account Type → Bank Name 选项

- (BOOL)isAccountTypeCode:(NSString *)code {
    NSString *l = code.lowercaseString;
    return [l containsString:@"accounttype"] || [l containsString:@"account_type"];
}

- (BOOL)isBankNameCode:(NSString *)code {
    NSString *l = code.lowercaseString;
    return [l containsString:@"bankname"] || [l containsString:@"bank_name"];
}

/// 根据 Account Type 选中值, 调 /sys/bank 或 /sys/wallet, 填到 Bank Name 字段的 buttonList
- (void)loadBankNameOptionsForType:(NSString *)val {
    NSString *lower = val.lowercaseString;
    NSString *endpoint = nil;
    if ([lower containsString:@"wallet"]) {
        endpoint = @"/app/v3/sys/wallet";
    } else if ([lower containsString:@"bank"]) {
        endpoint = @"/app/v3/sys/bank";
    } else {
        return;
    }
    [SVProgressHUD showWithStatus:@"Loading..."];
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:@{}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:endpoint params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        if (![resp isKindOfClass:[NSDictionary class]]) return;
        if ([resp[@"resultCode"] integerValue] != 200) {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Failed to load list"];
            [SVProgressHUD dismissWithDelay:2.0];
            return;
        }
        NSArray *list = nil;
        id data = resp[@"data"];
        if ([data isKindOfClass:[NSArray class]]) {
            list = data;
        } else if ([data isKindOfClass:[NSDictionary class]]) {
            list = data[@"bankList"] ?: data[@"walletList"] ?: data[@"list"];
        }
        [strongSelf applyBankNameOptions:list];
    } failure:^(NSError *e) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
        [SVProgressHUD dismissWithDelay:2.0];
    }];
}

- (void)applyBankNameOptions:(NSArray *)list {
    if (![list isKindOfClass:[NSArray class]] || list.count == 0) return;
    NSMutableArray<MKKYCButtonModel *> *buttons = [NSMutableArray array];
    for (NSDictionary *d in list) {
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        MKKYCButtonModel *btn = [MKKYCButtonModel new];
        // 兼容多种后端命名
        id keyV = d[@"key"] ?: d[@"bankCode"] ?: d[@"code"] ?: d[@"id"];
        id labelV = d[@"label"] ?: d[@"bankName"] ?: d[@"name"];
        btn.buttonKey = [keyV isKindOfClass:[NSString class]] ? keyV : [keyV description] ?: @"";
        btn.buttonLabel = [labelV isKindOfClass:[NSString class]] ? labelV : @"";
        if (btn.buttonLabel.length > 0) [buttons addObject:btn];
    }
    if (buttons.count == 0) return;
    for (NSInteger i = 0; i < (NSInteger)self.formItems.count; i++) {
        MKKYCItemModel *it = self.formItems[i];
        if ([self isBankNameCode:it.itemCode]) {
            it.buttonList = buttons;
            it.selectedKey = @"";
            it.selectedValue = @"";
            it.selectedIndex = -1;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
    }
}

#pragma mark - 独立编辑页 — 返回直接 pop

- (void)onBackTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - /user/info → KYC 已认证 Name 自动填入

- (void)requestUserInfo {
    NSDictionary *body = [[MKEncryptManager sharedManager]
                          generateRequestBodyWithSignData:@{} requestData:@{ @"adid": @"" }];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/user/info"
                                    params:body
                                   success:^(id resp) {
        kStrongSelf
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            NSDictionary *d = resp[@"data"];
            NSString *name = [d[@"name"] isKindOfClass:[NSString class]] ? d[@"name"] : nil;
            if (name.length > 0) {
                strongSelf.userName = name;
                [strongSelf applyUserNameToFormItems];
                [strongSelf.tableView reloadData];
            }
        }
    } failure:^(NSError *e) {}];
}

/// 把 self.userName 填到用户名字段 (itemCode 含 "name" 但不含 "bank" — 排除 bankName)
- (void)applyUserNameToFormItems {
    if (self.userName.length == 0 || self.formItems.count == 0) return;
    for (MKKYCItemModel *item in self.formItems) {
        if ([self isUserNameItemCode:item.itemCode]) {
            item.selectedValue = self.userName;
            item.selectedKey = self.userName;
        }
    }
}

- (BOOL)isUserNameItemCode:(NSString *)itemCode {
    NSString *lower = itemCode.lowercaseString;
    return [lower containsString:@"name"] && ![lower containsString:@"bank"];
}

#pragma mark - Submit → /save (新建) 或 /update (编辑)

- (void)continueAction {
    [self.view endEditing:YES];
    if (![self validateFormItems]) return;
    [self submitForm];
}

- (void)submitForm {
    NSArray<NSDictionary *> *commitList = [self buildKycCommitItemList];
    if (commitList.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"No data to submit"];
        return;
    }

    BOOL isEdit = (self.bankCardBindId > 0);
    NSString *endpoint = isEdit ? @"/app/v3/payAccountInfo/update" : @"/app/v3/payAccountInfo/save";
    NSMutableDictionary *dataForRequest = [NSMutableDictionary dictionary];
    dataForRequest[@"kycCommitItemList"] = commitList;
    dataForRequest[@"defaultFlag"] = self.isDefaultAccount ? @"1" : @"0";
    if (isEdit) {
        if (self.recordId.length == 0) {
            [SVProgressHUD showErrorWithStatus:@"Bank card record ID is missing"];
            return;
        }
        dataForRequest[@"recordId"] = self.recordId;
    }

    [SVProgressHUD showWithStatus:@"Submitting..."];
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:dataForRequest];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:endpoint
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCCommitResponse *r = [[MKKYCCommitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [SVProgressHUD showSuccessWithStatus:isEdit ? @"Updated successfully" : @"Added successfully"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [strongSelf.navigationController popViewControllerAnimated:YES];
            });
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Submit failed"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (NSArray<NSDictionary *> *)buildKycCommitItemList {
    NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
    for (MKKYCItemModel *item in self.formItems) {
        if (item.itemCode.length == 0) continue;
        NSString *value = nil;
        if ([item isPickerType]) {
            value = item.selectedKey.length > 0 ? item.selectedKey : item.selectedValue;
        } else {
            value = item.selectedValue;
        }
        if (value.length == 0) continue;
        [out addObject:@{
            @"itemCode": item.itemCode,
            @"itemValueType": @1,
            @"itemValue": value
        }];
    }
    return [out copy];
}

@end
