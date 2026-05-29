//
//  MKFormField.m
//

#import "MKFormField.h"
#import "MKConstants.h"

@interface MKFormField ()
@property (nonatomic, assign, readwrite) MKFormFieldType fieldType;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UITextField *textField;
@property (nonatomic, strong, readwrite) UILabel *valueLabel;
@property (nonatomic, strong) UIView *inputBox;
@property (nonatomic, strong) UIImageView *arrowView;
@property (nonatomic, copy) NSString *placeholder;
@end

@implementation MKFormField

+ (CGFloat)fieldHeight {
    return 76; // 20(title) + 4(gap) + 56(input) = 80, but design shows ~76
}

- (instancetype)initWithType:(MKFormFieldType)type {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _fieldType = type;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    self.titleLabel.textColor = MKHexColor(0x88979C);
    [self addSubview:self.titleLabel];

    // Input box background
    self.inputBox = [[UIView alloc] init];
    self.inputBox.backgroundColor = MKHexColor(0xF0F2EE);
    self.inputBox.layer.cornerRadius = 20;
    self.inputBox.clipsToBounds = YES;
    [self addSubview:self.inputBox];

    if (self.fieldType == MKFormFieldTypeInput) {
        self.textField = [[UITextField alloc] init];
        self.textField.font = [UIFont systemFontOfSize:14];
        self.textField.textColor = MKHexColor(0x171F14);
        [self.inputBox addSubview:self.textField];
    } else {
        // Picker mode: value label + arrow
        self.valueLabel = [[UILabel alloc] init];
        self.valueLabel.font = [UIFont systemFontOfSize:14];
        self.valueLabel.textColor = MKHexColor(0x171F14);
        [self.inputBox addSubview:self.valueLabel];

        self.arrowView = [[UIImageView alloc] init];
        self.arrowView.image = [UIImage systemImageNamed:@"chevron.right"];
        self.arrowView.tintColor = [UIColor blackColor];
        self.arrowView.contentMode = UIViewContentModeScaleAspectFit;
        [self.inputBox addSubview:self.arrowView];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerTapped)];
        [self.inputBox addGestureRecognizer:tap];
        self.inputBox.userInteractionEnabled = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;

    self.titleLabel.frame = CGRectMake(10, 0, w - 20, 20);
    self.inputBox.frame = CGRectMake(0, 24, w, 56);

    if (self.fieldType == MKFormFieldTypeInput) {
        self.textField.frame = CGRectMake(20, 0, w - 40, 56);
    } else {
        self.valueLabel.frame = CGRectMake(20, 0, w - 60, 56);
        self.arrowView.frame = CGRectMake(w - 36, 20, 16, 16);
    }
}

#pragma mark - Public

- (void)setTitle:(NSString *)title placeholder:(NSString *)placeholder {
    self.titleLabel.text = title;
    self.placeholder = placeholder;
    if (self.fieldType == MKFormFieldTypeInput) {
        self.textField.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:placeholder
            attributes:@{NSForegroundColorAttributeName: MKHexColor(0xBCC0BA),
                         NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    } else {
        self.valueLabel.text = placeholder;
        self.valueLabel.textColor = MKHexColor(0xBCC0BA);
    }
}

- (void)setSelectedValue:(NSString *)value {
    if (value.length > 0) {
        self.valueLabel.text = value;
        self.valueLabel.textColor = MKHexColor(0x171F14);
    } else {
        self.valueLabel.text = self.placeholder;
        self.valueLabel.textColor = MKHexColor(0xBCC0BA);
    }
}

- (NSString *)inputValue {
    if (self.fieldType == MKFormFieldTypeInput) {
        return self.textField.text ?: @"";
    }
    return self.valueLabel.text ?: @"";
}

- (void)pickerTapped {
    if (self.pickerTapBlock) {
        self.pickerTapBlock();
    }
}

@end
