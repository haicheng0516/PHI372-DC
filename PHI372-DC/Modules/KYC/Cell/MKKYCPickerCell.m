//
//  MKKYCPickerCell.m
//

#import "MKKYCPickerCell.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

@interface MKKYCPickerCell ()
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *valueLabel;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *chevronCircle;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, copy) NSString *placeholder;
@end

@implementation MKKYCPickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = kColorKYCCell;    // Pencil: #F8F8F7
    self.cardView.layer.cornerRadius = 14;
    [self.contentView addSubview:self.cardView];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.top.equalTo(self.contentView).offset(8);
        make.bottom.equalTo(self.contentView).offset(-8);
    }];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.cardView addGestureRecognizer:tap];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = kFontPingFang14;
    self.titleLabel.textColor = kColorTextSecondary;
    [self.cardView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(11);
        make.right.equalTo(self.cardView).offset(-11);
        make.top.equalTo(self.cardView).offset(9);
        make.height.mas_equalTo(20);
    }];

    // 绿色实心圆容器 + 白色 chevron — Pencil: 18×18 circle (r=9) inside 24×24 hit area
    self.chevronCircle = [UIView new];
    self.chevronCircle.backgroundColor = kColorChevronCircle;   // #60A786
    self.chevronCircle.layer.cornerRadius = 9;
    self.chevronCircle.userInteractionEnabled = NO;
    [self.cardView addSubview:self.chevronCircle];
    [self.chevronCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cardView).offset(-10);
        make.centerY.equalTo(self.cardView);
        make.width.height.mas_equalTo(18);
    }];

    self.arrowImageView = [[UIImageView alloc] init];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:9 weight:UIImageSymbolWeightBold];
    self.arrowImageView.image = [[UIImage systemImageNamed:@"chevron.down" withConfiguration:cfg]
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.arrowImageView.tintColor = kColorWhite;
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.chevronCircle addSubview:self.arrowImageView];
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.chevronCircle);
        make.width.height.mas_equalTo(10);
    }];

    self.valueLabel = [[UILabel alloc] init];
    // Pencil: placeholder 14pt #666666; filled value 16pt #171718 — set in setSelectedValue:
    self.valueLabel.font = kFontPingFang14;
    self.valueLabel.textColor = MKHexColor(0x666666);
    [self.cardView addSubview:self.valueLabel];
    [self.valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(11);
        make.right.equalTo(self.chevronCircle.mas_left).offset(-8);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
        make.height.mas_equalTo(24);
    }];
}

- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder {
    self.titleLabel.text = title;
    self.placeholder = placeholder;
    self.valueLabel.text = placeholder;
    // Pencil placeholder: PingFang SC 14pt #666666
    self.valueLabel.font = kFontPingFang14;
    self.valueLabel.textColor = MKHexColor(0x666666);
}

- (void)setSelectedValue:(NSString *)value {
    if (value.length > 0) {
        self.valueLabel.text = value;
        // Pencil filled value: PingFang SC 16pt #171718
        self.valueLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16] ?: kFontRegular(16);
        self.valueLabel.textColor = kColorTextPrimary;
    } else {
        self.valueLabel.text = self.placeholder ?: @"";
        self.valueLabel.font = kFontPingFang14;
        self.valueLabel.textColor = MKHexColor(0x666666);
    }
}

- (void)handleTap {
    if (self.tapBlock) self.tapBlock();
}

@end
