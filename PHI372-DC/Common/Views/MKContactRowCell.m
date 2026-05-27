//
//  MKContactRowCell.m
//

#import "MKContactRowCell.h"
#import "MKConstants.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKContactRowCell ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIButton *actionBtn;
@property (nonatomic, copy) NSString *contactValue;
@end

@implementation MKContactRowCell

+ (CGFloat)cellHeight { return kScaleH(60); }

- (instancetype)initWithKind:(MKContactRowKind)kind value:(NSString *)value {
    if (self = [super init]) {
        self.backgroundColor = MKHexColor(0xE9E9E4);
        self.layer.cornerRadius = kScaleH(14);
        _contactValue = [value copy];

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = kColorPrimary;
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightRegular];
        NSString *symbol = kind == MKContactRowKindWebsite ? @"globe" : @"envelope.fill";
        _iconView.image = [[UIImage systemImageNamed:symbol withConfiguration:cfg]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self addSubview:_iconView];

        _valueLabel = [UILabel new];
        _valueLabel.text = value;
        _valueLabel.font = kFontRegular(16);
        _valueLabel.textColor = kColorPrimary;
        [self addSubview:_valueLabel];

        UIImageSymbolConfiguration *copyCfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular];
        UIImage *copyImg = [[UIImage systemImageNamed:@"doc.on.doc" withConfiguration:copyCfg]
                            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _actionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_actionBtn setImage:copyImg forState:UIControlStateNormal];
        _actionBtn.tintColor = MKHexColor(0x999999);
        [_actionBtn addTarget:self action:@selector(copyTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_actionBtn];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height;
    CGFloat w = self.bounds.size.width;
    self.iconView.frame = CGRectMake(kScaleW(9), (h - kScaleW(42)) * 0.5, kScaleW(42), kScaleW(42));
    CGFloat textX = kScaleW(56);
    self.valueLabel.frame = CGRectMake(textX, 0, w - textX - kScaleW(48), h);
    self.actionBtn.frame = CGRectMake(w - kScaleW(40), (h - kScaleW(24)) * 0.5, kScaleW(24), kScaleW(24));
}

- (void)copyTapped {
    if (self.contactValue.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"No content to copy"];
        return;
    }
    UIPasteboard.generalPasteboard.string = self.contactValue;
    [SVProgressHUD showSuccessWithStatus:@"Copied to clipboard"];
    if (self.onCopyTapped) self.onCopyTapped(self.contactValue);
}
@end
