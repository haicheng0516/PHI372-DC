//
//  MKDetailRow.m
//  PHI372-DC
//

#import "MKDetailRow.h"
#import "MKConstants.h"

@interface MKDetailRow ()
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) UILabel *valueView;
@property (nonatomic, strong) UIControl *infoBtn;       // 可选
@end

@implementation MKDetailRow

+ (CGFloat)rowHeight {
    return kScaleH(20);
}

- (instancetype)initWithLabel:(NSString *)label hasInfoIcon:(BOOL)hasInfoIcon {
    if (self = [super initWithFrame:CGRectZero]) {
        _labelView = [UILabel new];
        _labelView.text = label;
        _labelView.font = kFontRegular(14);
        _labelView.textColor = MKHexColor(0x999999);
        [self addSubview:_labelView];

        if (hasInfoIcon) {
            _infoBtn = [UIControl new];
            [_infoBtn addTarget:self action:@selector(infoTap) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_infoBtn];

            UIImageView *icon = [[UIImageView alloc] initWithImage:
                                 [[UIImage systemImageNamed:@"info.circle"]
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            icon.tintColor = MKHexColor(0x999999);
            icon.tag = 9101;
            icon.userInteractionEnabled = NO;
            [_infoBtn addSubview:icon];
        }

        _valueView = [UILabel new];
        _valueView.font = kFontRegular(14);
        _valueView.textColor = MKHexColor(0x333333);
        _valueView.textAlignment = NSTextAlignmentRight;
        [self addSubview:_valueView];
    }
    return self;
}

- (void)setValue:(NSString *)value {
    _value = [value copy];
    self.valueView.text = value.length > 0 ? value : @"--";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    [self.labelView sizeToFit];
    CGFloat textW = MIN(W * 0.6, self.labelView.frame.size.width);
    self.labelView.frame = CGRectMake(0, 0, textW, H);

    if (self.infoBtn) {
        CGFloat iconSize = kScaleW(14);
        CGFloat hitPad = kScaleW(10);
        CGFloat infoX = textW + kScaleW(6);
        self.infoBtn.frame = CGRectMake(infoX,
                                        (H - iconSize) * 0.5 - kScaleW(2),
                                        iconSize + hitPad, iconSize + hitPad);
        UIImageView *icon = (UIImageView *)[self.infoBtn viewWithTag:9101];
        icon.frame = CGRectMake(kScaleW(2), kScaleW(2), iconSize, iconSize);
    }

    self.valueView.frame = CGRectMake(W * 0.4, 0, W * 0.6, H);
}

- (void)infoTap {
    if (self.onInfoTapped) self.onInfoTapped(self.infoBtn);
}

@end
