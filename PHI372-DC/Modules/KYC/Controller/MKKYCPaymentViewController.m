//
//  MKKYCPaymentViewController.m
//  Figma 3:983 KYC-支付认证 (银行卡信息) — 用户决策: 不在 KYC 主链路, 属产品申请流(下单前绑卡).
//  接口对齐 PHI259-DC BankAccountController:
//    POST /app/v3/payAccountInfo/payAccountItemList → 拉表单字段 (payAccountInfoItemDtoList)
//    POST /app/v3/payAccountInfo/save → 新建绑卡 (kycCommitItemList + defaultFlag)
//

#import "MKKYCPaymentViewController.h"
#import "MKConstants.h"
#import "MKKYCInputCell.h"
#import "MKKYCPickerCell.h"
#import "MKPickerView.h"
#import "MKKYCInitResponse.h"
#import "MKKYCCommitResponse.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKKYCPaymentViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation MKKYCPaymentViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navTitle = @"Bank Account";
        self.showsProgressBar = NO;   // Pencil: 独立绑卡流程, 不在 KYC 4步进度条内
    }
    return self;
}

- (NSString *)continueButtonTitle { return @"Apply now"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self setupHintHeader];
}

/// Pencil dk4JG: 米色圆角卡片内嵌 hint 图标 + 提示文字
- (void)setupHintHeader {
    CGFloat hintHeight = 71.0;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, hintHeight + 12)];
    header.backgroundColor = [UIColor clearColor];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0xe9/255.0 green:0xe9/255.0 blue:0xe4/255.0 alpha:1];
    card.layer.cornerRadius = 14;
    card.layer.masksToBounds = YES;
    [header addSubview:card];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:header.topAnchor constant:0],
        [card.leftAnchor constraintEqualToAnchor:header.leftAnchor constant:0],
        [card.rightAnchor constraintEqualToAnchor:header.rightAnchor constant:0],
        [card.heightAnchor constraintEqualToConstant:hintHeight]
    ]];

    // hint 图标占位 (Pencil: jt2xg 24x24, x:27 y:118-110=8)
    UIView *iconPlaceholder = [[UIView alloc] init];
    iconPlaceholder.backgroundColor = [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:0.4];
    iconPlaceholder.layer.cornerRadius = 4;
    [card addSubview:iconPlaceholder];
    iconPlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [iconPlaceholder.leftAnchor constraintEqualToAnchor:card.leftAnchor constant:16],
        [iconPlaceholder.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [iconPlaceholder.widthAnchor constraintEqualToConstant:24],
        [iconPlaceholder.heightAnchor constraintEqualToConstant:24]
    ]];

    // 提示文字 (Pencil: S82H8, 14pt, #999999)
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"Please enter correct, available, unfrozen bank account information for the loan to be credited.";
    hintLabel.font = [UIFont systemFontOfSize:14];
    hintLabel.textColor = [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1];
    hintLabel.numberOfLines = 0;
    hintLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [card addSubview:hintLabel];
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [hintLabel.leftAnchor constraintEqualToAnchor:iconPlaceholder.rightAnchor constant:8],
        [hintLabel.rightAnchor constraintEqualToAnchor:card.rightAnchor constant:-12],
        [hintLabel.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]
    ]];

    self.tableView.tableHeaderView = header;
}

- (void)loadFormItems {
    [self requestPayAccountItemList];
}

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
            [strongSelf.tableView reloadData];
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Failed to load"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
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
        [strongSelf scrollToNextRowAfterIndex:index];
    }];
}

#pragma mark - 拦截返回 — 独立页面直接 pop, 不走 KYC 返回确认

- (void)onBackTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Submit → /payAccountInfo/save

- (void)continueAction {
    [self.view endEditing:YES];
    if (![self validateFormItems]) return;
    [self submitBankAccount];
}

- (void)submitBankAccount {
    NSArray<NSDictionary *> *commitList = [self buildKycCommitItemList];
    if (commitList.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"No data to submit"];
        return;
    }
    NSDictionary *dataForRequest = @{
        @"kycCommitItemList": commitList,
        @"defaultFlag": @"1"
    };
    [SVProgressHUD showWithStatus:@"Submitting..."];
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:dataForRequest];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/payAccountInfo/save"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCCommitResponse *r = [[MKKYCCommitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [SVProgressHUD showSuccessWithStatus:@"Added successfully"];
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
