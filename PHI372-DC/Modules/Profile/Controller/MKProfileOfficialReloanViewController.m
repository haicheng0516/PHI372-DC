//
//  MKProfileOfficialReloanViewController.m
//  个人中心-官网
//
//  设计稿 (375×812):
//    顶部绿色 nav (#385330 r=0,0,14,14 h=98), 标题 "Official Website"
//    Hint banner (18,110) 339×60 灰底 r=14 — 提示文案
//    网址卡 (18, next) 339×60 r=14 — web icon 42×42 + URL #385330 + copy btn
//    网址来自 app/config 的 officialWebsiteUrl
//

#import "MKProfileOfficialReloanViewController.h"
#import "MKConstants.h"
#import "MKHintBannerView.h"
#import "MKContactRowCell.h"
#import "MKAppConfigManager.h"

@interface MKProfileOfficialReloanViewController ()
@property (nonatomic, strong) MKContactRowCell *webRow;
@property (nonatomic, assign) CGFloat webRowY;
@end

@implementation MKProfileOfficialReloanViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Official Website";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    CGFloat y = kNavBarHeight + kScaleH(12);
    CGFloat cardW = kScaleW(339);
    CGFloat cardX = kScaleW(18);

    // Hint banner — 设计稿 y=110 说明文案
    NSString *hintText = @"When encountering issues with your app, you can also apply and repay through the official website. We recommend that you save the official website address:";
    CGFloat hintH = [MKHintBannerView heightForText:hintText];
    MKHintBannerView *hint = [[MKHintBannerView alloc] initWithText:hintText];
    hint.frame = CGRectMake(cardX, y, cardW, hintH);
    [self.view addSubview:hint];
    y += hintH + kScaleH(12);

    self.webRowY = y;
    [self rebuildWebRow];

    // 配置未就绪 → 拉取后刷新网址
    if (![[MKAppConfigManager sharedManager] hasAppConfig]) {
        __weak typeof(self) wself = self;
        [[MKAppConfigManager sharedManager] loadConfigWithCompletion:^(MKAppConfigModel *config) {
            [wself rebuildWebRow];
        }];
    }
}

- (void)rebuildWebRow {
    [self.webRow removeFromSuperview];
    NSString *url = [MKAppConfigManager sharedManager].currentAppConfig.officialWebsiteUrl ?: @"";
    self.webRow = [[MKContactRowCell alloc] initWithKind:MKContactRowKindWebsite value:url];
    self.webRow.frame = CGRectMake(kScaleW(18), self.webRowY, kScaleW(339), [MKContactRowCell cellHeight]);
    [self.view addSubview:self.webRow];
}

@end
