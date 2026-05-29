//
//  MKSignInCardView.m
//
//  Figma 3:1743 Sign in 主卡片 (18,103 339x512, fill #E9E9E4, radius 24)
//  所有子元素坐标 = (Figma 绝对坐标) - (18, 103) 转为相对 card.
//

#import "MKSignInCardView.h"
#import "MKConstants.h"
#import "MKPhoneValidator.h"
#import "MKOTPValidator.h"

#define S(v) ((v) * kScale)

@interface MKSignInCardView () <UITextFieldDelegate>
@property (nonatomic, strong) UIView *pillView;            // 顶部胶囊
@property (nonatomic, strong) UIImageView *shieldImage;    // 右上盾牌 SVG
@property (nonatomic, strong) UILabel *welcomeLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) UIView *mobileBg;
@property (nonatomic, strong) UITextField *mobileField;
@property (nonatomic, strong) UIView *otpBg;
@property (nonatomic, strong) UITextField *otpField;
@property (nonatomic, strong) UIButton *getOTPButton;

@property (nonatomic, strong) UIButton *checkbox;
@property (nonatomic, strong) UILabel *agreementLabel;

@property (nonatomic, strong) UIButton *signInButton;

@property (nonatomic, strong, nullable) NSTimer *countdownTimer;
@property (nonatomic, assign) NSInteger countdown;
@end

@implementation MKSignInCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Figma fill_9J5O30 #E9E9E4, radius 24
        self.backgroundColor = MKHexColor(0xE9E9E4);
        self.layer.cornerRadius = S(24);
        self.clipsToBounds = YES;
        _agreementChecked = YES;   // 默认勾选
        [self setupTop];
        [self setupInputs];
        [self setupAgreement];
        [self setupSignInButton];
    }
    return self;
}

#pragma mark - 1) Top: pill + shield + welcome + subtitle

- (void)setupTop {
    // 胶囊 "Sign in to start" — Figma (119,113,137x43) → (101,10)
    self.pillView = [[UIView alloc] initWithFrame:CGRectMake(S(101), S(10), S(137), S(43))];
    self.pillView.backgroundColor = kColorPrimaryDark;      // #252F2C
    self.pillView.layer.cornerRadius = S(21.5);
    [self addSubview:self.pillView];

    // "Sign in to start" 文字 — Figma (130,122,117x24) Body/1/Semibold (Poppins 600 16 white)
    UILabel *pillText = [[UILabel alloc] initWithFrame:self.pillView.bounds];
    pillText.text = @"Sign in to start";
    pillText.font = kFontBodySemibold;
    pillText.textColor = kColorWhite;
    pillText.textAlignment = NSTextAlignmentCenter;
    [self.pillView addSubview:pillText];

    // 盾牌 — Figma (287,169,52x52) → (269,66)
    self.shieldImage = [[UIImageView alloc] initWithFrame:CGRectMake(S(269), S(66), S(52), S(52))];
    self.shieldImage.image = [UIImage imageNamed:@"mk_signin_shield"];
    self.shieldImage.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.shieldImage];

    // "welcome！" — Figma (28,176,104x24) PingFang SC 500 20 / Neutral/1 #171718
    self.welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(S(10), S(73), S(200), S(28))];
    self.welcomeLabel.text = @"welcome！";
    self.welcomeLabel.font = kFontPingFang20M;
    self.welcomeLabel.textColor = MKHexColor(0x171718);
    [self addSubview:self.welcomeLabel];

    // "Embark on your fast loan journey" — Figma (28,204,217x24) PingFang SC 400 14 #999999
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(S(10), S(101), S(250), S(24))];
    self.subtitleLabel.text = @"Embark on your fast loan journey";
    self.subtitleLabel.font = kFontPingFang14;
    self.subtitleLabel.textColor = MKHexColor(0x999999);
    [self addSubview:self.subtitleLabel];
}

#pragma mark - 2) Inputs

