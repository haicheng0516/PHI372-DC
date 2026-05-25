//
//  MKDialogGalleryViewController.m
//

#import "MKDialogGalleryViewController.h"
#import "MKConstants.h"
#import "MKBottomSheetView.h"

@interface MKDialogGalleryViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *labels;
@property (nonatomic, copy) NSArray<NSNumber *> *types;
@end

@implementation MKDialogGalleryViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Dialog Gallery";
        _labels = @[
            @"1  ForceUpdate",
            @"2  NormalUpdate",
            @"3  LogoutConfirm",
            @"4  AccountDelete",
            @"5  AccountDeleteSuccess",
            @"6  AccountDeleteFail",
            @"7  BackConfirm",
            @"8  ExistingOrder",
            @"9  CommonPicker",
            @"10 RatingGuide",
            @"11 RatingSuccess",
            @"12 ProductReloan",
            @"13 RepaymentPlan",
            @"14 OrderReloan",
            @"15 HomeReloan",
            @"16 WithdrawPending",
            @"17 WithdrawSuccess",
            @"18 KYCFail",
            @"19 PermissionCamera",
            @"20 PermissionLocation",
            @"21 PermissionContacts",
        ];
        _types = @[
            @(MKBottomSheetTypeForceUpdate),
            @(MKBottomSheetTypeNormalUpdate),
            @(MKBottomSheetTypeLogoutConfirm),
            @(MKBottomSheetTypeAccountDelete),
            @(MKBottomSheetTypeAccountDeleteSuccess),
            @(MKBottomSheetTypeAccountDeleteFail),
            @(MKBottomSheetTypeBackConfirm),
            @(MKBottomSheetTypeExistingOrder),
            @(MKBottomSheetTypeCommonPicker),
            @(MKBottomSheetTypeRatingGuide),
            @(MKBottomSheetTypeRatingSuccess),
            @(MKBottomSheetTypeProductReloan),
            @(MKBottomSheetTypeRepaymentPlan),
            @(MKBottomSheetTypeOrderReloan),
            @(MKBottomSheetTypeHomeReloan),
            @(MKBottomSheetTypeWithdrawPending),
            @(MKBottomSheetTypeWithdrawSuccess),
            @(MKBottomSheetTypeKYCFail),
            @(MKBottomSheetTypePermissionCamera),
            @(MKBottomSheetTypePermissionLocation),
            @(MKBottomSheetTypePermissionContacts),
        ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kNavBarHeight, kScreenWidth, kScreenHeight - kNavBarHeight) style:UITableViewStylePlain];
    self.tableView.backgroundColor = kColorBackground;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = kScaleH(48);
    [self.view addSubview:self.tableView];

    // 自动展示 (用于自动化截图)
    NSInteger auto_ = [[NSUserDefaults standardUserDefaults] integerForKey:@"MK.DebugDialogType"];
    if (auto_ > 0 && auto_ <= (NSInteger)self.types.count) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showDialogAtIndex:auto_ - 1];
        });
    }
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return self.labels.count; }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    c.backgroundColor = kColorCardBg;
    c.textLabel.text = self.labels[ip.row];
    c.textLabel.font = kFontRegular(15);
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self showDialogAtIndex:ip.row];
}

- (void)showDialogAtIndex:(NSInteger)idx {
    MKBottomSheetType t = (MKBottomSheetType)self.types[idx].integerValue;
    NSDictionary *config = (t == MKBottomSheetTypeCommonPicker)
        ? @{ @"title": @"Relationship",
             @"items": @[@"Parent", @"Spouse", @"Sibling", @"Friend", @"Colleague"] }
        : nil;
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:t config:config];
    [sheet show];
}

@end
