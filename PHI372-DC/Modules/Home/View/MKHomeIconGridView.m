//
//  MKHomeIconGridView.m
//
//  Figma 4 圆形 icon: Contact(38) Bank(120) Order(202) Me(284), 每个 53x53 圆,
//  内部图标 41x41(深色背景上).
//

#import "MKHomeIconGridView.h"
#import "MKConstants.h"

#define S(v) ((v) * kScale)

@implementation MKHomeIconGridView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupIcons];
    }
    return self;
}

- (void)setupIcons {
    // Pencil n6Aqn (frame 375): 圆 x=38/120/202/284, label x/y/width:
    //   H3wA1C "Contact Us"  x=37  y=315 w=54  fixed-width (2 行)
    //   ICTV6  "Bank Account" x=119 y=315 w=55  fixed-width (2 行)
    //   iF1Xm  "Order"       x=210 y=320 auto    (1 行)
    //   e2145O "me"          x=300 y=320 auto    (1 行, 小写)
    // 本 View 内坐标 = Pencil 坐标 - 38 (grid 起点)
    NSArray *kinds  = @[@(MKHomeIconKindContact), @(MKHomeIconKindBank), @(MKHomeIconKindOrder), @(MKHomeIconKindMe)];
    NSArray *iconXs = @[@0, @82, @164, @246];
    NSArray *names  = @[@"mk_icon_contact", @"mk_icon_bank", @"mk_icon_order", @"mk_icon_me"];
    NSArray *titles = @[@"Contact Us", @"Bank Account", @"Order", @"me"];
    // label x 相对本 View (=Pencil x - 38); label y 相对本 View (=Pencil y - 255 即 grid 内偏移)
    NSArray *labelXs     = @[@(37 - 38), @(119 - 38), @(210 - 38), @(300 - 38)];  // -1/81/172/262
    NSArray *labelYs     = @[@(315 - 255), @(315 - 255), @(320 - 255), @(320 - 255)]; // 60/60/65/65
    NSArray *labelWs     = @[@54, @55, @0, @0]; // 0 表示 auto
    NSArray *labelLines  = @[@2, @2, @1, @1];

    for (NSInteger i = 0; i < 4; i++) {
        CGFloat x = S([iconXs[i] floatValue]);

        UIButton *icon = [UIButton buttonWithType:UIButtonTypeCustom];
        icon.frame = CGRectMake(x, 0, S(53), S(53));
        icon.backgroundColor = kColorPrimaryDark;
        icon.layer.cornerRadius = S(26.5);
        icon.tag = [kinds[i] integerValue];
        [icon addTarget:self action:@selector(iconTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:icon];

        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(S(6), S(6), S(41), S(41))];
        iv.image = [UIImage imageNamed:names[i]];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.userInteractionEnabled = NO;
        [icon addSubview:iv];

        UILabel *lbl = [UILabel new];
        lbl.text = titles[i];
        lbl.font = kFontPingFang14;
        lbl.textColor = MKHexColor(0x000000);
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.numberOfLines = [labelLines[i] integerValue];
        lbl.lineBreakMode = NSLineBreakByWordWrapping;
        CGFloat lx = S([labelXs[i] floatValue]);
        CGFloat ly = S([labelYs[i] floatValue]);
        CGFloat lw = [labelWs[i] floatValue];
        if (lw > 0) {
            // fixed-width: Contact Us / Bank Account 用 Pencil 指定宽度强制换行
            lbl.frame = CGRectMake(lx, ly, S(lw), S(34));
        } else {
            // auto: Order / me 单行, 以圆心居中
            CGSize size = [lbl sizeThatFits:CGSizeMake(CGFLOAT_MAX, S(20))];
            CGFloat circleCenterX = x + S(53 * 0.5);
            lbl.frame = CGRectMake(circleCenterX - size.width * 0.5, ly, size.width, S(20));
        }
        [self addSubview:lbl];
    }
}

- (void)iconTapped:(UIButton *)b {
    if (self.onIconTapped) self.onIconTapped((MKHomeIconKind)b.tag);
}

@end
