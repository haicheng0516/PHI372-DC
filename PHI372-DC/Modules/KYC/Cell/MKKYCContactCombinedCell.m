//
//  MKKYCContactCombinedCell.m
//

#import "MKKYCContactCombinedCell.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

@interface MKKYCContactCombinedCell ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIControl *nameRow;
@property (nonatomic, strong) UILabel *nameValueLabel;
@property (nonatomic, strong) UIView *phoneRow;
@property (nonatomic, strong, readwrite) UITextField *phoneField;
@property (nonatomic, strong) UIImageView *chevron;
@end

@implementation MKKYCContactCombinedCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.cardView = [UIView new];
    self.cardView.backgroundColor = kColorKYCCell;      // Pencil: #F8F8F7
    self.cardView.layer.cornerRadius = 14;
    [self.contentView addSubview:self.cardView];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.top.equalTo(self.contentView).offset(8);
        make.bottom.equalTo(self.contentView).offset(-8);
    }];

    // 右侧 chevron — 中绿圆 #60A786 (Pencil 数据)
    UIView *chevronCircle = [UIView new];
    chevronCircle.backgroundColor = kColorChevronCircle;
    chevronCircle.layer.cornerRadius = 12;
    chevronCircle.userInteractionEnabled = NO;
    [self.cardView addSubview:chevronCircle];
    [chevronCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cardView).offset(-12);
        make.centerY.equalTo(self.cardView);
        make.width.height.mas_equalTo(24);
    }];

    self.chevron = [UIImageView new];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightBold];
    self.chevron.image = [[UIImage systemImageNamed:@"chevron.down" withConfiguration:cfg]
                          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.chevron.tintColor = kColorWhite;
    self.chevron.contentMode = UIViewContentModeScaleAspectFit;
    [chevronCircle addSubview:self.chevron];
    [self.chevron mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(chevronCircle);
        make.width.height.mas_equalTo(12);
    }];

    // 上半: Name 触发区 — Pencil 布局: label "Name" + 同行 "/Pick from Contacts" 占位
    self.nameRow = [UIControl new];
    [self.nameRow addTarget:self action:@selector(nameRowTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.nameRow];
    [self.nameRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.cardView);
        make.right.equalTo(chevronCircle.mas_left).offset(-8);
        make.height.equalTo(self.cardView).multipliedBy(0.5);
    }];

    self.nameValueLabel = [UILabel new];
    self.nameValueLabel.font = kFontPingFang14;
    self.nameValueLabel.textColor = kColorTextPrimary;
    [self.nameRow addSubview:self.nameValueLabel];
    [self.nameValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nameRow).offset(11);
        make.right.equalTo(self.nameRow);
        make.centerY.equalTo(self.nameRow);
        make.height.mas_equalTo(24);
    }];

    // 下半: Phone 输入
    self.phoneRow = [UIView new];
    [self.cardView addSubview:self.phoneRow];
    [self.phoneRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView);
        make.right.equalTo(chevronCircle.mas_left).offset(-8);
        make.top.equalTo(self.nameRow.mas_bottom);
        make.bottom.equalTo(self.cardView);
    }];

    self.phoneField = [UITextField new];
    self.phoneField.font = kFontPingFang14;
    self.phoneField.textColor = kColorTextPrimary;
    self.phoneField.borderStyle = UITextBorderStyleNone;
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    [self.phoneField addTarget:self action:@selector(phoneChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.phoneRow addSubview:self.phoneField];
    [self.phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.phoneRow).offset(11);
        make.right.equalTo(self.phoneRow);
        make.centerY.equalTo(self.phoneRow);
        make.height.mas_equalTo(24);
    }];
}

// 空状态: label 黑色 "Name " + 灰色 "/Pick from Contacts" 内联
// filled 状态: 黑色 16pt 值
- (NSAttributedString *)inlineLabel:(NSString *)label placeholder:(NSString *)placeholder {
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc]
        initWithString:label
        attributes:@{NSForegroundColorAttributeName: MKHexColor(0x999999),
                     NSFontAttributeName: kFontPingFang14}];
    NSAttributedString *value = [[NSAttributedString alloc]
        initWithString:[@"  /" stringByAppendingString:placeholder]
        attributes:@{NSForegroundColorAttributeName: MKHexColor(0x666666),
                     NSFontAttributeName: kFontPingFang14}];
    [att appendAttributedString:value];
    return att;
}

- (void)configWithName:(NSString *)name phone:(NSString *)phone {
    if (name.length > 0) {
        // filled: 16pt 黑色值
        self.nameValueLabel.attributedText = nil;
        self.nameValueLabel.font = kFontRegular(16);
        self.nameValueLabel.textColor = kColorTextPrimary;
        self.nameValueLabel.text = name;
    } else {
        // empty: "Name" 灰 + "  /Pick from Contacts" 深灰 内联
        self.nameValueLabel.attributedText = [self inlineLabel:@"Name" placeholder:@"Pick from Contacts"];
    }

    if (phone.length > 0) {
        self.phoneField.attributedPlaceholder = nil;
        self.phoneField.font = kFontRegular(16);
        self.phoneField.textColor = kColorTextPrimary;
        self.phoneField.text = phone;
    } else {
        self.phoneField.text = @"";
        self.phoneField.font = kFontPingFang14;
        self.phoneField.attributedPlaceholder = [self inlineLabel:@"Phone number" placeholder:@"Please enter"];
    }
}

- (void)nameRowTapped {
    if (self.onPickContactTapped) self.onPickContactTapped();
}

- (void)phoneChanged:(UITextField *)tf {
    if (self.onPhoneChanged) self.onPhoneChanged(tf.text ?: @"");
}

@end
