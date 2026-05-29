//  MKOrderListViewController.m
//  PHI372-DC — Figma 3:599 历史订单 (accordion)
//  布局精确还原 Figma 3:599 (375×812):
//    顶部 Rectangle 4232 (0,0,375,484) linear-gradient 180° #385330 27% → #F8F8F7 53%
//    状态栏 0,0,375,44; 返回箭头 (30,64) 24×24 白; 标题 "Order" (164,64) 白
//    4 个 accordion 卡片堆叠 (左右 margin=15):
//      Card #1 "Submit Application" (15,108) 345×441 (展开态) r=14 白
//        title text (29,129) 144×14, PingFang SC 500 16, #16171D
//        chevron up (327,126) 20×20 绿
//        子卡片 #1 (28,156) 319×117 r=14 #F8F8F7 (含 chip + ₱amount + 产品名 + 日期 + 分隔线)
//        子卡片 #2 (28,287) 319×117 ...
//        子卡片 #3 (28,418) 319×117 ...
//      Card #2 "Pending Repayment" (15,563) 345×57 collapsed
//      Card #3 "Processing"        (15,634) 345×57 collapsed
//      Card #4 "Completed"         (15,705) 345×57 collapsed
//    Collapsed 高 = 57; Expanded 高 = 48 + 131*N (N = 子卡片数)
//    子卡片结构:
//      chip BG (199-28,164-156)=(171,8) chipW×28 r=6  fill 状态色
//      chip text (居中)
//      ₱ amount (12,18) Inter 600 28
//      product name (右下角 chip 下方) #171718
//      divider (9,74) 301×1 #E9E9E4
//      "Date of application:" label (12,88) #C7C7C7
//      date value (右, 88) #171718

#import "MKOrderListViewController.h"
#import "MKConstants.h"
#import "MKOrderDetailViewController.h"
#import "MKOrderListModel.h"
#import "MKOrderStatusMapper.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "MKRejectFlowCoordinator.h"

#pragma mark - 金额/日期格式化辅助

static NSString *MKFormatOrderAmount(NSString *raw) {
    if (raw.length == 0) return @"₱ 0";
    NSNumberFormatter *f = [NSNumberFormatter new];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    f.maximumFractionDigits = 0;
    NSNumber *n = @([raw doubleValue]);
    NSString *s = [f stringFromNumber:n] ?: raw;
    return [NSString stringWithFormat:@"₱ %@", s];
}

/// "2025-03-18 12:34:56" / "2025-03-18" → "Mar 18, 2025"; 解析失败原样返回
static NSString *MKFormatOrderDate(NSString *raw) {
    if (raw.length == 0) return @"";
    static NSArray<NSDateFormatter *> *inputs;
    static NSDateFormatter *output;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDateFormatter *a = [NSDateFormatter new]; a.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSDateFormatter *b = [NSDateFormatter new]; b.dateFormat = @"yyyy-MM-dd";
        NSDateFormatter *c = [NSDateFormatter new]; c.dateFormat = @"yyyy/MM/dd HH:mm:ss";
        NSDateFormatter *d = [NSDateFormatter new]; d.dateFormat = @"yyyy/MM/dd";
        inputs = @[a, b, c, d];
        output = [NSDateFormatter new];
        output.dateFormat = @"MMM dd, yyyy";
        output.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
    for (NSDateFormatter *df in inputs) {
        NSDate *date = [df dateFromString:raw];
        if (date) return [output stringFromDate:date];
    }
    return raw;
}

#pragma mark - Order Sub-Card View (319×117)

@interface MKOrderSubCard : UIControl
- (void)configureAmount:(NSString *)amt
              chipTitle:(NSString *)chipTitle
              chipColor:(UIColor *)chipColor
                product:(NSString *)product
              dateLabel:(NSString *)dateLabel
              dateValue:(NSString *)dateValue;
@end

