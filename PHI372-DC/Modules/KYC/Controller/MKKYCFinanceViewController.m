//  MKKYCFinanceViewController.m
//  Figma 3:936 KYC-财务状况 (对应 334  Work Information)
//    - /app/v3/kyc/four/search-iterm (kycId=work_questionnaire) 拉表单字段
//    - /app/v3/kyc/four/work 提交, 成功后 push KYC3 Contact

#import "MKKYCFinanceViewController.h"
#import "MKConstants.h"
#import "MKKYCInputCell.h"
#import "MKKYCPickerCell.h"
#import "MKPickerView.h"
#import "MKKYCContactViewController.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKKYCCommitResponse.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKKYCFinanceViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation MKKYCFinanceViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navTitle = @"Credit Standing";
        self.kycId = @"work_questionnaire";
        self.currentStep = 2;     // KYC step 2/4
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)loadFormItems {
    [self requestFormItems];
}

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

- (void)continueAction {
    [self.view endEditing:YES];
    if (![self validateFormItems]) return;
    [self submitWorkInfo];
}

- (void)submitWorkInfo {
    [SVProgressHUD show];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (MKKYCItemModel *item in self.formItems) {
        if (item.itemCode.length == 0) continue;
        data[item.itemCode] = item.selectedKey ?: item.selectedValue ?: @"";
    }
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:data];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/work"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCCommitResponse *r = [[MKKYCCommitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [strongSelf.navigationController pushViewController:[MKKYCContactViewController new] animated:YES];
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Submit failed"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

@end
