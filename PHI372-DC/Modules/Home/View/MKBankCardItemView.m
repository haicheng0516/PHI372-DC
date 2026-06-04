//
//  MKBankCardItemView.m
//  Pencil 银行卡 cell (339×171)
//
//  背景: mk_bank_cell 设计图 (绿色波纹底, 自带圆角)
//  文字: 全部深色 (kColorTextPrimary)
//  Default: 右上 radio (外圈描深色, 选中时填 kColorPrimary 内点) + "Default" 文字
//  Submit: 右下 #BBCB2F 胶囊 + mk_bank_pen + "Submit" 深色字
//

#import "MKBankCardItemView.h"
#import "MKConstants.h"

@interface MKBankCardItemView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *bankLabel;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *holderLabel;
@property (nonatomic, strong) UILabel *defaultBadge;
@property (nonatomic, strong) UIView *radioOuter;
@property (nonatomic, strong) UIView *radioDot;
@property (nonatomic, strong) UIButton *submitBtn;
@end

@implementation MKBankCardItemView

+ (CGFloat)cardHeight { return kScaleH(171); }

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mk_bank_cell"]];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImageView.clipsToBounds = YES;
        [self addSubview:_bgImageView];

        _bankLabel = [UILabel new];
        _bankLabel.font = kFontRegular(14);
        _bankLabel.textColor = kColorTextPrimary;
        [self addSubview:_bankLabel];

        _defaultBadge = [UILabel new];
        _defaultBadge.text = @"Default";
        _defaultBadge.font = kFontRegular(12);
        _defaultBadge.textColor = kColorTextPrimary;
        _defaultBadge.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_defaultBadge];

        // radio 外圈
        _radioOuter = [UIView new];
        _radioOuter.layer.cornerRadius = kScaleW(8);
        _radioOuter.layer.borderWidth = 1.5;
        _radioOuter.layer.borderColor = kColorTextPrimary.CGColor;
        _radioOuter.backgroundColor = [UIColor clearColor];
        [self addSubview:_radioOuter];

        // radio 内点 (选中时显)
        _radioDot = [UIView new];
        _radioDot.layer.cornerRadius = kScaleW(4);
        _radioDot.backgroundColor = kColorPrimary;
        _radioDot.hidden = YES;
        [_radioOuter addSubview:_radioDot];

        _numberLabel = [UILabel new];
        _numberLabel.font = [UIFont systemFontOfSize:kScaleW(20) weight:UIFontWeightBold];
        _numberLabel.textColor = kColorTextPrimary;
        [self addSubview:_numberLabel];

        _holderLabel = [UILabel new];
        _holderLabel.font = kFontSemibold(13);
        _holderLabel.textColor = kColorTextPrimary;
        _holderLabel.numberOfLines = 2;
        [self addSubview:_holderLabel];

        // Submit 按钮: #BBCB2F + mk_bank_pen + 深色字
        _submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _submitBtn.backgroundColor = kColorAccentGreen;
        _submitBtn.layer.cornerRadius = kScaleH(18);
        [_submitBtn setImage:[UIImage imageNamed:@"mk_bank_pen"] forState:UIControlStateNormal];
        [_submitBtn setTitle:@"  Submit" forState:UIControlStateNormal];
        [_submitBtn setTitleColor:kColorTextPrimary forState:UIControlStateNormal];
        _submitBtn.titleLabel.font = kFontSemibold(13);
        [_submitBtn addTarget:self action:@selector(submitTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_submitBtn];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    self.bgImageView.frame = self.bounds;
    self.bankLabel.frame    = CGRectMake(kScaleW(17), kScaleH(26), kScaleW(180), kScaleH(20));
    // Pencil: radio (外圈 16) 左, "Default" 文字右; 整组贴右 17
    CGFloat badgeW = kScaleW(50);
    CGFloat radioSize = kScaleW(16);
    self.defaultBadge.frame = CGRectMake(W - kScaleW(17) - badgeW, kScaleH(15), badgeW, kScaleH(18));
    self.radioOuter.frame   = CGRectMake(CGRectGetMinX(self.defaultBadge.frame) - radioSize - kScaleW(6),
                                          kScaleH(16), radioSize, radioSize);
    self.radioDot.frame     = CGRectMake((radioSize - kScaleW(8)) / 2.0, (radioSize - kScaleW(8)) / 2.0,
                                          kScaleW(8), kScaleW(8));
    self.numberLabel.frame  = CGRectMake(kScaleW(17), kScaleH(71), W - kScaleW(34), kScaleH(24));
    self.holderLabel.frame  = CGRectMake(kScaleW(17), kScaleH(120), kScaleW(180), kScaleH(36));
    self.submitBtn.frame    = CGRectMake(W - kScaleW(120), kScaleH(120), kScaleW(106), kScaleH(37));
}

- (void)tapped       { if (self.onSelected) self.onSelected(); }
- (void)submitTapped { if (self.onSubmitTapped) self.onSubmitTapped(); }

/// 触点落在 Submit 按钮内时不让 card-tap 抢, 避免 onSelected/onSubmitTapped 同时触发
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint p = [touch locationInView:self.submitBtn];
    return !CGRectContainsPoint(self.submitBtn.bounds, p);
}

- (void)setBankName:(NSString *)v   { _bankName = [v copy]; self.bankLabel.text = v; }
- (void)setCardNumber:(NSString *)v { _cardNumber = [v copy]; self.numberLabel.text = v; }
- (void)setHolderName:(NSString *)v { _holderName = [v copy]; self.holderLabel.text = v; }
- (void)setIsDefault:(BOOL)v        { _isDefault = v; }
- (void)setSelected:(BOOL)v {
    _selected = v;
    self.radioDot.hidden = !v;
}
@end