@implementation MKOrderSubCard {
    UILabel *_amount; UIView *_chipBg; UILabel *_chipLabel; UILabel *_product;
    UIView *_divider; UILabel *_dateLabel; UILabel *_dateValue;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = MKHexColor(0xF8F8F7);
        self.layer.cornerRadius = kScaleH(14);
        self.clipsToBounds = YES;

        _amount = [UILabel new];
        _amount.font = [UIFont systemFontOfSize:kScaleW(28) weight:UIFontWeightSemibold];  // Pencil Inter 600 28
        _amount.textColor = MKHexColor(0x000000);
        [self addSubview:_amount];

        _chipBg = [UIView new];
        _chipBg.layer.cornerRadius = kScaleH(6);
        [self addSubview:_chipBg];

        _chipLabel = [UILabel new];
        _chipLabel.font = kFontRegular(12);
        _chipLabel.textColor = kColorWhite;
        _chipLabel.textAlignment = NSTextAlignmentCenter;
        [_chipBg addSubview:_chipLabel];

        _product = [UILabel new];
        _product.font = kFontRegular(14);  // Pencil 14
        _product.textColor = MKHexColor(0x171718);
        _product.textAlignment = NSTextAlignmentRight;
        [self addSubview:_product];

        _divider = [UIView new];
        _divider.backgroundColor = MKHexColor(0xE9E9E4);
        [self addSubview:_divider];

        _dateLabel = [UILabel new];
        _dateLabel.font = kFontRegular(14);  // Pencil 14
        _dateLabel.textColor = MKHexColor(0xC7C7C7);
        [self addSubview:_dateLabel];

        _dateValue = [UILabel new];
        _dateValue.font = kFontRegular(14);  // Pencil PingFang SC 14 regular
        _dateValue.textColor = MKHexColor(0x171718);
        _dateValue.textAlignment = NSTextAlignmentRight;
        [self addSubview:_dateValue];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    // ₱ amount  (12, 18) Inter 600 28 — 居左, 大字
    _amount.frame = CGRectMake(kScaleW(12), kScaleH(18), kScaleW(180), kScaleH(36));

    // Status chip — 右上, 自适应宽度
    CGSize chipSize = [_chipLabel.text sizeWithAttributes:@{NSFontAttributeName: _chipLabel.font}];
    CGFloat chipW = ceilf(chipSize.width) + kScaleW(20);
    CGFloat chipH = kScaleH(28);  // Pencil chip height 28
    CGFloat chipX = w - kScaleW(12) - chipW;
    CGFloat chipY = kScaleH(14);
    _chipBg.frame = CGRectMake(chipX, chipY, chipW, chipH);
    _chipLabel.frame = _chipBg.bounds;

    // Product name — chip 下方, 右对齐
    _product.frame = CGRectMake(w * 0.4, CGRectGetMaxY(_chipBg.frame) + kScaleH(6),
                                 w - w * 0.4 - kScaleW(12), kScaleH(18));

    // Divider (9,74) 301×1
    _divider.frame = CGRectMake(kScaleW(9), kScaleH(74), w - kScaleW(18), 1);

    // Date row — y=88
    _dateLabel.frame = CGRectMake(kScaleW(12), kScaleH(86), kScaleW(160), kScaleH(20));
    _dateValue.frame = CGRectMake(w * 0.45, kScaleH(86), w - w * 0.45 - kScaleW(12), kScaleH(20));
}

- (void)configureAmount:(NSString *)amt
              chipTitle:(NSString *)chipTitle
              chipColor:(UIColor *)chipColor
                product:(NSString *)product
              dateLabel:(NSString *)dateLabel
              dateValue:(NSString *)dateValue {
    _amount.text = amt;
    _chipLabel.text = chipTitle;
    _chipBg.backgroundColor = chipColor;
    _product.text = product;
    _dateLabel.text = dateLabel;
    _dateValue.text = dateValue;
    [self setNeedsLayout];
}
@end

#pragma mark - Accordion Section View

@interface MKOrderAccordionSection : UIView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, copy) NSArray<NSDictionary *> *items;
@property (nonatomic, copy) void (^onToggle)(void);
@property (nonatomic, copy) void (^onItemTap)(NSInteger idx);
- (CGFloat)heightForCurrentState;
- (void)reload;
@end

@implementation MKOrderAccordionSection {
    UIControl *_titleRow; UILabel *_titleLabel; UIImageView *_chevron;
    NSMutableArray<MKOrderSubCard *> *_cards;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = MKHexColor(0xE9E9E4);  // Pencil #e9e9e4 section header bg
        self.layer.cornerRadius = kScaleH(14);
        self.clipsToBounds = YES;

        _titleRow = [UIControl new];
        _titleRow.backgroundColor = [UIColor clearColor];
        [_titleRow addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_titleRow];

        _titleLabel = [UILabel new];
        _titleLabel.font = kFontSemibold(16);  // Pencil PingFang SC 500 16
        _titleLabel.textColor = MKHexColor(0x16171D);
        [_titleRow addSubview:_titleLabel];

        _chevron = [UIImageView new];
        _chevron.tintColor = kColorPrimary;
        _chevron.contentMode = UIViewContentModeScaleAspectFit;
        [_titleRow addSubview:_chevron];

        _cards = [NSMutableArray array];
    }
    return self;
}

- (void)setTitle:(NSString *)title { _title = [title copy]; _titleLabel.text = title; [self setNeedsLayout]; }
- (void)setExpanded:(BOOL)expanded { _expanded = expanded; [self updateChevron]; }

- (void)updateChevron {
    NSString *name = self.expanded ? @"chevron.up.circle.fill" : @"chevron.down.circle.fill";
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightRegular];
    UIImage *img = [[UIImage systemImageNamed:name withConfiguration:cfg]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _chevron.image = img;
}

