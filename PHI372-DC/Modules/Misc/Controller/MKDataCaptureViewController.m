#import "MKDataCaptureViewController.h"
#import "MKConstants.h"

@interface MKDataCaptureViewController ()
@property (nonatomic, strong) UIView *trackBar;
@property (nonatomic, strong) UIView *fillBar;
@property (nonatomic, strong) UILabel *percentageLabel;
@end

@implementation MKDataCaptureViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _progress = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Pencil 数据抓取: 全屏遮罩 #00000099
    self.view.backgroundColor = MKColorAlpha(0, 0, 0, 0.6);

    // 居中卡片, Pencil: #f8f8f7, cornerRadius=28
    CGFloat cardW = kScreenWidth - kScaleW(44);
    CGFloat cardH = kScaleH(315);
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(22), (kScreenHeight - cardH) * 0.5, cardW, cardH)];
    card.backgroundColor = MKHexColor(0xF8F8F7);
    card.layer.cornerRadius = kScaleW(28);
    [self.view addSubview:card];

    // Title "Under review"
    CGFloat titleY = kScaleH(20);
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, titleY, cardW, kScaleH(28))];
    title.text = @"Under review";
    title.font = kFontRegular(20);
    title.textColor = MKHexColor(0x000000);
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];

    // Body
    UILabel *body = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(22), kScaleH(58), cardW - kScaleW(44), kScaleH(56))];
    body.text = @"Your credit score is being updated, please don't exit. It'll only take a few seconds.";
    body.font = kFontRegular(14);
    body.textColor = MKHexColor(0x666666);
    body.textAlignment = NSTextAlignmentCenter;
    body.numberOfLines = 0;
    [card addSubview:body];

    // Progress container
    CGFloat progressContainerY = kScaleH(128);
    UIView *progContainer = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(20), progressContainerY, cardW - kScaleW(40), kScaleH(90))];
    progContainer.backgroundColor = MKHexColor(0xE9E9E4);
    progContainer.layer.cornerRadius = kScaleW(14);
    [card addSubview:progContainer];

    // 进度百分比 label (右上角)
    self.percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(progContainer.bounds.size.width - kScaleW(60) - kScaleW(12),
                                                                       kScaleH(10),
                                                                       kScaleW(60), kScaleH(16))];
    self.percentageLabel.font = [UIFont systemFontOfSize:kScaleW(12) weight:UIFontWeightSemibold];
    self.percentageLabel.textColor = kColorPrimary;
    self.percentageLabel.textAlignment = NSTextAlignmentRight;
    self.percentageLabel.text = @"0%";
    [progContainer addSubview:self.percentageLabel];

    // 步骤标签
    NSArray *steps = @[ @"Apply", @"Reviewed", @"Received" ];
    NSArray *stepXs = @[ @(kScaleW(53)), @(kScaleW(141)), @(kScaleW(256)) ];
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *stepLbl = [[UILabel alloc] initWithFrame:CGRectMake([stepXs[i] floatValue] - kScaleW(22),
                                                                      kScaleH(48),
                                                                      kScaleW(60), kScaleH(24))];
        stepLbl.text = steps[i];
        stepLbl.font = kFontRegular(12);
        stepLbl.textColor = MKHexColor(0x565656);
        stepLbl.textAlignment = NSTextAlignmentCenter;
        [progContainer addSubview:stepLbl];
    }

    // 进度条
    self.trackBar = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(16), kScaleH(32), progContainer.bounds.size.width - kScaleW(32), kScaleH(7))];
    self.trackBar.backgroundColor = MKHexColor(0xC8C8BE);
    self.trackBar.layer.cornerRadius = kScaleH(3.5);
    [progContainer addSubview:self.trackBar];

    self.fillBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, kScaleH(7))];
    self.fillBar.backgroundColor = kColorPrimary;
    self.fillBar.layer.cornerRadius = kScaleH(3.5);
    [self.trackBar addSubview:self.fillBar];

    // 底部说明文字
    UILabel *progressNote = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(22), progressContainerY + kScaleH(98), cardW - kScaleW(44), kScaleH(52))];
    progressNote.text = @"You're only one step away from receiving your funds, please keep this page open.";
    progressNote.font = kFontRegular(13);
    progressNote.textColor = MKHexColor(0x666666);
    progressNote.textAlignment = NSTextAlignmentCenter;
    progressNote.numberOfLines = 0;
    [card addSubview:progressNote];

    // 应用初始 progress (init 时设置过的值)
    [self applyProgress:_progress animated:NO];
}

- (void)setProgress:(NSInteger)progress {
    [self setProgress:progress animated:YES];
}

- (void)setProgress:(NSInteger)progress animated:(BOOL)animated {
    _progress = MAX(0, MIN(100, progress));
    if (!self.isViewLoaded) return;
    [self applyProgress:_progress animated:animated];
}

- (void)applyProgress:(NSInteger)progress animated:(BOOL)animated {
    CGFloat trackW = self.trackBar.bounds.size.width;
    CGFloat fillW = trackW * (progress / 100.0);
    self.percentageLabel.text = [NSString stringWithFormat:@"%ld%%", (long)progress];
    void (^block)(void) = ^{
        CGRect f = self.fillBar.frame;
        f.size.width = fillW;
        self.fillBar.frame = f;
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:block];
    } else {
        block();
    }
}

@end
