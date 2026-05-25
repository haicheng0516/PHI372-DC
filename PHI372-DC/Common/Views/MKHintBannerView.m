//
//  MKHintBannerView.m
//

#import "MKHintBannerView.h"
#import "MKConstants.h"

@interface MKHintBannerView ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *textLabel;
@end

@implementation MKHintBannerView

+ (CGFloat)heightForText:(NSString *)text {
    // icon 24×24 @ (9,8); text @ (37,9) 宽 = 339-37-12 = 290, font 14
    CGFloat width = kScaleW(290);
    UIFont *font = [UIFont systemFontOfSize:kScaleW(14)];
    CGFloat textH = [text ?: @"" boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: font}
                                              context:nil].size.height;
    return MAX(ceilf(textH), kScaleW(24)) + kScaleH(18);  // 9 上 + 9 下 padding
}

- (instancetype)initWithText:(NSString *)text {
    if (self = [super init]) {
        self.backgroundColor = MKHexColor(0xE9E9E4);
        self.layer.cornerRadius = kScaleH(14);

        _iconView = [[UIImageView alloc] init];
        _iconView.image = [UIImage imageNamed:@"mk_icon_hint"];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconView];

        _textLabel = [UILabel new];
        _textLabel.text = text;
        _textLabel.font = kFontRegular(14);
        _textLabel.textColor = MKHexColor(0x999999);
        _textLabel.numberOfLines = 0;
        [self addSubview:_textLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.iconView.frame = CGRectMake(kScaleW(9), kScaleH(9), kScaleW(24), kScaleW(24));
    CGFloat textX = kScaleW(37);
    self.textLabel.frame = CGRectMake(textX, kScaleH(9),
                                        self.bounds.size.width - textX - kScaleW(12),
                                        self.bounds.size.height - kScaleH(18));
}
@end
