//
//  MKBankCardView.m
//  设计图 okZYR:
//  默认卡: 背景图jtln_bank_bg + 白色文字
//  非默认卡: 无背景 + 灰色(#6E766B)文字
//  布局: name+Default(top 20) | cardNumber(中间) | ifsc+edit(bottom)
//

#import "MKBankCardView.h"
#import "MKConstants.h"

@interface MKBankCardView ()
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *nameLabel;          // 持卡人（左上）
@property (nonatomic, strong) UIImageView *defaultIcon;    // 默认勾选图标（右上）
@property (nonatomic, strong) UILabel *defaultLabel;       // "Default" 文字
@property (nonatomic, strong) UILabel *bankNameLabel;      // 银行名称（持卡人下方）
@property (nonatomic, strong) UILabel *cardNumberLabel;    // 卡号（中间大字）
@property (nonatomic, strong) UILabel *ifscLabel;          // IFSC（左下）
@property (nonatomic, strong) UIButton *editBtn;           // 编辑（右下）
@property (nonatomic, strong) UIButton *deleteBtn;
@end

@implementation MKBankCardView

+ (CGFloat)preferredHeight {
    return 200;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 20;
        self.clipsToBounds = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 背景图（默认卡有，非默认卡隐藏）
    self.bgImageView = [[UIImageView alloc] init];
    self.bgImageView.image = [UIImage imageNamed:@"gsssss_bank_bg"];
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.bgImageView.clipsToBounds = YES;
    [self addSubview:self.bgImageView];

    // 持卡人名（左上）
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = kFontRegular(14);
    [self addSubview:self.nameLabel];

    // Default 勾选图标（名字右侧）
    self.defaultIcon = [[UIImageView alloc] init];
    self.defaultIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.defaultIcon.hidden = YES;
    self.defaultIcon.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(defaultTapped)];
    [self.defaultIcon addGestureRecognizer:tap];
    [self addSubview:self.defaultIcon];

    // 银行名称（持卡人下方）
    self.bankNameLabel = [[UILabel alloc] init];
    self.bankNameLabel.font = kFontRegular(14);
    [self addSubview:self.bankNameLabel];

    // "Default" 文字
    self.defaultLabel = [[UILabel alloc] init];
    self.defaultLabel.text = @"Default";
    self.defaultLabel.font = kFontRegular(14);
    self.defaultLabel.hidden = YES;
    [self addSubview:self.defaultLabel];

    // 卡号
    self.cardNumberLabel = [[UILabel alloc] init];
    self.cardNumberLabel.font = kFontBold(24);
    [self addSubview:self.cardNumberLabel];

    // IFSC
    self.ifscLabel = [[UILabel alloc] init];
    self.ifscLabel.font = kFontRegular(14);
    [self addSubview:self.ifscLabel];

    // 编辑按钮
    self.editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editBtn setImage:[UIImage imageNamed:@"gsssss_bank_edit"] forState:UIControlStateNormal];
    self.editBtn.hidden = YES;
    [self.editBtn addTarget:self action:@selector(editTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.editBtn];

    // 删除按钮（预留）
    self.deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteBtn setImage:[UIImage systemImageNamed:@"trash"] forState:UIControlStateNormal];
    self.deleteBtn.tintColor = kColorWhite;
    self.deleteBtn.hidden = YES;
    [self.deleteBtn addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.deleteBtn];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    self.bgImageView.frame = self.bounds;

    // 设计图精确坐标（相对卡片 top, 卡高200）：
    // 持卡人 offset=20   Default图标 offset=20   Default文字 offset=20
    // 卡号 offset=126    (bold 24, h=28)
    // IFSC offset=164    (font14, h=16)   编辑图标 offset=160 (20x20)
    self.nameLabel.frame = CGRectMake(20, 20, w - 120, 16);
    self.defaultIcon.frame = CGRectMake(w - 69, 20, 16, 16);
    self.defaultLabel.frame = CGRectMake(w - 49, 20, 45, 16);
    self.bankNameLabel.frame = CGRectMake(20, 44, w - 120, 16);
    self.cardNumberLabel.frame = CGRectMake(20, 126, w - 60, 28);
    self.ifscLabel.frame = CGRectMake(20, 164, w - 60, 16);
    self.editBtn.frame = CGRectMake(w - 40, 160, 20, 20);
    self.deleteBtn.frame = CGRectMake(w - 40, 160, 20, 20);
}

#pragma mark - Public

- (void)setBankName:(NSString *)bankName
        accountName:(NSString *)accountName
         cardNumber:(NSString *)cardNumber
               ifsc:(NSString *)ifsc {
    self.nameLabel.text = accountName;
    self.bankNameLabel.text = bankName;
    // 格式化卡号
    NSString *clean = [cardNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableString *formatted = [NSMutableString string];
    for (NSInteger i = 0; i < (NSInteger)clean.length; i++) {
        if (i > 0 && i % 4 == 0) [formatted appendString:@" "];
        [formatted appendFormat:@"%C", [clean characterAtIndex:i]];
    }
    self.cardNumberLabel.text = formatted;
    self.ifscLabel.text = ifsc;
}

- (void)setShowDeleteButton:(BOOL)showDeleteButton {
    _showDeleteButton = showDeleteButton;
    self.deleteBtn.hidden = !showDeleteButton;
}

- (void)setShowEditButton:(BOOL)showEditButton {
    _showEditButton = showEditButton;
    self.editBtn.hidden = !showEditButton;
}

- (void)setShowDefaultToggle:(BOOL)showDefaultToggle {
    _showDefaultToggle = showDefaultToggle;
    self.defaultIcon.hidden = !showDefaultToggle;
    self.defaultLabel.hidden = !showDefaultToggle;
}

- (void)setIsDefault:(BOOL)isDefault {
    _isDefault = isDefault;

    // 勾选图标
    NSString *imgName = isDefault ? @"gsssss_bank_mru" : @"gsssss_bank_mrn";
    self.defaultIcon.image = [UIImage imageNamed:imgName];

    // 两张卡都有背景图
    // 默认卡: 全白文字   非默认卡: 内容灰色(#6E766B)，Default文字始终白色
    self.bgImageView.hidden = NO;
    UIColor *contentColor = isDefault ? kColorWhite : kColorTextSecondary;
    self.nameLabel.textColor = contentColor;
    self.bankNameLabel.textColor = contentColor;
    self.cardNumberLabel.textColor = contentColor;
    self.ifscLabel.textColor = contentColor;
    self.defaultLabel.textColor = kColorWhite; // 始终白色
}

#pragma mark - Actions

- (void)deleteTapped {
    if (self.deleteBlock) self.deleteBlock();
}

- (void)editTapped {
    if (self.editBlock) self.editBlock();
}

- (void)defaultTapped {
    if (self.defaultBlock) self.defaultBlock();
}

@end
