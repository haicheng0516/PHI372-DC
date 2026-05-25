//
//  MKHomeFooterView.m
//

#import "MKHomeFooterView.h"
#import "MKConstants.h"

// Figma 数据: regulatorRow (30, 734, 297×36); footnote (30, 787)
// 相对 footer 内坐标: card2 在 Figma 588+126=714 结束 → regulator 离上方 20pt, footnote 离 regulator 17pt, 底 25pt 留白
static const CGFloat kFooterPadTop      = 20;
static const CGFloat kRegulatorHeight   = 36;
static const CGFloat kRegulatorFootnote = 17;
static const CGFloat kFootnoteHeight    = 24;
static const CGFloat kFooterPadBottom   = 25;

@implementation MKHomeFooterView

+ (CGFloat)height {
    return kScaleH(kFooterPadTop + kRegulatorHeight + kRegulatorFootnote + kFootnoteHeight + kFooterPadBottom);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.height == 0) frame.size.height = [MKHomeFooterView height];
    if (frame.size.width  == 0) frame.size.width  = kScreenWidth;
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kColorBackground;

        // 4 logo row (Pencil JISSV: x:39 y:743, 4 子节点局部坐标 0/92/189/267, total width 297)
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(39), kScaleH(kFooterPadTop), kScaleW(297), kScaleH(kRegulatorHeight))];
        NSArray *logoData = @[
            @[@"mk_logo_sec",  @0,   @0, @58, @36],
            @[@"mk_logo_npc",  @92,  @3, @61, @29],
            @[@"mk_logo_pis",  @189, @3, @33, @30],
            @[@"mk_logo_cic",  @267, @3, @30, @30],
        ];
        for (NSArray *d in logoData) {
            UIImageView *iv = [[UIImageView alloc]
                initWithFrame:CGRectMake(kScaleW([d[1] floatValue]),
                                         kScaleH([d[2] floatValue]),
                                         kScaleW([d[3] floatValue]),
                                         kScaleH([d[4] floatValue]))];
            iv.image = [UIImage imageNamed:d[0]];
            iv.contentMode = UIViewContentModeScaleAspectFit;
            [row addSubview:iv];
        }
        [self addSubview:row];

        // Pencil bIbsf: x:39 (相对 frame), w:315, Poppins 14 #A6AFBC
        UILabel *footnote = [[UILabel alloc] initWithFrame:CGRectMake(
            kScaleW(39),
            kScaleH(kFooterPadTop + kRegulatorHeight + kRegulatorFootnote),
            kScaleW(315),
            kScaleH(kFootnoteHeight))];
        footnote.text = @"Adheres to Philippine Financial Regulations";
        footnote.font = kFontPoppins14;
        footnote.textColor = MKHexColor(0xA6AFBC);
        // Pencil bIbsf: 无 textAlign 字段 → 默认 left
        footnote.textAlignment = NSTextAlignmentLeft;
        [self addSubview:footnote];
    }
    return self;
}

@end
