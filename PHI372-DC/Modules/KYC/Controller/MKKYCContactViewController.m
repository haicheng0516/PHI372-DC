//  MKKYCContactViewController.m
//  Figma 3:1044 KYC-紧急联系人
//    - self.contacts: NSMutableArray<NSMutableDictionary*>, 3 个 dict (relation/relationKey/name/phone)
//    - self.relationOptions / self.relationKeys: 从 /kyc/four/search-iterm 拿 buttonList[].label/key
//    - self.emailValue: NSString
//    - relation 选 → contacts[i][relation]=label, contacts[i][relationKey]=key
//    - 通讯录回填 → contacts[i][name]=fullName, [phone]=filter+strip63+strip0
//    - submit: 拼 prefix dict, email 非空才挂; relationKey 为优先值, fallback relation

#import "MKKYCContactViewController.h"
#import "MKKYCInputCell.h"
#import "MKKYCPickerCell.h"
#import "MKKYCContactCombinedCell.h"
#import "MKConstants.h"
#import "MKPickerView.h"
#import "MKKYCIDViewController.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKKYCInitResponse.h"
#import "MKKYCCommitResponse.h"
#import "MKPhoneValidator.h"
#import <Masonry/Masonry.h>
#import <ContactsUI/ContactsUI.h>
#import <SVProgressHUD/SVProgressHUD.h>

static const NSInteger kContactCount = 3;

@interface MKKYCContactViewController () <UITableViewDataSource, UITableViewDelegate, CNContactPickerDelegate>
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *contacts;
@property (nonatomic, strong) NSArray<NSString *> *relationOptions;
@property (nonatomic, strong) NSArray<NSString *> *relationKeys;
@property (nonatomic, assign) NSInteger currentContactIndex;
@property (nonatomic, copy) NSString *emailValue;
@property (nonatomic, copy) NSString *phoneRegex;
@property (nonatomic, copy) NSString *nameRegex;
// UI section 标题
@property (nonatomic, copy) NSArray<NSString *> *sectionTitles;
@end

@implementation MKKYCContactViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navTitle = @"Emergency Contact";
        self.kycId = @"urgent_contact";
        self.currentStep = 3;
        _contacts = [NSMutableArray array];
        for (NSInteger i = 0; i < kContactCount; i++) {
            [_contacts addObject:[@{@"relation": @"", @"relationKey": @"",
                                    @"name": @"", @"phone": @""} mutableCopy]];
        }
        _emailValue = @"";
        _currentContactIndex = -1;
        _sectionTitles = @[ @"Contact 1", @"Contact 2", @"Contact 3", @"E-Mail" ];
    }
    return self;
}

- (NSString *)continueButtonTitle { return @"Continue"; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[MKKYCContactCombinedCell class]
           forCellReuseIdentifier:NSStringFromClass([MKKYCContactCombinedCell class])];
}

- (void)loadFormItems {
    // Base 默认会调 requestFormItems(走 base 的 search-iterm)。我们 KYC3 自定义抓 relationOptions, 不用 base 的字段填充
    [self requestFormItems];
}

#pragma mark - 拉 relationOptions / relationKeys

- (void)requestFormItems {
    if (self.kycId.length == 0) return;
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{}
                            requestData:@{@"kycId": self.kycId}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/search-iterm"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        MKKYCInitResponse *r = [[MKKYCInitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            for (MKKYCItemModel *item in r.kycItemList) {
                // 关系选项: 取第一个 picker 类带 buttonList 的字段
                if ([item isPickerType] && item.buttonList.count > 0 && strongSelf.relationOptions.count == 0) {
                    NSMutableArray *labels = [NSMutableArray array];
                    NSMutableArray *keys = [NSMutableArray array];
                    for (MKKYCButtonModel *btn in item.buttonList) {
                        [labels addObject:btn.buttonLabel ?: @""];
                        [keys addObject:btn.buttonKey ?: @""];
                    }
                    strongSelf.relationOptions = [labels copy];
                    strongSelf.relationKeys = [keys copy];
                }
                NSString *code = item.itemCode.lowercaseString;
                if ([code containsString:@"phone"] && item.regularExpression.length > 0 && strongSelf.phoneRegex.length == 0) {
                    strongSelf.phoneRegex = item.regularExpression;
                }
                if ([code containsString:@"name"] && item.regularExpression.length > 0 && strongSelf.nameRegex.length == 0) {
                    strongSelf.nameRegex = item.regularExpression;
                }
            }
        }
        if (strongSelf.relationOptions.count == 0) {
            // 后端没返时, fallback
            strongSelf.relationOptions = @[@"Parent", @"Spouse", @"Sibling", @"Friend", @"Colleague", @"Other"];
            strongSelf.relationKeys = @[@"parent", @"spouse", @"sibling", @"friend", @"colleague", @"other"];
        }
    } failure:^(NSError *e) {
        kStrongSelf
        strongSelf.relationOptions = @[@"Parent", @"Spouse", @"Sibling", @"Friend", @"Colleague", @"Other"];
        strongSelf.relationKeys = @[@"parent", @"spouse", @"sibling", @"friend", @"colleague", @"other"];
    }];
}

