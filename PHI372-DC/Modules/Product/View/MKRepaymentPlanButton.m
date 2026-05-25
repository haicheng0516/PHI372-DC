//
//  MKRepaymentPlanButton.m
//  PHI372-DC
//

#import "MKRepaymentPlanButton.h"
#import "MKConstants.h"

@interface MKRepaymentPlanButton ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *chevronCircle;
@property (nonatomic, strong) UIImageView *chevronIcon;
@end

@implementation MKRepaymentPlanButton

+ (CGFloat)buttonHeight {
    return kScaleH(56);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = kColorAccentGreen;
        self.layer.cornerRadius = kScaleH(28);

        _titleLabel = [UILabel new];
        _titleLabel.text = @"Repayment plan";
        _titleLabel.font = kFontSemibold(16);
        _titleLabel.textColor = kColorTextPrimary;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        _chevronCircle = [UIView new];
        _chevronCircle.backgroundColor = kColorWhite;
        _chevronCircle.layer.cornerRadius = kScaleW(10);
        _chevronCircle.userInteractionEnabled = NO;
        [self addSubview:_chevronCircle];

        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightBold];
        _chevronIcon = [[UIImageView alloc] initWithImage:
                        [[UIImage systemImageNamed:@"chevron.right" withConfiguration:cfg]
                         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _chevronIcon.tintColor = kColorTextPrimary;
        _chevronIcon.contentMode = UIViewContentModeCenter;
        _chevronIcon.userInteractionEnabled = NO;
        [_chevronCircle addSubview:_chevronIcon];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = [title copy];
    self.titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    self.titleLabel.frame = CGRectMake(kScaleW(18), 0, W * 0.65, H);

    CGFloat chevSize = kScaleW(20);
    self.chevronCircle.frame = CGRectMake(W - chevSize - kScaleW(18),
                                          (H - chevSize) * 0.5,
                                          chevSize, chevSize);
    self.chevronIcon.frame = self.chevronCircle.bounds;
}

@end
