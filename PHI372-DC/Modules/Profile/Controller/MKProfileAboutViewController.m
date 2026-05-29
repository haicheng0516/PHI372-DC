//
//  MKProfileAboutViewController.m
//  个人中心-关于我们
//
//  设计稿 (375×812):
//    顶部绿色 nav bg (#385330 h=98 r=0,0,14,14) 标题 "About" PingFang SC 20pt white 居中
//    Logo 圆形 50×50 r=20 白底 居中 x=163 y=111
//    APP name 全宽居中 Poppins 600 16 white y=163
//    灰底文档卡 (18,255) 339×208 r=14 产品介绍 #666d80 16pt
//

#import "MKProfileAboutViewController.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

@implementation MKProfileAboutViewController

- (instancetype)init {
    // 父类 init 仅传入空 items, 我们完全重写 viewDidLoad
    if (self = [super initWithTitle:@"" items:@[]]) {
        self.navBarStyle = MKNavBarStyleNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    // ── 顶部绿色 nav (h=98, r=0,0,14,14) ──
    UIView *navBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScaleH(98))];
    navBg.backgroundColor = kColorPrimary;
    navBg.clipsToBounds = YES;
    navBg.layer.cornerRadius = kScaleH(14);
    navBg.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.view addSubview:navBg];

    UIImageView *bgImg = [[UIImageView alloc] initWithFrame:navBg.bounds];
    bgImg.image = [UIImage imageNamed:@"mk_me_header_bg"];
    bgImg.contentMode = UIViewContentModeScaleAspectFill;
    bgImg.clipsToBounds = YES;
    [navBg addSubview:bgImg];

    UIView *maskView = [[UIView alloc] initWithFrame:navBg.bounds];
    maskView.backgroundColor = MKColorAlpha(56, 83, 48, 0.94);
    [navBg addSubview:maskView];

    // "About" 标题 (设计稿 y=64, PingFang SC 20pt normal, white)
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(56), kScreenWidth, kScaleH(32))];
    titleLabel.text = @"About";
    titleLabel.textColor = kColorWhite;
    titleLabel.font = [UIFont systemFontOfSize:kScaleW(20) weight:UIFontWeightRegular];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [navBg addSubview:titleLabel];

    // 返回箭头 (30,64) 黄绿色
    if (self.navigationController.viewControllers.count > 1) {
        UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
        back.frame = CGRectMake(kScaleW(20), kScaleH(52), 44, 44);
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
        UIImage *img = [[UIImage systemImageNamed:@"chevron.left" withConfiguration:cfg]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [back setImage:img forState:UIControlStateNormal];
        back.tintColor = MKHexColor(0xBBCB2F);
        back.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        back.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        [back addTarget:self action:@selector(onBackTapped) forControlEvents:UIControlEventTouchUpInside];
        [navBg addSubview:back];
    }

    // ── Logo 圆形 50×50 r=20 白底, 居中 x=163 y=111 ──
    UIView *logo = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(163), kScaleH(111), kScaleW(50), kScaleW(50))];
    logo.backgroundColor = kColorWhite;
    logo.layer.cornerRadius = kScaleW(20);
    [self.view addSubview:logo];

    // ── APP name: 600 16, white, 全宽居中 y=163 ── 走 Info.plist 显示名
    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(163), kScreenWidth, kScaleH(24))];
    name.text = MKAppDisplayName();
    name.textColor = kColorWhite;
    name.font = kFontSemibold(16);
    name.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:name];

    // ── 产品介绍卡 (18, 255) 339×auto r=14 ──
    UIScrollView *scroll = [UIScrollView new];
    scroll.backgroundColor = kColorBackground;
    scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scroll];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kScaleH(187));
        make.left.right.bottom.equalTo(self.view);
    }];

    // 产品介绍灰底卡 (设计稿 y=255, 设计 body: Poppins regular 16 #666d80)
    // 用 MKDocCardView 基础样式, body 在 Common 中固定为 14pt; 差异可接受
    NSString *body = @"Swift and reliable financial support. We are committed to providing safe, easy and fast loan services to all Filipinos. We adhere to all Philippine financial regulations.";
    CGFloat cardY = kScaleH(255 - 187);  // 相对 scroll 内容顶部
    CGFloat cardW = kScaleW(339);
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = MKHexColor(0xE9E9E4);
    card.layer.cornerRadius = kScaleH(14);

    UILabel *bodyLabel = [UILabel new];
    bodyLabel.numberOfLines = 0;
    bodyLabel.font = kFontRegular(16);
    bodyLabel.textColor = MKHexColor(0x666D80);
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.lineSpacing = kScaleH(6);
    bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:body
        attributes:@{ NSFontAttributeName: bodyLabel.font,
                      NSForegroundColorAttributeName: bodyLabel.textColor,
                      NSParagraphStyleAttributeName: ps }];
    CGFloat textW = cardW - kScaleW(32);
    CGFloat textH = ceilf([bodyLabel sizeThatFits:CGSizeMake(textW, CGFLOAT_MAX)].height);
    CGFloat cardH = kScaleH(14) + textH + kScaleH(14);
    card.frame = CGRectMake(kScaleW(18), cardY, cardW, cardH);
    bodyLabel.frame = CGRectMake(kScaleW(16), kScaleH(14), textW, textH);
    [card addSubview:bodyLabel];
    [scroll addSubview:card];
    scroll.contentSize = CGSizeMake(kScreenWidth, cardY + cardH + kBottomSafeHeight + kScaleH(20));
}

@end
