//
//  MKKYCInputCell.m
//

#import "MKKYCInputCell.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

@interface MKKYCInputCell () <UITextFieldDelegate>
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UITextField *inputField;
@property (nonatomic, strong) UIView *cardView;
@end

@implementation MKKYCInputCell

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

    self.inputField = [[UITextField alloc] init];
    // Pencil: input value 16pt #171718
    self.inputField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16] ?: kFontRegular(16);
    self.inputField.textColor = kColorTextPrimary;
    self.inputField.borderStyle = UITextBorderStyleNone;
    self.inputField.returnKeyType = UIReturnKeyDone;
    self.inputField.delegate = self;
    [self.inputField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.cardView addSubview:self.inputField];
    [self.inputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cardView).offset(11);
        make.right.equalTo(self.cardView).offset(-11);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
        make.height.mas_equalTo(24);
    }];
}

- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder {
    [self configWithTitle:title placeholder:placeholder value:nil];
}

- (void)configWithTitle:(NSString *)title placeholder:(NSString *)placeholder value:(NSString *)value {
    self.titleLabel.text = title;
    // Pencil: placeholder 14pt #666666
    UIFont *phFont = [UIFont fontWithName:@"PingFangSC-Regular" size:14] ?: kFontPingFang14;
    self.inputField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:placeholder ?: @""
        attributes:@{ NSForegroundColorAttributeName: MKHexColor(0x666666),
                      NSFontAttributeName: phFont }];
    self.inputField.text = value.length > 0 ? value : @"";
}

- (BOOL)becomeFirstResponder { return [self.inputField becomeFirstResponder]; }

- (void)textFieldDidChange:(UITextField *)field {
    if (self.textChangeBlock) self.textChangeBlock(field.text ?: @"");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.onReturnPressed) self.onReturnPressed();
    return YES;
}

// 照搬 259 FormInputCell shouldChangeCharactersInRange 主体: maxLength 拦截超长(粘贴/快速输入)
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.maxLength == 0) return YES;
    if (string.length == 0) return YES;  // 删除/退格放行
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return newString.length <= self.maxLength;
}

@end
