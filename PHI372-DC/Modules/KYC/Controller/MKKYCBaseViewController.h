//
//  MKKYCBaseViewController.h
//  PHI372-DC
//
//  KYC 流程基类
//  封装: NavBar(深绿) + 顶部进度条 + UITableView + 底部固定 Continue 按钮.
//  子类只需设置 kycId / progressPercent / 数据源 / continueAction.
//

#import "MKBaseViewController.h"
#import "MKKYCItemModel.h"
#import "MKKYCProgressBarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKKYCBaseViewController : MKBaseViewController

/// KYC 字段标识 (search-iterm 拉表单用; e.g. "personal" / "work_questionnaire" / "urgent_contact")
@property (nonatomic, copy, nullable) NSString *kycId;

/// 表单数据源
@property (nonatomic, strong) NSMutableArray<MKKYCItemModel *> *formItems;

/// 公共组件
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIButton *continueButton;
@property (nonatomic, strong, readonly) MKKYCProgressBarView *progressBar;

/// KYC 共 4 步: Personal=1, Finance=2, Contact=3, ID=4. 子类 init 时设, 默认 1
@property (nonatomic, assign) NSInteger currentStep;

/// 是否显示顶部 KYC 进度条 (Payment/BankCardEdit 独立页面设 NO). 默认 YES.
@property (nonatomic, assign) BOOL showsProgressBar;

#pragma mark - 子类重写

- (NSString *)continueButtonTitle;
- (void)continueAction;
/// 子类在 viewDidLoad 调一次, 装填 self.formItems 并刷 tableView. 默认空实现.
- (void)loadFormItems;

#pragma mark - 通用方法

/// 必填 + 正则校验, 返回 YES 全通过
- (BOOL)validateFormItems;

/// 接 /app/v3/kyc/four/search-iterm 拉表单字段, 成功后填 self.formItems 并 reload tableView.
/// 调用前必须设置 self.kycId (e.g. "personal" / "work_questionnaire" / "urgent_contact" / "identity_liveness").
- (void)requestFormItems;

/// 收集所有 selectedKey 用于提交 (key = itemCode)
- (NSDictionary<NSString *, NSString *> *)collectFormValues;

/// 当前行选完自动滚到下一行 (picker → 自动弹, input → 自动 focus)
- (void)scrollToNextRowAfterIndex:(NSInteger)index;

/// 返回前弹确认弹窗
- (void)showBackConfirmDialog;

@end

NS_ASSUME_NONNULL_END
