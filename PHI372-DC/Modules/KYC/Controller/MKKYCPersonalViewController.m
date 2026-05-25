//  MKKYCPersonalViewController.m
//  Figma 3:891 KYC-个人信息认证
//    - /app/v3/kyc/four/search-iterm (kycId=personal) 拉表单字段
//    - province → /app/v3/sys/province; city → /app/v3/sys/city (省市级联)
//    - /app/v3/kyc/four/personal 提交, 成功后 push KYC2 Finance

#import "MKKYCPersonalViewController.h"
#import "MKConstants.h"
#import "MKKYCInputCell.h"
#import "MKKYCPickerCell.h"
#import "MKPickerView.h"
#import "MKKYCFinanceViewController.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKKYCCommitResponse.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSString * const kCountryIdPH = @"63";

@interface MKKYCPersonalViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray<NSDictionary *> *provinceList;   // [{key, label}]
@property (nonatomic, strong) NSArray<NSDictionary *> *cityList;
@property (nonatomic, copy)   NSString *selectedProvinceKey;
@end

@implementation MKKYCPersonalViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navTitle = @"Personal Information";
        self.kycId = @"personal";
        self.currentStep = 1;     // KYC step 1/4
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

#pragma mark - DataSource

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

#pragma mark - Picker 分发: province / city / 普通

- (void)showPickerForIndex:(NSInteger)index {
    [self.view endEditing:YES];
    MKKYCItemModel *item = self.formItems[index];
    if ([item.itemCode isEqualToString:@"province"]) {
        [self showProvincePickerAtIndex:index];
    } else if ([item.itemCode isEqualToString:@"city"]) {
        [self showCityPickerAtIndex:index];
    } else {
        [self showNormalPickerAtIndex:index];
    }
}

- (void)showNormalPickerAtIndex:(NSInteger)index {
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

#pragma mark - 省份 Picker (/app/v3/sys/province)

- (void)showProvincePickerAtIndex:(NSInteger)index {
    if (self.provinceList.count > 0) {
        [self presentProvincePickerAtIndex:index];
        return;
    }
    [SVProgressHUD show];
    NSDictionary *params = [[MKEncryptManager sharedManager] generateRequestBody:@{@"countryId": kCountryIdPH}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/sys/province"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        NSArray *list = [strongSelf parseAreaList:resp key:@"provinceList"];
        if (list.count > 0) {
            strongSelf.provinceList = list;
            [strongSelf presentProvincePickerAtIndex:index];
        } else {
            [SVProgressHUD showErrorWithStatus:@"Failed to load provinces"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (void)presentProvincePickerAtIndex:(NSInteger)index {
    MKKYCItemModel *item = self.formItems[index];
    NSMutableArray *labels = [NSMutableArray array];
    for (NSDictionary *p in self.provinceList) [labels addObject:p[@"label"] ?: @""];

    NSInteger currentIdx = -1;
    if (item.selectedValue.length > 0) {
        currentIdx = [labels indexOfObject:item.selectedValue];
        if (currentIdx == NSNotFound) currentIdx = -1;
    }

    kWeakSelf
    [MKPickerView showWithTitle:item.itemName options:labels selectedIndex:currentIdx
                       onSelect:^(NSInteger idx, NSString *value) {
        kStrongSelf
        item.selectedIndex = idx;
        item.selectedValue = value;
        item.selectedKey = strongSelf.provinceList[idx][@"key"] ?: @"";
        strongSelf.selectedProvinceKey = item.selectedKey;
        [strongSelf clearCitySelection];
        [strongSelf.tableView reloadData];
        [strongSelf scrollToNextRowAfterIndex:index];
    }];
}

#pragma mark - 城市 Picker (/app/v3/sys/city)

- (void)showCityPickerAtIndex:(NSInteger)index {
    if (self.selectedProvinceKey.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"Please select province first"];
        return;
    }
    if (self.cityList.count > 0) {
        [self presentCityPickerAtIndex:index];
        return;
    }
    [SVProgressHUD show];
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBody:@{@"countryId": kCountryIdPH,
                                                  @"provinceId": self.selectedProvinceKey}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/sys/city"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        NSArray *list = [strongSelf parseAreaList:resp key:@"cityList"];
        if (list.count > 0) {
            strongSelf.cityList = list;
            [strongSelf presentCityPickerAtIndex:index];
        } else {
            [SVProgressHUD showErrorWithStatus:@"Failed to load cities"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

- (void)presentCityPickerAtIndex:(NSInteger)index {
    MKKYCItemModel *item = self.formItems[index];
    NSMutableArray *labels = [NSMutableArray array];
    for (NSDictionary *c in self.cityList) [labels addObject:c[@"label"] ?: @""];

    NSInteger currentIdx = -1;
    if (item.selectedValue.length > 0) {
        currentIdx = [labels indexOfObject:item.selectedValue];
        if (currentIdx == NSNotFound) currentIdx = -1;
    }

    kWeakSelf
    [MKPickerView showWithTitle:item.itemName options:labels selectedIndex:currentIdx
                       onSelect:^(NSInteger idx, NSString *value) {
        kStrongSelf
        item.selectedIndex = idx;
        item.selectedValue = value;
        item.selectedKey = strongSelf.cityList[idx][@"key"] ?: @"";
        [strongSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                    withRowAnimation:UITableViewRowAnimationNone];
        [strongSelf scrollToNextRowAfterIndex:index];
    }];
}

#pragma mark - 省市 utils

- (void)clearCitySelection {
    self.cityList = nil;
    for (MKKYCItemModel *item in self.formItems) {
        if ([item.itemCode isEqualToString:@"city"]) {
            item.selectedValue = nil;
            item.selectedKey = nil;
            item.selectedIndex = -1;
            break;
        }
    }
}

- (NSArray<NSDictionary *> *)parseAreaList:(id)resp key:(NSString *)listKey {
    if (![resp isKindOfClass:[NSDictionary class]]) return @[];
    NSDictionary *r = (NSDictionary *)resp;
    if ([r[@"resultCode"] integerValue] != 200) return @[];

    NSDictionary *data = r[@"data"];
    if (![data isKindOfClass:[NSDictionary class]]) return @[];
    NSArray *arr = data[listKey];
    if (![arr isKindOfClass:[NSArray class]]) return @[];

    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *d in arr) {
        if (![d isKindOfClass:[NSDictionary class]]) continue;
        NSString *key = [NSString stringWithFormat:@"%@", d[@"key"] ?: @""];
        NSString *label = [NSString stringWithFormat:@"%@", d[@"label"] ?: @""];
        NSNumber *sort = d[@"sort"] ?: @(0);
        if (label.length > 0) [out addObject:@{@"key": key, @"label": label, @"sort": sort}];
    }
    [out sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"sort"] integerValue] - [b[@"sort"] integerValue];
    }];
    return [out copy];
}

#pragma mark - Continue → 提交

- (void)continueAction {
    [self.view endEditing:YES];
    if (![self validateFormItems]) return;
    [self submitPersonalInfo];
}

- (void)submitPersonalInfo {
    [SVProgressHUD show];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (MKKYCItemModel *item in self.formItems) {
        if (item.itemCode.length == 0) continue;
        data[item.itemCode] = item.selectedKey ?: item.selectedValue ?: @"";
    }
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:data];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/personal"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCCommitResponse *r = [[MKKYCCommitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [strongSelf.navigationController pushViewController:[MKKYCFinanceViewController new] animated:YES];
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Submit failed"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Network error"];
    }];
}

@end
