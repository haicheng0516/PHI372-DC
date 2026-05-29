//
//  MKRepaymentPlanCell.m
//

#import "MKRepaymentPlanCell.h"
#import "MKConstants.h"

@interface MKRepaymentPlanCell ()
@property (nonatomic, strong) UIControl *button;
@end

@implementation MKRepaymentPlanCell

+ (CGFloat)cellHeight {
    // Pencil button h=56 + 上下间距 8/8
    return kScaleH(56) + kScaleH(16);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = kColorBackground;
        self.backgroundColor = kColorBackground;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self build];
    }
    return self;
}

- (void)build {
    _button = [UIControl new];
    _button.backgroundColor = kColorAccentGreen;  // #BBCB2F
    _button.layer.cornerRadius = kScaleH(14);
    [_button addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_button];

    UILabel *label = [UILabel new];
    label.text = @"Repayment plan";
    label.font = kFontSemibold(14);
    label.textColor = kColorPrimary;
    label.tag = 901;
    [_button addSubview:label];

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold];
    UIImage *arrow = [[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *iv = [[UIImageView alloc] initWithImage:arrow];
    iv.tintColor = kColorAccentGreen;
    iv.backgroundColor = kColorPrimary;
    iv.contentMode = UIViewContentModeCenter;
    iv.layer.cornerRadius = kScaleW(10);
    iv.tag = 902;
    [_button addSubview:iv];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // Pencil: x=36, y=515 → 此 cell 局部 y=8, 按钮 303×56
    self.button.frame = CGRectMake(kScaleW(36), kScaleH(8), kScaleW(303), kScaleH(56));
    UILabel *label = (UILabel *)[self.button viewWithTag:901];
    label.frame = CGRectMake(kScaleW(18), 0, kScaleW(200), kScaleH(56));
    UIImageView *iv = (UIImageView *)[self.button viewWithTag:902];
    iv.frame = CGRectMake(kScaleW(303 - 18 - 20), (kScaleH(56) - kScaleW(20)) * 0.5,
                          kScaleW(20), kScaleW(20));
}

- (void)tap { if (self.onTapped) self.onTapped(); }

@end