- (CGFloat)heightForCurrentState {
    if (!self.expanded || self.items.count == 0) return kScaleH(57);
    return kScaleH(48) + kScaleH(131) * self.items.count;
}

- (void)reload {
    // 清除旧 cards
    for (MKOrderSubCard *c in _cards) [c removeFromSuperview];
    [_cards removeAllObjects];

    if (!self.expanded) return;

    for (NSInteger i = 0; i < self.items.count; i++) {
        MKOrderSubCard *c = [[MKOrderSubCard alloc] initWithFrame:CGRectMake(kScaleW(13),
                                                                              kScaleH(48 + 131 * i),
                                                                              kScaleW(319),
                                                                              kScaleH(117))];
        NSDictionary *m = self.items[i];
        [c configureAmount:m[@"amount"]
                  chipTitle:m[@"chipTitle"]
                  chipColor:m[@"chipColor"]
                    product:m[@"product"]
                  dateLabel:m[@"dateLabel"]
                  dateValue:m[@"dateValue"]];
        c.tag = i;
        [c addTarget:self action:@selector(cardTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:c];
        [_cards addObject:c];
    }
}

- (void)cardTapped:(MKOrderSubCard *)c {
    if (self.onItemTap) self.onItemTap(c.tag);
}

- (void)toggle { if (self.onToggle) self.onToggle(); }

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    _titleRow.frame = CGRectMake(0, 0, w, kScaleH(57));
    _titleLabel.frame = CGRectMake(kScaleW(14), 0, w - kScaleW(60), kScaleH(57));
    _chevron.frame = CGRectMake(w - kScaleW(15) - kScaleW(20),
                                 (kScaleH(57) - kScaleW(20)) * 0.5,
                                 kScaleW(20), kScaleW(20));
}
@end

#pragma mark - VC

@interface MKOrderListViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) NSMutableArray<MKOrderAccordionSection *> *sections;
/// 4 桶, 每桶是 {amount, chipTitle, chipColor, product, dateLabel, dateValue, _model} 的字典数组
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSDictionary *> *> *bucketedData;
@property (nonatomic, assign) MKOrderSectionKind currentExpanded;
@end

@implementation MKOrderListViewController

- (instancetype)init { return [self initWithExpandedSection:MKOrderSectionSubmitApplication]; }
- (instancetype)initWithTab:(MKOrderListTab)tab { return [self initWithExpandedSection:(MKOrderSectionKind)tab]; }

