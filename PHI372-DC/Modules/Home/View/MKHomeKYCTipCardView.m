//
//  MKHomeKYCTipCardView.m
//  PHI372-DC
//
//  Figma KYC 提示卡 — 灰底圆角 + 左上橙色 ! icon + 右侧多行文字
//

#import "MKHomeKYCTipCardView.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

@interface MKHomeKYCTipCardView ()
@property (nonatomic, strong) UIImageView *hintIcon;
@property (nonatomic, strong) UILabel *textLabel;
@end

@implementation MKHomeKYCTipCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = MKHexColor(0xE9E9E4);
        self.layer.cornerRadius = 14;

        // 左上 ! icon (Pencil: 24×24, 相对卡 (9, 8))
        self.hintIcon = [[UIImageView alloc] init];
        self.hintIcon.image = [UIImage imageNamed:@"mk_icon_hint"];
        self.hintIcon.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.hintIcon];
        [self.hintIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(9);
            make.top.equalTo(self).offset(8);
            make.width.height.equalTo(@24);
        }];

        // 右侧文字 (Pencil: text x:37 y:9, 即 iconR(33)+4, top 9, right padding 9)
        self.textLabel = [UILabel new];
        self.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14] ?: [UIFont systemFontOfSize:14];
        self.textLabel.textColor = MKHexColor(0x999999);
        self.textLabel.numberOfLines = 0;
        [self addSubview:self.textLabel];
        [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.hintIcon.mas_right).offset(4);
            make.right.equalTo(self).offset(-9);
            make.top.equalTo(self).offset(9);
            make.bottom.lessThanOrEqualTo(self).offset(-9);
        }];

        self.tipText = @"Please complete the KYC certifcation beforeusing our loan service.";
    }
    return self;
}

- (void)setTipText:(NSString *)t {
    _tipText = [t copy];
    self.textLabel.text = t;
}

/// 内部布局 (Pencil): icon 24w at left 9 + gap 4 + 文字 (right padding 9, top/bot 9)
+ (CGFloat)heightForText:(NSString *)text cardWidth:(CGFloat)cardWidth {
    static const CGFloat kIconWidth   = 24;
    static const CGFloat kIconGap     = 4;
    static const CGFloat kLeftPadding = 9;
    static const CGFloat kRightPadding= 9;
    static const CGFloat kTopPadding  = 9;
    static const CGFloat kBotPadding  = 9;
    CGFloat textWidth = cardWidth - kLeftPadding - kIconWidth - kIconGap - kRightPadding;
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size:14] ?: [UIFont systemFontOfSize:14];
    CGFloat textHeight = ceilf([text ?: @""
        boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                     options:NSStringDrawingUsesLineFragmentOrigin
                  attributes:@{ NSFontAttributeName: font }
                     context:nil].size.height);
    // icon 行至少和 icon 一样高
    CGFloat contentHeight = MAX(textHeight, kIconWidth);
    return kTopPadding + contentHeight + kBotPadding;
}

@end
