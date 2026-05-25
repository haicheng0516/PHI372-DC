//
//  MKOrderListViewController.m
//  PHI372-DC — Figma 3:599 历史订单 (accordion)
//
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
//

#import "MKOrderListViewController.h"
#import "MKConstants.h"
#import "MKOrderDetailWaitRepayViewController.h"
#import "MKOrderDetailReviewingViewController.h"
#import "MKOrderDetailPendingWithdrawViewController.h"
#import <Masonry/Masonry.h>

#pragma mark - Status chip colors (Figma)

static UIColor *MKChipColorChangeBank(void)   { return MKHexColor(0x6E1758); }
static UIColor *MKChipColorUnfinished(void)   { return MKHexColor(0x532C6E); }
static UIColor *MKChipColorWithdraw(void)     { return MKHexColor(0x0A7F93); }
static UIColor *MKChipColorPendingRepay(void) { return MKHexColor(0xAF5D00); }  // Pencil #af5d00
static UIColor *MKChipColorOverdue(void)      { return MKHexColor(0xA0721B); }  // Pencil #a0721b
static UIColor *MKChipColorProcessing(void)   { return MKHexColor(0x385330); }
static UIColor *MKChipColorCompleted(void)    { return MKHexColor(0x999999); }

#pragma mark - Order Sub-Card View (319×117)

@interface MKOrderSubCard : UIControl
- (void)configureAmount:(NSString *)amt
              chipTitle:(NSString *)chipTitle
              chipColor:(UIColor *)chipColor
                product:(NSString *)product
                   date:(NSString *)date;
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
        _dateLabel.text = @"Payment date:";
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
                   date:(NSString *)date {
    _amount.text = amt;
    _chipLabel.text = chipTitle;
    _chipBg.backgroundColor = chipColor;
    _product.text = product;
    _dateValue.text = date;
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
                       date:m[@"date"]];
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
@property (nonatomic, strong) NSArray<NSArray<NSDictionary *> *> *mockData;
@property (nonatomic, assign) MKOrderSectionKind currentExpanded;
@end

@implementation MKOrderListViewController

- (instancetype)init { return [self initWithExpandedSection:MKOrderSectionSubmitApplication]; }
- (instancetype)initWithTab:(MKOrderListTab)tab { return [self initWithExpandedSection:(MKOrderSectionKind)tab]; }

- (instancetype)initWithExpandedSection:(MKOrderSectionKind)kind {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
        _currentExpanded = kind;
        [self buildMockData];
    }
    return self;
}

- (void)buildMockData {
    self.mockData = @[
        @[ // SubmitApplication
            @{ @"amount": @"₱ 50,000", @"chipTitle": @"Change bank account", @"chipColor": MKChipColorChangeBank(),
               @"product": @"chanpinmingcheng", @"date": @"Mar 18, 2025" },
            @{ @"amount": @"₱ 50,000", @"chipTitle": @"Unfinished Application", @"chipColor": MKChipColorUnfinished(),
               @"product": @"chanpinmingcheng", @"date": @"Mar 18, 2025" },
            @{ @"amount": @"₱ 50,000", @"chipTitle": @"To be withdrawn", @"chipColor": MKChipColorWithdraw(),
               @"product": @"chanpinmingcheng", @"date": @"Mar 18, 2025" },
        ],
        @[ // PendingRepayment — Pencil shows two cards: Overdue + Pending Repayment
            @{ @"amount": @"₱ 50,000", @"chipTitle": @"Overdue", @"chipColor": MKChipColorOverdue(),
               @"product": @"chanpinmingcheng", @"date": @"Mar 18, 2025" },
            @{ @"amount": @"₱ 50,000", @"chipTitle": @"Pending Repayment", @"chipColor": MKChipColorPendingRepay(),
               @"product": @"chanpinmingcheng", @"date": @"Mar 18, 2025" },
        ],
        @[ // Processing
            @{ @"amount": @"₱ 30,000", @"chipTitle": @"Processing", @"chipColor": MKChipColorProcessing(),
               @"product": @"chanpinmingcheng", @"date": @"Mar 15, 2026" },
        ],
        @[ // Completed
            @{ @"amount": @"₱ 10,000", @"chipTitle": @"Completed", @"chipColor": MKChipColorCompleted(),
               @"product": @"chanpinmingcheng", @"date": @"Feb 10, 2026" },
        ],
    ];
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
        sec.items = self.mockData[i];
        sec.expanded = (i == self.currentExpanded);
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
    // 只允许 1 个 section 展开 (与 Figma 设计一致)
    BOOL willExpand = !self.sections[idx].expanded;
    for (NSInteger i = 0; i < self.sections.count; i++) {
        self.sections[i].expanded = (i == idx && willExpand);
        [self.sections[i] reload];
    }
    self.currentExpanded = willExpand ? (MKOrderSectionKind)idx : -1;
    [UIView animateWithDuration:0.25 animations:^{
        [self relayoutSections];
    }];
}

- (void)didTapItemInSection:(NSInteger)section idx:(NSInteger)idx {
    UIViewController *detail = nil;
    switch ((MKOrderSectionKind)section) {
        case MKOrderSectionSubmitApplication: {
            // 按状态类型路由 (Mock: 三个分别 → Pending Withdraw / Reviewing / Pending Withdraw)
            NSString *chip = self.mockData[section][idx][@"chipTitle"];
            if ([chip isEqualToString:@"To be withdrawn"])      detail = [MKOrderDetailPendingWithdrawViewController new];
            else if ([chip isEqualToString:@"Unfinished Application"]) detail = [MKOrderDetailReviewingViewController new];
            else                                                detail = [MKOrderDetailReviewingViewController new];
            break;
        }
        case MKOrderSectionPendingRepayment: detail = [MKOrderDetailWaitRepayViewController new]; break;
        case MKOrderSectionProcessing:       detail = [MKOrderDetailReviewingViewController new]; break;
        case MKOrderSectionCompleted:        detail = [MKOrderDetailPendingWithdrawViewController new]; break;
    }
    if (detail) [self.navigationController pushViewController:detail animated:YES];
}

@end
