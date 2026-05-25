//
//  MKBankCardItemView.m
//  PHI372-DC — Figma 3:1188 银行卡 cell
//
//  布局 (339×171 r=20):
//    背景: 深绿底 + 渐变高光 (#002903 → #11722E)
//    bank name (17, 26) Poppins 14 #002903 (但文字白色更醒目, 使用 white)
//    Default 标签 (右上, ~283, 16) Poppins 12 white
//    Selected 圆 (右上, 264, 14) 16×16 stroke white / filled white check
//    Card number (17, 71) Poppins 600 20 white
//    Holder (17, 126) PingFang SC 600 13 white
//    Submit 按钮 (右下, 224, 119) 106×37 r=28 #BBCB2F + pen 图标 + "Submit"
//

#import "MKBankCardItemView.h"
#import "MKConstants.h"

@interface MKBankCardItemView ()
@property (nonatomic, strong) CAGradientLayer *bgGradient;
@property (nonatomic, strong) UILabel *bankLabel;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *holderLabel;
@property (nonatomic, strong) UILabel *defaultBadge;
@property (nonatomic, strong) UIView *selectMark;
@property (nonatomic, strong) UIImageView *selectMarkIcon;
@property (nonatomic, strong) UIButton *submitBtn;
@end

@implementation MKBankCardItemView

+ (CGFloat)cardHeight { return kScaleH(171); }

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = kScaleH(20);
        self.clipsToBounds = YES;

        _bgGradient = [CAGradientLayer layer];
        _bgGradient.colors = @[ (id)MKHexColor(0x0F4220).CGColor, (id)MKHexColor(0x11722E).CGColor ];
        _bgGradient.startPoint = CGPointMake(0, 0);
        _bgGradient.endPoint = CGPointMake(1, 1);
        [self.layer addSublayer:_bgGradient];

        _bankLabel = [UILabel new];
        _bankLabel.font = kFontRegular(14);
        _bankLabel.textColor = kColorWhite;
        [self addSubview:_bankLabel];

        _defaultBadge = [UILabel new];
        _defaultBadge.text = @"Default";
        _defaultBadge.font = kFontRegular(12);
        _defaultBadge.textColor = kColorWhite;
        _defaultBadge.textAlignment = NSTextAlignmentRight;
        [self addSubview:_defaultBadge];

        _selectMark = [UIView new];
        _selectMark.layer.cornerRadius = kScaleW(8);
        _selectMark.layer.borderWidth = 1;
        _selectMark.layer.borderColor = kColorWhite.CGColor;
        [self addSubview:_selectMark];

        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightBold];
        _selectMarkIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"checkmark" withConfiguration:cfg]
                                                              imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _selectMarkIcon.tintColor = kColorPrimary;
        _selectMarkIcon.hidden = YES;
        _selectMarkIcon.contentMode = UIViewContentModeCenter;
        [_selectMark addSubview:_selectMarkIcon];

        _numberLabel = [UILabel new];
        _numberLabel.font = [UIFont systemFontOfSize:kScaleW(20) weight:UIFontWeightBold];
        _numberLabel.textColor = kColorWhite;
        [self addSubview:_numberLabel];

        _holderLabel = [UILabel new];
        _holderLabel.font = kFontSemibold(13);
        _holderLabel.textColor = kColorWhite;
        _holderLabel.alpha = 0.85;
        [self addSubview:_holderLabel];

        // Submit 按钮
        _submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _submitBtn.backgroundColor = MKHexColor(0xBBCB2F);
        _submitBtn.layer.cornerRadius = kScaleH(18);
        UIImageSymbolConfiguration *pcfg = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightSemibold];
        UIImage *pen = [[UIImage systemImageNamed:@"square.and.pencil" withConfiguration:pcfg]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_submitBtn setImage:pen forState:UIControlStateNormal];
        [_submitBtn setTitle:@"  Submit" forState:UIControlStateNormal];
        [_submitBtn setTitleColor:kColorPrimary forState:UIControlStateNormal];
        _submitBtn.tintColor = kColorPrimary;
        _submitBtn.titleLabel.font = kFontSemibold(13);
        [_submitBtn addTarget:self action:@selector(submitTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_submitBtn];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    self.bgGradient.frame = self.bounds;
    self.bankLabel.frame   = CGRectMake(kScaleW(17), kScaleH(26), kScaleW(180), kScaleH(20));
    self.defaultBadge.frame = CGRectMake(W - kScaleW(60), kScaleH(15), kScaleW(45), kScaleH(18));
    self.selectMark.frame  = CGRectMake(W - kScaleW(82), kScaleH(16), kScaleW(16), kScaleW(16));
    self.selectMarkIcon.frame = self.selectMark.bounds;
    self.numberLabel.frame = CGRectMake(kScaleW(17), kScaleH(71), W - kScaleW(34), kScaleH(24));
    self.holderLabel.frame = CGRectMake(kScaleW(17), kScaleH(126), kScaleW(180), kScaleH(20));
    self.submitBtn.frame   = CGRectMake(W - kScaleW(120), kScaleH(120), kScaleW(106), kScaleH(37));
}

- (void)tapped       { if (self.onSelected) self.onSelected(); }
- (void)submitTapped { if (self.onSubmitTapped) self.onSubmitTapped(); }

- (void)setBankName:(NSString *)v   { _bankName = [v copy]; self.bankLabel.text = v; }
- (void)setCardNumber:(NSString *)v { _cardNumber = [v copy]; self.numberLabel.text = v; }
- (void)setHolderName:(NSString *)v { _holderName = [v copy]; self.holderLabel.text = v; }
- (void)setIsDefault:(BOOL)v        { _isDefault = v; self.defaultBadge.hidden = !v; }
- (void)setSelected:(BOOL)v {
    _selected = v;
    if (v) {
        self.selectMark.backgroundColor = kColorWhite;
        self.selectMarkIcon.hidden = NO;
    } else {
        self.selectMark.backgroundColor = [UIColor clearColor];
        self.selectMarkIcon.hidden = YES;
    }
}
@end
