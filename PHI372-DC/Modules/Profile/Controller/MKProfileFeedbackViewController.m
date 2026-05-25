//
//  MKProfileFeedbackViewController.m
//  PHI372-DC — Figma 3:1220 个人中心-问题反馈
//
//  布局精确还原 (375×812):
//    顶部品牌绿 nav (#385330 r=0,0,14,14) 标题 "Feedback"
//    Hint banner (18,110) 339×91 灰底 + 4 行文案
//    "Your question" (36,228) 14pt 600 #171718
//    多行输入 (36,260) 303×185 白底 r=14 占位 "Please enter" 字数 1/1000
//    "Upload pictures" (36,465) 14pt 600
//    3 格上传位 (横向, 94×93, gap ~10, r=14, 描边)
//    底部 Submit 按钮 (36, bottom) 303×56 r=28 #385330
//

#import "MKProfileFeedbackViewController.h"
#import "MKConstants.h"
#import "MKHintBannerView.h"
#import <Masonry/Masonry.h>

@interface MKProfileFeedbackViewController () <UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *counterLabel;
@end

@implementation MKProfileFeedbackViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Feedback";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    CGFloat y = kNavBarHeight + kScaleH(12);

    // Hint banner
    NSString *hintText = @"You can describe the problem you encounter in detail on this page, or send your problem to our email, leave your contact information, and we will contact you as soon as possible!";
    CGFloat hintH = [MKHintBannerView heightForText:hintText];
    MKHintBannerView *hint = [[MKHintBannerView alloc] initWithText:hintText];
    hint.frame = CGRectMake(kScaleW(18), y, kScaleW(339), hintH);
    [self.view addSubview:hint];
    y += hintH + kScaleH(20);

    // "Your question" 小标题
    UILabel *qlabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(36), y, kScaleW(303), kScaleH(20))];
    qlabel.text = @"Your question";
    qlabel.font = kFontRegular(14);
    qlabel.textColor = MKHexColor(0x171718);
    [self.view addSubview:qlabel];
    y += kScaleH(28);

    // 多行输入
    self.textView = [UITextView new];
    self.textView.frame = CGRectMake(kScaleW(36), y, kScaleW(303), kScaleH(185));
    self.textView.backgroundColor = MKHexColor(0xE9E9E4);
    self.textView.layer.cornerRadius = kScaleH(14);
    self.textView.font = kFontRegular(14);
    self.textView.textColor = kColorTextPrimary;
    self.textView.textContainerInset = UIEdgeInsetsMake(kScaleH(14), kScaleW(14), kScaleH(28), kScaleW(14));
    self.textView.delegate = self;
    [self.view addSubview:self.textView];

    // Placeholder label (since UITextView doesn't have native placeholder)
    UILabel *placeholder = [UILabel new];
    placeholder.text = @"Please enter";
    placeholder.textColor = MKHexColor(0x666D80);
    placeholder.font = kFontRegular(14);
    placeholder.tag = 9100;
    placeholder.frame = CGRectMake(kScaleW(50), y + kScaleH(20), kScaleW(280), kScaleH(20));
    [self.view addSubview:placeholder];

    // 字数计数器
    self.counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(36) + kScaleW(303) - kScaleW(80) - kScaleW(14),
                                                                    y + kScaleH(185) - kScaleH(30),
                                                                    kScaleW(80), kScaleH(20))];
    self.counterLabel.text = @"0/1000";
    self.counterLabel.font = kFontRegular(12);
    self.counterLabel.textColor = MKHexColor(0x666D80);
    self.counterLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.counterLabel];
    y += kScaleH(185 + 20);

    // "Upload pictures" 小标题
    UILabel *uplabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(36), y, kScaleW(303), kScaleH(20))];
    uplabel.text = @"Upload pictures";
    uplabel.font = kFontRegular(14);
    uplabel.textColor = MKHexColor(0x171718);
    [self.view addSubview:uplabel];
    y += kScaleH(28);

    // 3 上传格 (94×93 横向 gap 10)
    CGFloat slotW = kScaleW(94);
    CGFloat slotH = kScaleH(93);
    CGFloat gap = kScaleW(10);
    for (NSInteger i = 0; i < 3; i++) {
        UIView *slot = [UIView new];
        slot.frame = CGRectMake(kScaleW(36) + i * (slotW + gap), y, slotW, slotH);
        slot.backgroundColor = MKHexColor(0xE9E9E4);
        slot.layer.cornerRadius = kScaleH(14);
        [self.view addSubview:slot];

        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightLight];
        UIImageView *plus = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"plus" withConfiguration:cfg]
                                                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        plus.tintColor = MKHexColor(0x999999);
        plus.contentMode = UIViewContentModeScaleAspectFit;
        plus.frame = CGRectMake((slotW - kScaleW(24)) * 0.5, kScaleH(20), kScaleW(24), kScaleW(24));
        [slot addSubview:plus];

        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(55), slotW, kScaleH(20))];
        t.text = @"Upload pictures";
        t.textAlignment = NSTextAlignmentCenter;
        t.font = kFontRegular(11);
        t.textColor = MKHexColor(0x999999);
        [slot addSubview:t];
    }

    // Submit
    UIButton *submit = [UIButton buttonWithType:UIButtonTypeCustom];
    submit.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(76), kScaleW(303), kScaleH(56));
    submit.backgroundColor = kColorPrimary;
    submit.layer.cornerRadius = kScaleH(28);
    [submit setTitle:@"Submit" forState:UIControlStateNormal];
    [submit setTitleColor:kColorWhite forState:UIControlStateNormal];
    submit.titleLabel.font = kFontSemibold(16);
    [self.view addSubview:submit];
}

- (void)textViewDidChange:(UITextView *)textView {
    UILabel *placeholder = (UILabel *)[self.view viewWithTag:9100];
    placeholder.hidden = textView.text.length > 0;
    if (textView.text.length > 1000) {
        textView.text = [textView.text substringToIndex:1000];
    }
    self.counterLabel.text = [NSString stringWithFormat:@"%lu/1000", (unsigned long)textView.text.length];
}

@end