- (instancetype)initWithExpandedSection:(MKOrderSectionKind)kind {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
        _currentExpanded = kind;
        // 初始 4 个空桶, 接口回来后 reload
        _bucketedData = [NSMutableArray arrayWithObjects:
                         [NSMutableArray new], [NSMutableArray new],
                         [NSMutableArray new], [NSMutableArray new], nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;
    [self setupGradient];
    [self setupHeader];
    [self setupScrollView];
    [self setupSections];
    [self relayoutSections];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [self loadOrderList];
}

- (void)setupGradient {
    // 顶部 Rectangle 4232: 0,0,375,484 linear 180° #385330 27% → #F8F8F7 53%
    self.gradient = [CAGradientLayer layer];
    self.gradient.frame = CGRectMake(0, 0, kScreenWidth, kScaleH(484));
    self.gradient.colors = @[ (id)kColorPrimary.CGColor, (id)kColorBackground.CGColor ];
    self.gradient.locations = @[ @(0.27), @(0.53) ];
    self.gradient.startPoint = CGPointMake(0.5, 0);
    self.gradient.endPoint = CGPointMake(0.5, 1);
    [self.view.layer addSublayer:self.gradient];
}

- (void)setupHeader {
    // 标题 "Order" 白色 居中, y=statusBar+10
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, kStatusBarHeight, kScreenWidth, 44)];
    title.text = @"Order";
    title.textAlignment = NSTextAlignmentCenter;
    title.font = kFontSemibold(18);
    title.textColor = kColorWhite;
    [self.view addSubview:title];

    // 返回箭头
    if (self.navigationController.viewControllers.count > 1) {
        UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
        back.frame = CGRectMake(kScaleW(20), kStatusBarHeight, 44, 44);
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
        UIImage *img = [[UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [back setImage:img forState:UIControlStateNormal];
        back.tintColor = kColorWhite;
        back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        back.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        [back addTarget:self action:@selector(onBackTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:back];
    }
}

- (void)setupScrollView {
    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kNavBarHeight);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)setupSections {
    NSArray<NSString *> *titles = @[ @"Submit Application", @"Pending Repayment", @"Processing", @"Completed" ];
    self.sections = [NSMutableArray array];
    for (NSInteger i = 0; i < titles.count; i++) {
        MKOrderAccordionSection *sec = [[MKOrderAccordionSection alloc] init];
        sec.title = titles[i];
        sec.items = self.bucketedData[i];
        sec.expanded = YES;  // 默认 4 段全展开
        __weak typeof(self) wself = self;
        sec.onToggle = ^{ [wself toggleSection:i]; };
        sec.onItemTap = ^(NSInteger idx) { [wself didTapItemInSection:i idx:idx]; };
        [sec reload];
        [self.scrollView addSubview:sec];
        [self.sections addObject:sec];
    }
}

- (void)relayoutSections {
    // Card 顶部 y 起始 = 108 - kNavBarHeight (scrollView 已位移 kNavBarHeight)
    CGFloat y = kScaleH(108) - kNavBarHeight;
    if (y < 0) y = 0;
    for (MKOrderAccordionSection *sec in self.sections) {
        CGFloat h = [sec heightForCurrentState];
        sec.frame = CGRectMake(kScaleW(15), y, kScaleW(345), h);
        y += h + kScaleH(14);
    }
    self.scrollView.contentSize = CGSizeMake(kScreenWidth, y + kBottomSafeHeight + kScaleH(20));
}

- (void)toggleSection:(NSInteger)idx {
    // 每段独立切换 (默认 4 段全展开, 用户可点 chevron 单独折叠/恢复)
    MKOrderAccordionSection *sec = self.sections[idx];
    sec.expanded = !sec.expanded;
    [sec reload];
    [UIView animateWithDuration:0.25 animations:^{
        [self relayoutSections];
    }];
}

- (void)didTapItemInSection:(NSInteger)section idx:(NSInteger)idx {
    if (section >= (NSInteger)self.bucketedData.count) return;
    NSArray<NSDictionary *> *bucket = self.bucketedData[section];
    if (idx >= (NSInteger)bucket.count) return;
    MKOrderListModel *m = bucket[idx][@"_model"];
    if (!m) return;

    // 拒绝订单 + rejectH5 已配置 → 跳拒量 H5
    if (m.orderStatus == 31 && [MKRejectFlowCoordinator presentRejectH5FromVC:self]) return;

    // 否则统一走 MKOrderDetailViewController, 由它按 orderStatus 自适应渲染
    MKOrderDetailViewController *detail = [[MKOrderDetailViewController alloc] initWithOrderId:m.orderId];
    detail.productId = m.productId;
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark - API

- (void)loadOrderList {
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSMutableDictionary *dataForRequest = [NSMutableDictionary dictionary];
    dataForRequest[@"orderStatus"] = @(66);  // 66 = 全部
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:@{}
                                                                              requestData:dataForRequest];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/order/list"
                                     params:body
                                    success:^(id resp) {
        [SVProgressHUD dismiss];
        if (![resp isKindOfClass:[NSDictionary class]]) return;
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code != 200) {
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Failed to load orders"];
            return;
        }
        NSDictionary *data = resp[@"data"];
        NSArray *list = [data isKindOfClass:[NSDictionary class]] ? data[@"orderList"] : nil;
        [wself rebuildBucketsFromOrderList:list];
    } failure:^(NSError *e) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:e.localizedDescription ?: @"Network error"];
    }];
}

- (void)rebuildBucketsFromOrderList:(NSArray *)list {
    for (NSMutableArray *bucket in self.bucketedData) [bucket removeAllObjects];

    if ([list isKindOfClass:[NSArray class]]) {
        for (id dict in list) {
            if (![dict isKindOfClass:[NSDictionary class]]) continue;
            MKOrderListModel *m = [[MKOrderListModel alloc] initWithDictionary:dict];
            NSInteger bucket = [MKOrderStatusMapper sectionForStatus:m.orderStatus];
            if (bucket < 0 || bucket >= (NSInteger)self.bucketedData.count) continue;

            NSDictionary *item = @{
                @"amount":    MKFormatOrderAmount(m.loanAmount),
                @"chipTitle": [MKOrderStatusMapper chipTextForStatus:m.orderStatus],
                @"chipColor": [MKOrderStatusMapper chipColorForStatus:m.orderStatus],
                @"product":   m.productName ?: @"",
                @"dateLabel": [MKOrderStatusMapper dateLabelForStatus:m.orderStatus],
                @"dateValue": MKFormatOrderDate([MKOrderStatusMapper dateValueForStatus:m.orderStatus fromModel:m]),
                @"_model":    m,
            };
            [self.bucketedData[bucket] addObject:item];
        }
    }

    // 同步到 section + 重新布局
    for (NSInteger i = 0; i < self.sections.count && i < (NSInteger)self.bucketedData.count; i++) {
        self.sections[i].items = self.bucketedData[i];
        [self.sections[i] reload];
    }
    [self relayoutSections];
}

@end