- (void)setupInputs {
    // Mobile 输入框背景 — Figma (36,266,303x75) → (18,163) fill #F8F8F7 radius 14
    self.mobileBg = [[UIView alloc] initWithFrame:CGRectMake(S(18), S(163), S(303), S(75))];
    self.mobileBg.backgroundColor = MKHexColor(0xF8F8F7);
    self.mobileBg.layer.cornerRadius = S(14);
    [self addSubview:self.mobileBg];

    // "Mobile number" label — Figma (47,275,97x24) → 相对 card (29,172)
    UILabel *mLbl = [[UILabel alloc] initWithFrame:CGRectMake(S(29), S(172), S(120), S(24))];
    mLbl.text = @"Mobile number";
    mLbl.font = kFontPingFang14;
    mLbl.textColor = MKHexColor(0x999999);
    [self addSubview:mLbl];

    // "+63" 国家区号 — 固定 Label, 不属于输入框. Poppins 400 15 Neutral/1
    UILabel *prefixLbl = [[UILabel alloc] initWithFrame:CGRectMake(S(29), S(202), S(35), S(28))];
    prefixLbl.text = @"+63";
    prefixLbl.font = kFontPoppins15;
    prefixLbl.textColor = MKHexColor(0x171718);
    [self addSubview:prefixLbl];

    // 手机号输入 — 紧跟 +63 之后, placeholder "Please enter mobile number" #999999
    self.mobileField = [[UITextField alloc] initWithFrame:CGRectMake(S(72), S(202), S(237), S(28))];
    self.mobileField.font = kFontPoppins15;
    self.mobileField.textColor = MKHexColor(0x171718);
    self.mobileField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Please enter mobile number"
                                        attributes:@{NSForegroundColorAttributeName: MKHexColor(0x999999),
                                                     NSFontAttributeName: kFontPoppins15}];
    self.mobileField.keyboardType = UIKeyboardTypeNumberPad;
    self.mobileField.delegate = self;
    [self addSubview:self.mobileField];

    // OTP 输入框背景 — Figma (36,352,303x75) → (18,249)
    self.otpBg = [[UIView alloc] initWithFrame:CGRectMake(S(18), S(249), S(303), S(75))];
    self.otpBg.backgroundColor = MKHexColor(0xF8F8F7);
    self.otpBg.layer.cornerRadius = S(14);
    [self addSubview:self.otpBg];

    // "OTP" label — Figma (47,361,29x24) → (29,258)
    UILabel *oLbl = [[UILabel alloc] initWithFrame:CGRectMake(S(29), S(258), S(100), S(24))];
    oLbl.text = @"OTP";
    oLbl.font = kFontPingFang14;
    oLbl.textColor = MKHexColor(0x999999);
    [self addSubview:oLbl];

    // OTP 输入 — Figma "Enter OTP" placeholder (47,395) → 相对 card (29,292) Poppins 400 15 #999999
    self.otpField = [[UITextField alloc] initWithFrame:CGRectMake(S(29), S(292), S(200), S(20))];
    self.otpField.font = kFontPoppins15;
    self.otpField.textColor = MKHexColor(0x171718);
    self.otpField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:@"Enter OTP"
                                        attributes:@{NSForegroundColorAttributeName: MKHexColor(0x999999),
                                                     NSFontAttributeName: kFontPoppins15}];
    self.otpField.keyboardType = UIKeyboardTypeNumberPad;
    self.otpField.delegate = self;
    [self addSubview:self.otpField];

    // "Get OTP" — Figma (266,396,65x18) PingFang SC 500 16 #385330 → 卡内 (248,293), w=65
    // 右边距 = OTP框右(321) - 按钮右(248+65=313) = 8pt (匹配 Figma)
    self.getOTPButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.getOTPButton.frame = CGRectMake(S(248), S(293), S(65), S(24));
    self.getOTPButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.getOTPButton setTitle:@"Get OTP" forState:UIControlStateNormal];
    [self.getOTPButton setTitleColor:kColorPrimary forState:UIControlStateNormal];
    self.getOTPButton.titleLabel.font = kFontPingFang16M;
    [self.getOTPButton addTarget:self action:@selector(getOTPAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.getOTPButton];
}

#pragma mark - 3) Agreement