#pragma mark - DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sectionTitles.count; }

// 每个 Contact section: row0=Relationship, row1=合并 Name/Phone. Email section 只 1 行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section < kContactCount ? 2 : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 94;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // E-Mail section (section==3)
    if (indexPath.section == kContactCount) {
        MKKYCInputCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKKYCInputCell cellIdentifier] forIndexPath:indexPath];
        [cell configWithTitle:@"E-Mail" placeholder:@"Please enter" value:self.emailValue];
        cell.inputField.keyboardType = UIKeyboardTypeEmailAddress;
        kWeakSelf
        cell.textChangeBlock = ^(NSString *text) {
            kStrongSelf
            strongSelf.emailValue = text ?: @"";
        };
        return cell;
    }

    // Contact section
    NSInteger idx = indexPath.section;
    NSDictionary *contact = self.contacts[idx];

    if (indexPath.row == 0) {
        // Relationship picker cell
        MKKYCPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:[MKKYCPickerCell cellIdentifier] forIndexPath:indexPath];
        [cell configWithTitle:@"Relationship" placeholder:@"Please choose"];
        [cell setSelectedValue:contact[@"relation"]];
        kWeakSelf
        cell.tapBlock = ^{
            kStrongSelf
            [strongSelf showRelationPickerForIndex:idx];
        };
        return cell;
    }

    // row 1: 合并 Name/Phone 卡
    MKKYCContactCombinedCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([MKKYCContactCombinedCell class]) forIndexPath:indexPath];
    [cell configWithName:contact[@"name"] phone:contact[@"phone"]];
    kWeakSelf
    cell.onPickContactTapped = ^{
        kStrongSelf
        [strongSelf selectContactForIndex:idx];
    };
    cell.onPhoneChanged = ^(NSString *phone) {
        kStrongSelf
        strongSelf.contacts[idx][@"phone"] = phone ?: @"";
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < kContactCount && indexPath.row == 0) {
        [self showRelationPickerForIndex:indexPath.section];
    }
}

#pragma mark - section header/footer

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 44; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 8; }

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = kColorCardSecondary;

    BOOL hasIcon = (section < kContactCount);
    UIView *icon = nil;
    if (hasIcon) {
        icon = [UIView new];
        icon.backgroundColor = kColorContactIconGreen;
        icon.layer.cornerRadius = 12;
        icon.layer.masksToBounds = YES;
        [header addSubview:icon];
        [icon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(header).offset(20);
            make.bottom.equalTo(header).offset(-10);
            make.width.height.mas_equalTo(24);
        }];
    }

    UILabel *title = [UILabel new];
    title.text = self.sectionTitles[section];
    title.font = kFontSemibold(14);
    title.textColor = kColorTextPrimary;
    [header addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        if (hasIcon) {
            make.left.equalTo(icon.mas_right).offset(8);
        } else {
            make.left.equalTo(header).offset(20);
        }
        make.right.equalTo(header).offset(-20);
        make.bottom.equalTo(header).offset(-8);
        make.height.mas_equalTo(24);
    }];
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [UIView new]; footer.backgroundColor = kColorCardSecondary; return footer;
}

#pragma mark - Relation picker

