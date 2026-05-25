#import "MKDataCaptureViewController.h"
#import "MKConstants.h"

@implementation MKDataCaptureViewController
- (instancetype)init { if (self = [super init]) { self.navBarStyle = MKNavBarStyleNone; } return self; }
- (void)viewDidLoad {
    [super viewDidLoad];
    // Pencil 数据抓取: 全屏遮罩 #00000099
    self.view.backgroundColor = MKColorAlpha(0, 0, 0, 0.6);

    // 居中卡片, Pencil: #f8f8f7, cornerRadius=28, 内有 title/body/progress bar
    CGFloat cardW = kScreenWidth - kScaleW(44);
    CGFloat cardH = kScaleH(315);
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(22), (kScreenHeight - cardH) * 0.5, cardW, cardH)];
    card.backgroundColor = MKHexColor(0xF8F8F7);
    card.layer.cornerRadius = kScaleW(28);
    [self.view addSubview:card];

    // Pencil: title "Under review" PingFang SC/20 #000000, textAlign center
    CGFloat titleY = kScaleH(20);
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, titleY, cardW, kScaleH(28))];
    title.text = @"Under review";
    title.font = kFontRegular(20);
    title.textColor = MKHexColor(0x000000);
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title];

    // Pencil: body "Your credit score is being updated..." PingFang SC/14 #666666
    UILabel *body = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(22), kScaleH(58), cardW - kScaleW(44), kScaleH(56))];
    body.text = @"Your credit score is being updated, please don't exit. It'll only take a few seconds.";
    body.font = kFontRegular(14);
    body.textColor = MKHexColor(0x666666);
    body.textAlignment = NSTextAlignmentCenter;
    body.numberOfLines = 0;
    [card addSubview:body];

    // Pencil: progress container #e9e9e4, cornerRadius=14, 291x90, y=569 (相对卡片内)
    CGFloat progressContainerY = kScaleH(128);
    UIView *progContainer = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(20), progressContainerY, cardW - kScaleW(40), kScaleH(90))];
    progContainer.backgroundColor = MKHexColor(0xE9E9E4);
    progContainer.layer.cornerRadius = kScaleW(14);
    [card addSubview:progContainer];

    // Pencil: 进度步骤标签: Apply / Reviewed / Received (Poppins/14 #565656)
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

    // Pencil: progress bar #c8c8be bg, #385330 fill 80%, cornerRadius=20, h=7, y=601-569=32
    UIView *trackBar = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(16), kScaleH(32), progContainer.bounds.size.width - kScaleW(32), kScaleH(7))];
    trackBar.backgroundColor = MKHexColor(0xC8C8BE);
    trackBar.layer.cornerRadius = kScaleH(3.5);
    [progContainer addSubview:trackBar];

    UIView *fillBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, trackBar.bounds.size.width * 0.8, kScaleH(7))];
    fillBar.backgroundColor = kColorPrimary;
    fillBar.layer.cornerRadius = kScaleH(3.5);
    [trackBar addSubview:fillBar];

    // Pencil: 底部进度说明文字
    UILabel *progressNote = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(22), progressContainerY + kScaleH(98), cardW - kScaleW(44), kScaleH(52))];
    progressNote.text = @"You're only one step away from receiving your funds, please keep this page open.";
    progressNote.font = kFontRegular(13);
    progressNote.textColor = MKHexColor(0x666666);
    progressNote.textAlignment = NSTextAlignmentCenter;
    progressNote.numberOfLines = 0;
    [card addSubview:progressNote];
}
@end