- (void)setupAgreement {
    // checkbox — Figma (36,481,16x16) → (18,378)
    self.checkbox = [UIButton buttonWithType:UIButtonTypeCustom];
    self.checkbox.frame = CGRectMake(S(18), S(378), S(16), S(16));
    [self.checkbox setImage:[UIImage imageNamed:_agreementChecked ? @"mk_check_on" : @"mk_check_off"]
                   forState:UIControlStateNormal];
    [self.checkbox addTarget:self action:@selector(toggleAgreement) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.checkbox];

    // 协议文字 — Figma (59,481,277x32) → (41,378) Poppins 400 12 Neutral/1
    // "Privacy Policy" 与 "Service Agreement" 加下划线 (Figma 富文本)
    self.agreementLabel = [[UILabel alloc] initWithFrame:CGRectMake(S(41), S(378), S(280), S(32))];
    self.agreementLabel.font = kFontPoppins12;
    self.agreementLabel.textColor = MKHexColor(0x171718);
    self.agreementLabel.numberOfLines = 0;

    NSString *full = @"I have read and accepted Privacy Policy and Service Agreement";
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:full
        attributes:@{ NSFontAttributeName: kFontPoppins12,
                      NSForegroundColorAttributeName: MKHexColor(0x171718) }];
    NSRange r1 = [full rangeOfString:@"Privacy Policy"];
    NSRange r2 = [full rangeOfString:@"Service Agreement"];
    if (r1.location != NSNotFound) {
        [att addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:r1];
    }
    if (r2.location != NSNotFound) {
        [att addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:r2];
    }
    self.agreementLabel.attributedText = att;
    [self addSubview:self.agreementLabel];
}

#pragma mark - 4) Sign in button

- (void)setupSignInButton {
    // Figma (36,535,303x56) → (18,432) fill #385330 radius 28 / Poppins 600 16 white
    self.signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signInButton.frame = CGRectMake(S(18), S(432), S(303), S(56));
    self.signInButton.backgroundColor = kColorPrimary;
    self.signInButton.layer.cornerRadius = S(28);
    // Figma 文字为 "Sign in" (首字母大写, in 小写)
    [self.signInButton setTitle:@"Sign in" forState:UIControlStateNormal];
    [self.signInButton setTitleColor:kColorWhite forState:UIControlStateNormal];
    self.signInButton.titleLabel.font = kFontButtonLarge;
    [self.signInButton addTarget:self action:@selector(signInAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.signInButton];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    if (textField == self.mobileField) {
        // 菲律宾手机号: 9开头10位 或 09开头11位
        return [MKPhoneValidator shouldChangeText:textField.text
                                          inRange:range
                                replacementString:string
                                        maxLength:11];
    }
    if (textField == self.otpField) {
        // OTP 固定 6 位
        return [MKOTPValidator shouldChangeText:textField.text
                                        inRange:range
                              replacementString:string];
    }
    return YES;
}

#pragma mark - Actions

- (void)getOTPAction { if (self.onGetOTPTapped) self.onGetOTPTapped(); }
- (void)signInAction { if (self.onSignInTapped) self.onSignInTapped(); }
- (void)toggleAgreement {
    _agreementChecked = !_agreementChecked;
    UIImage *img = [UIImage imageNamed:_agreementChecked ? @"mk_check_on" : @"mk_check_off"];
    [self.checkbox setImage:img forState:UIControlStateNormal];
    if (self.onAgreementCheckToggled) self.onAgreementCheckToggled(_agreementChecked);
}

#pragma mark - Getters

- (NSString *)mobile { return self.mobileField.text; }
- (NSString *)otp    { return self.otpField.text; }

#pragma mark - Countdown

- (void)startOTPCountdown:(NSInteger)seconds {
    [self.countdownTimer invalidate];
    self.countdown = seconds;
    self.getOTPButton.enabled = NO;
    [self.getOTPButton setTitleColor:MKHexColor(0x999999) forState:UIControlStateNormal];
    [self.getOTPButton setTitle:[NSString stringWithFormat:@"%lds", (long)self.countdown] forState:UIControlStateNormal];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self
                                                          selector:@selector(tickCountdown)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)tickCountdown {
    self.countdown--;
    if (self.countdown <= 0) {
        [self resetOTPButton];
    } else {
        [self.getOTPButton setTitle:[NSString stringWithFormat:@"%lds", (long)self.countdown] forState:UIControlStateNormal];
    }
}

- (void)resetOTPButton {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    self.countdown = 0;
    self.getOTPButton.enabled = YES;
    [self.getOTPButton setTitleColor:kColorPrimary forState:UIControlStateNormal];
    [self.getOTPButton setTitle:@"Get OTP" forState:UIControlStateNormal];
}

- (void)dealloc {
    [self.countdownTimer invalidate];
}

@end