- (void)showRelationPickerForIndex:(NSInteger)idx {
    [self.view endEditing:YES];
    if (self.relationOptions.count == 0) {
        [SVProgressHUD showInfoWithStatus:@"Loading options..."];
        [self requestFormItems];
        return;
    }

    NSString *currentRelation = self.contacts[idx][@"relation"];
    NSInteger currentIdx = -1;
    if (currentRelation.length > 0) {
        NSInteger found = [self.relationOptions indexOfObject:currentRelation];
        if (found != NSNotFound) currentIdx = found;
    }

    kWeakSelf
    [MKPickerView showWithTitle:@"Relationship"
                        options:self.relationOptions
                  selectedIndex:currentIdx
                       onSelect:^(NSInteger selectedIdx, NSString *value) {
        kStrongSelf
        strongSelf.contacts[idx][@"relation"] = value ?: @"";
        if (selectedIdx >= 0 && selectedIdx < (NSInteger)strongSelf.relationKeys.count) {
            strongSelf.contacts[idx][@"relationKey"] = strongSelf.relationKeys[selectedIdx];
        }
        [strongSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:idx]]
                                    withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - 通讯录

- (void)selectContactForIndex:(NSInteger)idx {
    [self.view endEditing:YES];
    self.currentContactIndex = idx;
    CNContactPickerViewController *picker = [[CNContactPickerViewController alloc] init];
    picker.delegate = self;
    picker.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)contactPicker:(CNContactPickerViewController *)picker
didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNContact *contact = contactProperty.contact;
    NSString *fullName = [NSString stringWithFormat:@"%@ %@",
                          contact.givenName ?: @"", contact.familyName ?: @""];
    fullName = [fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *phone = @"";
    if ([contactProperty.value isKindOfClass:[CNPhoneNumber class]]) {
        NSString *rawPhone = ((CNPhoneNumber *)contactProperty.value).stringValue;
        phone = [MKPhoneValidator normalizeFromContact:rawPhone];
    }

    NSString *nameError = [self validateName:fullName];
    if (nameError) {
        [SVProgressHUD showErrorWithStatus:nameError];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }
    NSString *phoneError = [self validatePhone:phone forCurrentIndex:self.currentContactIndex];
    if (phoneError) {
        [SVProgressHUD showErrorWithStatus:phoneError];
        [SVProgressHUD dismissWithDelay:2.0];
        return;
    }

    NSInteger idx = self.currentContactIndex;
    if (idx >= 0 && idx < (NSInteger)self.contacts.count) {
        self.contacts[idx][@"name"] = fullName;
        self.contacts[idx][@"phone"] = phone;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:idx]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - 校验

- (NSString *)validateName:(NSString *)name {
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length == 0) return @"Name cannot be empty";
    if (self.nameRegex.length > 0) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", self.nameRegex];
        if (![p evaluateWithObject:name]) return @"Invalid name format";
    }
    return nil;
}

- (NSString *)validatePhone:(NSString *)phone forCurrentIndex:(NSInteger)currentIdx {
    phone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (phone.length == 0) return @"Phone number cannot be empty";
    if (self.phoneRegex.length > 0) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", self.phoneRegex];
        if (![p evaluateWithObject:phone]) return @"Invalid phone number format";
    }
    for (NSInteger i = 0; i < (NSInteger)self.contacts.count; i++) {
        if (i == currentIdx) continue;
        NSString *other = self.contacts[i][@"phone"] ?: @"";
        if (other.length > 0 && [other isEqualToString:phone]) {
            return @"Phone number already exists in another contact";
        }
    }
    return nil;
}

#pragma mark - Submit

- (void)continueAction {
    [self.view endEditing:YES];

    // 校验联系人数据
    NSMutableArray<NSString *> *seenPhones = [NSMutableArray array];
    for (NSInteger i = 0; i < kContactCount; i++) {
        NSDictionary *c = self.contacts[i];
        if (((NSString *)c[@"relation"]).length == 0) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Please select relation for Contact %ld", (long)(i + 1)]];
            [SVProgressHUD dismissWithDelay:2.0];
            return;
        }
        NSString *name = [(NSString *)c[@"name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (name.length == 0) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Please select contact for Contact %ld", (long)(i + 1)]];
            [SVProgressHUD dismissWithDelay:2.0];
            return;
        }
        NSString *phone = [(NSString *)c[@"phone"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
        if (phone.length == 0) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Please pick a valid phone for Contact %ld", (long)(i + 1)]];
            [SVProgressHUD dismissWithDelay:2.0];
            return;
        }
        if ([seenPhones containsObject:phone]) {
            [SVProgressHUD showErrorWithStatus:@"Two contacts share the same phone, please pick a different one"];
            [SVProgressHUD dismissWithDelay:2.0];
            return;
        }
        [seenPhones addObject:phone];
    }

    [self submitContactInfo];
}

- (void)submitContactInfo {
    [SVProgressHUD show];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSArray *prefixes = @[@"first", @"second", @"third"];
    for (NSInteger i = 0; i < kContactCount && i < (NSInteger)prefixes.count; i++) {
        NSString *prefix = prefixes[i];
        NSDictionary *c = self.contacts[i];
        data[[NSString stringWithFormat:@"%@_relation", prefix]] = c[@"relationKey"] ?: c[@"relation"] ?: @"";
        data[[NSString stringWithFormat:@"%@_name", prefix]] = c[@"name"] ?: @"";
        data[[NSString stringWithFormat:@"%@_phone", prefix]] = c[@"phone"] ?: @"";
    }
    if (self.emailValue.length > 0) {
        data[@"email"] = self.emailValue;
    }

    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{}
                            requestData:data];

    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/contact"
                                    params:params
                                   success:^(id responseObject) {
        [SVProgressHUD dismiss];
        MKKYCCommitResponse *resp = [[MKKYCCommitResponse alloc] initWithDictionary:responseObject];
        if ([resp isSuccess]) {
            [self.navigationController pushViewController:[[MKKYCIDViewController alloc] init] animated:YES];
        } else {
            [SVProgressHUD showErrorWithStatus:resp.resultMsg ?: @"Submit failed"];
            [SVProgressHUD dismissWithDelay:2.0];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"Network error"];
        [SVProgressHUD dismissWithDelay:2.0];
    }];
}

@end
