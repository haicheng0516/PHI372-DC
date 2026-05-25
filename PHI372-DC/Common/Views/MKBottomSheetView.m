//
//  MKBottomSheetView.m
//  PHI372-DC
//
//  中央弹窗：内容驱动高度（按实际正文行数自适应）, 容器在屏幕几何中心
//

#import "MKBottomSheetView.h"
#import "MKConstants.h"
#import "NSString+MKAmount.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define S(v) ((v) * kScale)

@interface MKBottomSheetView () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, assign) MKBottomSheetType type;
@property (nonatomic, strong, nullable) NSDictionary *config;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *dragHandle;
@property (nonatomic, assign) CGFloat cardWidth;
@property (nonatomic, assign) CGFloat contentMaxY;   // 已添加内容的最大 Y (容器内坐标)
@property (nonatomic, assign) CGFloat sheetFinalHeight;
// CommonPicker / RepaymentPlan 共用
@property (nonatomic, copy, nullable) NSArray<NSString *> *pickerItems;
@property (nonatomic, assign) NSInteger pickerSelectedRow;
// DataCapture: 进度条引用 (供 setDataCaptureProgress: 动态更新)
@property (nonatomic, strong, nullable) UIView *dcTrackBar;
@property (nonatomic, strong, nullable) UIView *dcFillBar;
@property (nonatomic, strong, nullable) UILabel *dcPercentLabel;
// 私有按钮构建方法
typedef NS_ENUM(NSInteger, MKSheetCancelFillStyle) {
    MKSheetCancelFillGray  = 0,   // #E9E9E4 (多数 sheet 默认)
    MKSheetCancelFillWhite = 1,   // #FFFFFF (Reloan 类 sheet)
};
/// 照 Pencil: 左小 Cancel (90×56 cr=28) + 右大 Confirm (170×56 cr=28 #385330) gap=11 居中起点 52
- (CGFloat)addDoubleButtonsCancelLeftConfirmRightAtY:(CGFloat)y
                                         confirmTitle:(NSString *)confirmTitle
                                          cancelTitle:(NSString *)cancelTitle
                                           cancelFill:(MKSheetCancelFillStyle)cancelFill;
- (CGFloat)addSingleButtonUpgrade:(NSString *)title atY:(CGFloat)y;
- (CGFloat)addDoubleButtonsUpgrade:(NSString *)confirm cancel:(NSString *)cancel atY:(CGFloat)y;
@end

@implementation MKBottomSheetView

#pragma mark - 工厂

+ (instancetype)sheetWithType:(MKBottomSheetType)type config:(NSDictionary *)config {
    return [[self alloc] initWithType:type config:config];
}

- (instancetype)initWithType:(MKBottomSheetType)type config:(NSDictionary *)config {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        _type = type;
        _config = config;
        _cardWidth = kScreenWidth - S(44);  // Pencil: 左右各 22pt 边距, 卡片宽331@375
        _contentMaxY = S(8);                 // 顶部留 8 (无 drag handle)
        // 强更 / 数据抓取 / 申请成功: 禁止 dim 关闭 (必须点对应按钮 或 API 关闭)
        BOOL noDim = (type == MKBottomSheetTypeForceUpdate
                       || type == MKBottomSheetTypeDataCapture
                       || type == MKBottomSheetTypeApplySuccess);
        _dismissibleByDim = !noDim;
        [self setupDim];
        [self setupContainerInitial];
        [self addDragHandle];
        [self buildContentForType:type];
        [self finalizeContainerLayout];
    }
    return self;
}

#pragma mark - 兼容: 类方法 heightForType (不再驱动布局, 仅作启发值)

+ (CGFloat)heightForType:(MKBottomSheetType)type { return 320; }

#pragma mark - 容器

- (void)setupDim {
    self.dimView = [[UIView alloc] initWithFrame:self.bounds];
    self.dimView.backgroundColor = MKColorAlpha(0, 0, 0, 0.5);
    self.dimView.alpha = 0;
    self.dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.dimView];

    if (self.dismissibleByDim) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [self.dimView addGestureRecognizer:tap];
    }
}

- (void)setupContainerInitial {
    // 先用占位高度创建容器, finalize 时按内容修正 frame
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cardWidth, 320)];
    self.containerView.backgroundColor = MKHexColor(0xF8F8F7);
    // 浮起卡片: 四角全圆
    self.containerView.layer.cornerRadius = S(24);
    self.containerView.layer.masksToBounds = YES;
    self.containerView.alpha = 0;
    [self addSubview:self.containerView];
}

- (void)addDragHandle {
    // 浮起卡片不再需要 drag handle (Figma 3:1654 等均无)
}

- (void)finalizeContainerLayout {
    // 浮起卡片高度 = 内容高 + 底部 16 padding (safe area 由 anchorContainerToBottom 处理)
    CGFloat sheetH = self.contentMaxY + S(16);
    self.sheetFinalHeight = sheetH;
    CGRect f = self.containerView.bounds;
    f.size.width = self.cardWidth;
    f.size.height = sheetH;
    self.containerView.bounds = f;
    [self anchorContainerToBottom];
    // gradient 子层跟着 bounds 走
    for (CALayer *l in self.containerView.layer.sublayers) {
        if ([l isKindOfClass:CAGradientLayer.class]) { l.frame = self.containerView.bounds; }
    }
}

- (void)anchorContainerToBottom {
    // 浮起卡片: 水平居中 + 底部留 16pt 间距(safe area 之上)
    CGSize host = self.bounds.size.width > 0 ? self.bounds.size : [UIScreen mainScreen].bounds.size;
    CGSize sz = self.containerView.bounds.size;
    CGFloat bottomSafe = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *w = nil;
        for (UIWindowScene *s in UIApplication.sharedApplication.connectedScenes) {
            for (UIWindow *win in s.windows) { if (win.isKeyWindow) { w = win; break; } }
            if (w) break;
        }
        bottomSafe = w.safeAreaInsets.bottom;
    }
    CGFloat x = (host.width - sz.width) * 0.5;
    CGFloat y = host.height - sz.height - bottomSafe - S(16);
    self.containerView.frame = CGRectMake(x, y, sz.width, sz.height);
}

#pragma mark - Container 宽度访问器

- (CGFloat)containerWidth { return self.cardWidth; }

#pragma mark - 内容构建分发

- (void)buildContentForType:(MKBottomSheetType)type {
    switch (type) {
        case MKBottomSheetTypeForceUpdate:
            [self buildUpgrade:YES version:@"V1.0.1" subtitle:@"New version found"]; break;
        case MKBottomSheetTypeNormalUpdate:
            [self buildUpgrade:NO  version:@"V1.0.1" subtitle:@"New version found"]; break;

        case MKBottomSheetTypeLogoutConfirm:
            [self buildConfirmWithHintIcon:@"Sign Out"
                                       body:@"Are you sure to sign out your account?"
                                    confirm:@"Confirm" cancel:@"Cancel"]; break;
        case MKBottomSheetTypeAccountDelete:
            // Pencil Jt7av body NOT FOUND → left
            [self buildConfirmWithHintIcon:@"Delete Account"
                                       body:@"Once you delete your account, this action cannot be undone. All your data, loans and history will be permanently removed. Are you sure you want to proceed?"
                                    confirm:@"Confirm" cancel:@"Cancel"
                                  bodyAlign:NSTextAlignmentLeft]; break;
        case MKBottomSheetTypeBackConfirm:
            [self buildConfirmWithHintIcon:nil
                                       body:@"It's a pity to leave. The information you filled in will not be saved. Are you sure you want to leave?"
                                    confirm:@"Confirm" cancel:@"Cancel"]; break;
        case MKBottomSheetTypeExistingOrder:
            // Pencil Q2Ta4l body NOT FOUND → left
            [self buildConfirmWithHintIcon:nil
                                       body:@"You have an ongoing order. Please complete it before applying for a new one."
                                    confirm:@"Know More" cancel:@"Back"
                                  bodyAlign:NSTextAlignmentLeft]; break;
        case MKBottomSheetTypeRatingGuide:
            [self buildRatingGuide]; break;
        case MKBottomSheetTypePermissionCamera:
            [self buildPermission:@"camera"  body:@"We need camera access to take ID photos for verification. Tap Confirm and allow access in Settings."]; break;
        case MKBottomSheetTypePermissionLocation:
            [self buildPermission:@"location.fill"  body:@"We use your location to enhance fraud prevention. Tap Confirm and allow access in Settings."]; break;
        case MKBottomSheetTypePermissionContacts:
            [self buildPermission:@"person.2.fill" body:@"We need contacts access for emergency contact verification. Tap Confirm and allow access in Settings."]; break;

        case MKBottomSheetTypeDataCapture:
            [self buildDataCapture]; break;
        case MKBottomSheetTypeApplySuccess:
            // Pencil Q5IzQ: title "Success!" body "Your application is under review..."
            [self buildResult:YES
                        title:@"Success!"
                         body:@"Your application is under review. Once approved, the money will be credited to your bank account."
                      confirm:@"Confirm"]; break;

        case MKBottomSheetTypeAccountDeleteSuccess:
            // Pencil: "Account canceled successfully" body, title "Success!"
            [self buildResult:YES title:@"Success!" body:@"Account canceled successfully" confirm:@"Confirm"]; break;
        case MKBottomSheetTypeAccountDeleteFail:
            // Pencil: "Account cancellation failed, please check your order"
            [self buildResult:NO  title:@"Failed!"  body:@"Account cancellation failed, please check your order" confirm:@"Confirm"]; break;
        case MKBottomSheetTypeRatingSuccess:
            // Pencil: 好评成功 title "Success!" body as below
            [self buildResult:YES title:@"Success!" body:@"We sincerely thank you for your feedback! We will carefully consider your suggestions to continuously improve." confirm:@"Confirm"]; break;
        case MKBottomSheetTypeWithdrawPending:
            // Pencil UdvaD body NOT FOUND → left
            [self buildConfirmWithHintIcon:@"To be withdrawn"
                                       body:@"You have an order pending withdrawal. After entering the page to confirm, the funds will be transferred to your bank account immediately."
                                    confirm:@"Withdraw" cancel:@"Cancel"
                                  bodyAlign:NSTextAlignmentLeft]; break;
        case MKBottomSheetTypeWithdrawSuccess:
            // Pencil sGmVb body NOT FOUND → left
            [self buildResult:YES title:@"Success!" body:@"Withdrawal is successful, the funds will be transferred to your bank account, please check" confirm:@"Confirm" bodyAlign:NSTextAlignmentLeft]; break;

        case MKBottomSheetTypeHomeReloan:
            [self buildReloan:@"Congratulations! The order has been closed. Apply for a new loan, win a lower rate, faster approval, and exclusive benefits!"]; break;
        case MKBottomSheetTypeProductReloan:
            [self buildReloan:@"Make every opportunity become reality! The products you applied for are now open again. Don't miss out on this exclusive offer."]; break;
        case MKBottomSheetTypeOrderReloan:
            [self buildReloan:@"The opportunity is here again! Re-borrow immediately and let the possibilities continue. Lower rates and faster approval await."]; break;

        case MKBottomSheetTypeKYCFail:
            [self buildKYCFail]; break;

        case MKBottomSheetTypeRepaymentPlan:
            [self buildRepaymentPlan]; break;
        case MKBottomSheetTypeBankCardSelect: {
            // 滚轮 picker + 自定义右按钮文案 "+ Please Add A Receiving Account"
            NSArray *items = [self.config[@"items"] isKindOfClass:[NSArray class]] ? self.config[@"items"] : @[];
            NSString *addNewText = [self.config[@"addNewTitle"] isKindOfClass:[NSString class]]
                ? self.config[@"addNewTitle"] : @"+ Please Add A Receiving Account";
            [self buildBankCardPicker:items addNewTitle:addNewText]; break;
        }
        case MKBottomSheetTypeCommonPicker: {
            NSString *title = self.config[@"title"] ?: @"Select";
            NSArray *items = self.config[@"items"] ?: @[@"Option 1", @"Option 2", @"Option 3"];
            [self buildPicker:title items:items]; break;
        }
    }
}

#pragma mark - 单按钮 Result

- (void)buildResult:(BOOL)success title:(NSString *)title body:(NSString *)body confirm:(NSString *)c {
    [self buildResult:success title:title body:body confirm:c bodyAlign:NSTextAlignmentCenter];
}

- (void)buildResult:(BOOL)success title:(NSString *)title body:(NSString *)body confirm:(NSString *)c bodyAlign:(NSTextAlignment)bodyAlign {
    CGFloat W = self.cardWidth;
    // Pencil: Se_success/Se_fail 图片占位 68x60, 居中
    CGFloat y = S(28);

    UIView *resultIcon = [[UIView alloc] initWithFrame:CGRectMake((W - S(60)) * 0.5, y, S(60), S(52))];
    resultIcon.backgroundColor = success ? kColorPrimary : kColorError;
    resultIcon.layer.cornerRadius = S(8);
    [self.containerView addSubview:resultIcon];
    y = CGRectGetMaxY(resultIcon.frame) + S(12);

    // Pencil: title PingFang SC 20pt/400 #171718, 居中
    UILabel *titleLbl = [UILabel new];
    titleLbl.text = title;
    titleLbl.font = [UIFont systemFontOfSize:S(20) weight:UIFontWeightRegular];
    titleLbl.textColor = MKHexColor(0x171718);
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.numberOfLines = 0;
    CGSize fit = [titleLbl sizeThatFits:CGSizeMake(W - S(36), CGFLOAT_MAX)];
    titleLbl.frame = CGRectMake(S(18), y, W - S(36), ceil(fit.height));
    [self.containerView addSubview:titleLbl];
    y = CGRectGetMaxY(titleLbl.frame) + S(8);

    y = [self addBody:body atY:y align:bodyAlign];
    y += S(20);
    // Pencil: 单按钮 279pt, cornerRadius=80, fill=#385330, 高度56
    y = [self addSingleButton:c atY:y];

    self.contentMaxY = y;
}

#pragma mark - 双按钮 Confirm-with-Hint-Icon

- (void)buildConfirmWithHintIcon:(NSString *)title body:(NSString *)body confirm:(NSString *)c cancel:(NSString *)cancel {
    [self buildConfirmWithHintIcon:title body:body confirm:c cancel:cancel bodyAlign:NSTextAlignmentCenter];
}

- (void)buildConfirmWithHintIcon:(NSString *)title body:(NSString *)body confirm:(NSString *)c cancel:(NSString *)cancel bodyAlign:(NSTextAlignment)bodyAlign {
    CGFloat W = self.cardWidth;
    // Pencil: Se_hint 图片占位 68x60, 居中
    CGFloat y = S(28);

    UIView *hintIcon = [[UIView alloc] initWithFrame:CGRectMake((W - S(60)) * 0.5, y, S(60), S(52))];
    hintIcon.backgroundColor = MKHexColor(0xEB8A54);
    hintIcon.layer.cornerRadius = S(8);
    [self.containerView addSubview:hintIcon];
    y = CGRectGetMaxY(hintIcon.frame) + S(12);

    if (title.length) {
        // Pencil: title PingFang SC 20pt/400 #16171d, 居中
        UILabel *titleLbl = [UILabel new];
        titleLbl.text = title;
        titleLbl.font = [UIFont systemFontOfSize:S(20) weight:UIFontWeightRegular];
        titleLbl.textColor = MKHexColor(0x16171D);
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.numberOfLines = 0;
        CGSize fit = [titleLbl sizeThatFits:CGSizeMake(W - S(36), CGFLOAT_MAX)];
        titleLbl.frame = CGRectMake(S(18), y, W - S(36), ceil(fit.height));
        [self.containerView addSubview:titleLbl];
        y = CGRectGetMaxY(titleLbl.frame) + S(10);
    }
    y = [self addBody:body atY:y align:bodyAlign];
    y += S(24);
    // Pencil: 左 Cancel(小,90pt,#e9e9e4,text=#385330) 右 Confirm(大,170pt,#385330,white)
    y = [self addDoubleButtonsCancelLeftConfirmRightAtY:y confirmTitle:c cancelTitle:cancel cancelFill:MKSheetCancelFillGray];

    self.contentMaxY = y;
}

#pragma mark - Upgrade

- (void)buildUpgrade:(BOOL)force version:(NSString *)version subtitle:(NSString *)subtitle {
    // Pencil 版本更新: 卡片宽 331, 高 282, cornerRadius=28, 渐变 #d7ffcb→#e9e9e4
    // 布局: Se_Upgrade 绿箭头图 (image-import-38.png, mk_upgrade) 187×187 at (-12, 128) 卡内
    //       含 rotation=180+flipX → 视觉上等价 flipY (上下镜像), 部分溢出卡片左/底
    //       文字栈右对齐: Upgrade 32/700, V1.0.1 14, "New version found" 14/#666
    //       Buttons y=194: force=单按钮 279; normal=Cancel(90,白) + Upgrade(170,绿), sidePad=30, gap=11
    CGFloat W = self.cardWidth;
    CGFloat cardH = S(282);
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.clipsToBounds = NO;

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, W, cardH);
    gradient.colors = @[ (id)MKHexColor(0xD7FFCB).CGColor, (id)MKHexColor(0xE9E9E4).CGColor ];
    gradient.startPoint = CGPointMake(0.5, 0);
    gradient.endPoint = CGPointMake(0.5, 1);
    gradient.cornerRadius = S(28);
    [self.containerView.layer insertSublayer:gradient atIndex:0];

    // Se_Upgrade 图 — Pencil snapshot_layout: 187×187 at sheet (10, 415) → 卡内 (-12, -59)
    // 图片上方 59pt 在弹窗外, 箭头 tip 在弹窗顶部外面向上指, body 弯进卡片左上
    // 注: 导出的切图已包含 Pencil rotation+flipX 的最终视觉(箭头向上), 不需要额外 transform
    // containerView.clipsToBounds=NO → 允许图片溢出卡片边界
    UIImageView *arrow = [[UIImageView alloc] initWithFrame:CGRectMake(S(-12), S(-59), S(187), S(187))];
    arrow.image = [UIImage imageNamed:@"mk_upgrade"];
    arrow.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:arrow];

    CGFloat textRightInset = S(20);

    // "Upgrade" — Pencil: Phetsarath 32pt/700 #171718, right, y=39
    UILabel *title = [[UILabel alloc] init];
    title.text = @"Upgrade";
    title.font = [UIFont systemFontOfSize:S(32) weight:UIFontWeightBold];
    title.textColor = MKHexColor(0x171718);
    title.textAlignment = NSTextAlignmentRight;
    title.frame = CGRectMake(0, S(36), W - textRightInset, S(40));
    [self.containerView addSubview:title];

    // Version — Pencil y=77, Poppins 14/400, right
    UILabel *ver = [[UILabel alloc] init];
    ver.text = version;
    ver.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    ver.textColor = MKHexColor(0x171718);
    ver.textAlignment = NSTextAlignmentRight;
    ver.frame = CGRectMake(0, S(78), W - textRightInset, S(20));
    [self.containerView addSubview:ver];

    // Subtitle — Pencil y=105, PingFang SC 14/400 #666, right
    UILabel *sub = [[UILabel alloc] init];
    sub.text = subtitle;
    sub.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    sub.textColor = MKHexColor(0x666666);
    sub.textAlignment = NSTextAlignmentRight;
    sub.frame = CGRectMake(0, S(102), W - textRightInset, S(20));
    [self.containerView addSubview:sub];

    // Buttons — Pencil y=194 (相对卡内)
    CGFloat btnY = S(194);
    if (force) {
        btnY = [self addSingleButtonUpgrade:@"Upgrade" atY:btnY];
    } else {
        btnY = [self addDoubleButtonsUpgrade:@"Upgrade" cancel:@"Cancel" atY:btnY];
    }
    // 强制 container 高度 = Pencil 卡片高 282 (按 anchor 公式 = contentMaxY + 20 → contentMaxY=262)
    self.contentMaxY = cardH - S(20);
}

#pragma mark - Reloan

- (void)buildReloan:(NSString *)body {
    CGFloat W = self.cardWidth;
    self.containerView.backgroundColor = [UIColor clearColor];
    // Pencil n7NuBf base: 高 304, gradient #d7ffcb→#e9e9e4 cornerRadius=28
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, W, S(304));
    gradient.colors = @[ (id)MKHexColor(0xD7FFCB).CGColor, (id)MKHexColor(0xE9E9E4).CGColor ];
    gradient.startPoint = CGPointMake(0.5, 0);
    gradient.endPoint = CGPointMake(0.5, 1);
    gradient.cornerRadius = S(28);
    [self.containerView.layer insertSublayer:gradient atIndex:0];

    // config 支持: productName / productAmount / productLogoURL
    // 二次格式化兜底 (259 SCTipsAlertView 同款): caller 即便给了 "50000" 也能渲染成 "₱ 50,000"
    NSString *amountText = @"₱ 50,000";
    if ([self.config[@"productAmount"] isKindOfClass:[NSString class]]) {
        NSString *raw = self.config[@"productAmount"];
        if (raw.length > 0) {
            amountText = [raw hasPrefix:@"₱"] ? raw : [raw mk_formattedPesoAmount];
        }
    }
    NSString *nameText = [self.config[@"productName"] isKindOfClass:[NSString class]] && [(NSString *)self.config[@"productName"] length] > 0
        ? self.config[@"productName"] : @"Quick Cash";
    NSString *logoURL = [self.config[@"productLogoURL"] isKindOfClass:[NSString class]] ? self.config[@"productLogoURL"] : nil;

    // Pencil yj48R: 金额文字 Inter/28/600 #385330 textAlign:center
    // 位置(相对 frame): x=53 y=482 → 相对 cardWidth (31, 30)
    UILabel *amount = [[UILabel alloc] initWithFrame:CGRectMake(S(31), S(30), S(180), S(36))];
    amount.text = amountText;
    amount.font = [UIFont systemFontOfSize:S(28) weight:UIFontWeightSemibold];
    amount.textColor = kColorPrimary;
    amount.textAlignment = NSTextAlignmentLeft;  // 金额左对齐(label 自身 frame 已限定区域)
    [self.containerView addSubview:amount];

    // Pencil iQUO8: 右上角固定钱袋切图 image-import-30.png (mk_money_bag), 76×68, 相对 cardWidth (225, 30)
    UIImageView *money = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mk_money_bag"]];
    money.contentMode = UIViewContentModeScaleAspectFit;
    money.frame = CGRectMake(S(225), S(30), S(76), S(68));
    money.clipsToBounds = YES;
    [self.containerView addSubview:money];

    // Pencil kOPoy: 产品 logo 色块 28×28 cornerRadius=9, 相对 cardWidth (31, 83)
    // 色块固定主色 #385330(Pencil 死值), URL 图标走 SDWebImage 加载到一个内嵌 imageView,
    // aspectFit + 内嵌缩进 → 始终能看到主色背景, 避免图片把色块完全覆盖.
    UIView *prodLogoBg = [[UIView alloc] initWithFrame:CGRectMake(S(31), S(83), S(28), S(28))];
    prodLogoBg.backgroundColor = kColorPrimary;
    prodLogoBg.layer.cornerRadius = S(9);
    prodLogoBg.clipsToBounds = YES;
    [self.containerView addSubview:prodLogoBg];

    UIImageView *prodLogoIcon = [[UIImageView alloc] initWithFrame:CGRectInset(prodLogoBg.bounds, S(4), S(4))];
    prodLogoIcon.contentMode = UIViewContentModeScaleAspectFit;
    [prodLogoBg addSubview:prodLogoIcon];
    if (logoURL.length > 0) {
        [prodLogoIcon sd_setImageWithURL:[NSURL URLWithString:logoURL]];
    }

    // Pencil pK9Db: 产品名 Poppins/14 #385330 left, 相对 frame (89, 538) → 相对 cardWidth (67, 86)
    UILabel *tag = [[UILabel alloc] initWithFrame:CGRectMake(S(67), S(86), W - S(80), S(22))];
    tag.text = nameText;
    tag.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    tag.textColor = kColorPrimary;
    tag.textAlignment = NSTextAlignmentLeft;
    [self.containerView addSubview:tag];

    // Pencil K1jQ1: body PingFang/14 #666666 left, 相对 frame (52, 577) w=280 → 相对 cardWidth (30, 125, 280)
    UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(S(30), S(125), S(280), 0)];
    bodyLabel.text = body;
    bodyLabel.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    bodyLabel.textColor = MKHexColor(0x666666);
    bodyLabel.textAlignment = NSTextAlignmentLeft;
    bodyLabel.numberOfLines = 0;
    CGSize bodyFit = [bodyLabel sizeThatFits:CGSizeMake(S(280), CGFLOAT_MAX)];
    CGRect bodyFrame = bodyLabel.frame;
    bodyFrame.size.height = ceil(bodyFit.height);
    bodyLabel.frame = bodyFrame;
    [self.containerView addSubview:bodyLabel];

    // 按钮 Pencil: y=668 (相对 frame), base y=452 → 相对 cardWidth y=668-452=216
    CGFloat y = S(216);
    y = [self addDoubleButtonsCancelLeftConfirmRightAtY:y confirmTitle:@"Apply Now" cancelTitle:@"Cancel" cancelFill:MKSheetCancelFillWhite];
    self.contentMaxY = y;
}

#pragma mark - Rating Guide

- (void)buildRatingGuide {
    CGFloat W = self.cardWidth;
    CGFloat y = S(32);
    CGFloat starSize = S(32);
    CGFloat starGap = S(10);
    CGFloat starsTotalW = starSize * 5 + starGap * 4;
    CGFloat startX = (W - starsTotalW) * 0.5;
    for (NSInteger i = 0; i < 5; i++) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightRegular];
        UIImageView *star = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"star.fill" withConfiguration:cfg]
                                                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        star.tintColor = MKHexColor(0xF4C15F);
        star.frame = CGRectMake(startX + i * (starSize + starGap), y, starSize, starSize);
        [self.containerView addSubview:star];
    }
    y += starSize + S(20);

    // Pencil cKdsE 段落 left
    y = [self addBody:@"We value the feedback of every user. Please share your thoughts and suggestions with us by rating our app to help us better understand your needs and expectations." atY:y align:NSTextAlignmentLeft];
    y += S(24);
    // Pencil RatingGuide: Cancel(灰 90pt 左) + Submit(170pt 右, 主色)
    y = [self addDoubleButtonsCancelLeftConfirmRightAtY:y confirmTitle:@"Submit" cancelTitle:@"Cancel" cancelFill:MKSheetCancelFillGray];
    self.contentMaxY = y;
}

#pragma mark - Permission

- (void)buildPermission:(NSString *)symbol body:(NSString *)body {
    CGFloat W = self.cardWidth;
    // Pencil: Se_camera/Se_locate/Se_contacts 图片 68x60, 渐变占位
    CGFloat y = S(28);

    UIView *permIcon = [[UIView alloc] initWithFrame:CGRectMake((W - S(60)) * 0.5, y, S(60), S(52))];
    permIcon.backgroundColor = MKHexColor(0x20BCDB);
    permIcon.layer.cornerRadius = S(8);
    [self.containerView addSubview:permIcon];
    y = CGRectGetMaxY(permIcon.frame) + S(16);

    // Pencil 三个权限 sheet: body 都 left (NOT FOUND)
    y = [self addBody:body atY:y align:NSTextAlignmentLeft];
    y += S(24);
    // Pencil Permission: Cancel(灰 90pt 左) + Confirm(170pt 右, 主色)
    y = [self addDoubleButtonsCancelLeftConfirmRightAtY:y confirmTitle:@"Confirm" cancelTitle:@"Cancel" cancelFill:MKSheetCancelFillGray];
    self.contentMaxY = y;
}

#pragma mark - Data Capture (Pencil opiuJ)

- (void)buildDataCapture {
    // Pencil opiuJ: 卡片 331×315 (xd7UO). 内部坐标 = pencil_y - 441
    CGFloat W = self.cardWidth;
    CGFloat y = S(19);   // Pencil title y=460 → 19

    // Title "Under review" PingFang SC 20pt #000 center
    UILabel *title = [UILabel new];
    title.text = @"Under review";
    title.font = [UIFont systemFontOfSize:S(20) weight:UIFontWeightRegular];
    title.textColor = MKHexColor(0x000000);
    title.textAlignment = NSTextAlignmentCenter;
    title.frame = CGRectMake(0, y, W, S(28));
    [self.containerView addSubview:title];
    y = CGRectGetMaxY(title.frame) + S(13);   // Pencil body y=506 → 65 → gap=18

    // Body 14pt #666 居中
    UILabel *body = [UILabel new];
    body.text = @"Your credit score is being updated, please don't exit. It'll only take a few seconds.";
    body.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    body.textColor = MKHexColor(0x666666);
    body.textAlignment = NSTextAlignmentCenter;
    body.numberOfLines = 0;
    CGSize fit = [body sizeThatFits:CGSizeMake(W - S(48), CGFLOAT_MAX)];
    body.frame = CGRectMake(S(24), y, W - S(48), ceil(fit.height));
    [self.containerView addSubview:body];
    y = CGRectGetMaxY(body.frame) + S(15);   // Pencil progress container y=569 → 128

    // Progress container 291×90 r14 #e9e9e4
    UIView *prog = [[UIView alloc] initWithFrame:CGRectMake(S(20), y, W - S(40), S(90))];
    prog.backgroundColor = MKHexColor(0xE9E9E4);
    prog.layer.cornerRadius = S(14);
    [self.containerView addSubview:prog];

    // 百分比 label "0%" Poppins 14 #171718, Pencil at (239, 574) → container (219, 5)
    self.dcPercentLabel = [UILabel new];
    self.dcPercentLabel.text = @"0%";
    self.dcPercentLabel.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    self.dcPercentLabel.textColor = MKHexColor(0x171718);
    self.dcPercentLabel.textAlignment = NSTextAlignmentCenter;
    self.dcPercentLabel.frame = CGRectMake(prog.bounds.size.width - S(60) - S(10), S(5), S(60), S(21));
    [prog addSubview:self.dcPercentLabel];

    // Track bar 267×7 r3.5 #c8c8be, Pencil (53, 601) → container (11, 32)
    self.dcTrackBar = [[UIView alloc] initWithFrame:CGRectMake(S(11), S(32), prog.bounds.size.width - S(22), S(7))];
    self.dcTrackBar.backgroundColor = MKHexColor(0xC8C8BE);
    self.dcTrackBar.layer.cornerRadius = S(3.5);
    [prog addSubview:self.dcTrackBar];

    // Fill bar 0→track.w, fill #385330 (主色), 初始 0
    self.dcFillBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, S(7))];
    self.dcFillBar.backgroundColor = kColorPrimary;
    self.dcFillBar.layer.cornerRadius = S(3.5);
    [self.dcTrackBar addSubview:self.dcFillBar];

    // checkpoint divider ticks 17×4 #eae9e9 at (108, 635) and (226, 635), 居中 progress bar 内
    // Pencil: divider y=635, 即 progress bar 上面 y=601-632 之间, 中线 y=601+3.5=604.5 → divider y=635 似乎在 bar 下方
    // 这是 step 标签上方的小分隔点, 我们简化: 不渲染 (Pencil 设计微调装饰), 重点是 bar + 步骤标签

    // Step labels Poppins 14 #565656: Apply / Reviewed / Received, Pencil y=627 → container y=58
    NSArray *steps = @[ @"Apply", @"Reviewed", @"Received" ];
    NSArray *xs = @[ @(S(11)), @(S(99)), @(prog.bounds.size.width - S(11) - S(80)) ];
    NSArray *widths = @[ @(S(60)), @(S(80)), @(S(80)) ];
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *step = [UILabel new];
        step.text = steps[i];
        step.font = [UIFont systemFontOfSize:S(12) weight:UIFontWeightRegular];
        step.textColor = MKHexColor(0x565656);
        step.textAlignment = i == 0 ? NSTextAlignmentLeft : (i == 1 ? NSTextAlignmentCenter : NSTextAlignmentRight);
        step.frame = CGRectMake([xs[i] floatValue], S(58), [widths[i] floatValue], S(21));
        [prog addSubview:step];
    }

    y = CGRectGetMaxY(prog.frame) + S(28);

    // 底部说明 14pt #666 center
    UILabel *note = [UILabel new];
    note.text = @"You're only one step away from receiving your funds, please keep this page open.";
    note.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    note.textColor = MKHexColor(0x666666);
    note.textAlignment = NSTextAlignmentCenter;
    note.numberOfLines = 0;
    CGSize nf = [note sizeThatFits:CGSizeMake(W - S(48), CGFLOAT_MAX)];
    note.frame = CGRectMake(S(24), y, W - S(48), ceil(nf.height));
    [self.containerView addSubview:note];
    y = CGRectGetMaxY(note.frame);

    // dim 不可关闭 (任务进行中)
    self.dismissibleByDim = NO;

    self.contentMaxY = y;
}

- (void)setDataCaptureProgress:(NSInteger)progress animated:(BOOL)animated {
    if (!self.dcTrackBar || !self.dcFillBar || !self.dcPercentLabel) return;
    progress = MAX(0, MIN(100, progress));
    CGFloat trackW = self.dcTrackBar.bounds.size.width;
    if (trackW <= 0) trackW = self.dcTrackBar.frame.size.width;
    CGFloat fillW = trackW * (progress / 100.0);
    self.dcPercentLabel.text = [NSString stringWithFormat:@"%ld%%", (long)progress];
    void (^block)(void) = ^{
        CGRect f = self.dcFillBar.frame;
        f.size.width = fillW;
        self.dcFillBar.frame = f;
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:block];
    } else {
        block();
    }
}

#pragma mark - KYC Fail

- (void)buildKYCFail {
    CGFloat W = self.cardWidth;
    // Pencil: KYC卡片背景 #eceff3
    self.containerView.backgroundColor = MKHexColor(0xECEFF3);

    CGFloat y = S(24);

    // Pencil: title Poppins 14pt/600 #171718, 两行居中
    UILabel *title = [UILabel new];
    title.text = @"Verification failed. Please upload the photo again.";
    title.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightSemibold];
    title.textColor = MKHexColor(0x171718);
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 0;
    CGSize tFit = [title sizeThatFits:CGSizeMake(W - S(48), CGFLOAT_MAX)];
    title.frame = CGRectMake(S(24), y, W - S(48), ceil(tFit.height));
    [self.containerView addSubview:title];
    y = CGRectGetMaxY(title.frame) + S(20);

    // Pencil: 3 张 ID 示例图片区域 (2列 + 1列全宽), 纯色矩形占位
    // 第一行: 两张小图 128x119 (左) + 122x119 (右)
    // Pencil Group333: img1(x=0,w=128) ← red ✗ "The ID photo is too small."
    //                  img2(x=137,w=122) ← red ✗ "The ID is partially covered."
    UIView *img1 = [[UIView alloc] initWithFrame:CGRectMake(S(20), y, S(128), S(119))];
    img1.backgroundColor = MKHexColor(0xE9E9E4);
    img1.layer.cornerRadius = S(14);
    [self.containerView addSubview:img1];

    UIView *img2 = [[UIView alloc] initWithFrame:CGRectMake(S(20) + S(128) + S(14), y, W - S(20) - S(128) - S(14) - S(20), S(119))];
    img2.backgroundColor = MKHexColor(0xE9E9E4);
    img2.layer.cornerRadius = S(14);
    [self.containerView addSubview:img2];

    // 状态圆点: img1 → 红 ✗ (o4B87O x=54,y=107), img2 → 红 ✗ (uTghg x=188,y=107)
    UIView *dotFail1 = [[UIView alloc] initWithFrame:CGRectMake(S(20) + S(54), y + S(100), S(20), S(20))];
    dotFail1.backgroundColor = MKHexColor(0xDD2B2B);
    dotFail1.layer.cornerRadius = S(10);
    [self.containerView addSubview:dotFail1];

    UIView *dotFail2 = [[UIView alloc] initWithFrame:CGRectMake(S(20) + S(128) + S(14) + S(50), y + S(100), S(20), S(20))];
    dotFail2.backgroundColor = MKHexColor(0xDD2B2B);
    dotFail2.layer.cornerRadius = S(10);
    [self.containerView addSubview:dotFail2];

    y += S(119) + S(8);

    // 底部文字标签
    CGFloat col2X = S(20) + S(128) + S(14);
    NSArray *captions = @[ @"The ID photo is too small.", @"The ID is\npartially covered." ];
    NSArray *captionXs = @[ @(S(20)), @(col2X) ];
    NSArray *captionWs = @[ @(S(128)), @(W - col2X - S(20)) ];
    for (NSInteger i = 0; i < 2; i++) {
        UILabel *cap = [UILabel new];
        cap.text = captions[i];
        cap.font = [UIFont systemFontOfSize:S(12) weight:UIFontWeightRegular];
        cap.textColor = MKHexColor(0x999999);
        cap.textAlignment = NSTextAlignmentCenter;
        cap.numberOfLines = 2;
        cap.frame = CGRectMake([captionXs[i] floatValue], y, [captionWs[i] floatValue], S(32));
        [self.containerView addSubview:cap];
    }
    y += S(32) + S(12);

    // 第二行: 全宽大图 259x195 ← green ✓ "Clear and unobstructed" (Pencil: Wn9sx x=120,y=321)
    UIView *img3 = [[UIView alloc] initWithFrame:CGRectMake(S(20), y, W - S(40), S(195))];
    img3.backgroundColor = MKHexColor(0xE9E9E4);
    img3.layer.cornerRadius = S(14);
    [self.containerView addSubview:img3];

    // 绿色 ✓ badge — Pencil x=120 relative to group (group offset x=56 in card)
    UIView *dotOk = [[UIView alloc] initWithFrame:CGRectMake(S(20) + S(120), y + S(175), S(20), S(20))];
    dotOk.backgroundColor = kColorPrimary;
    dotOk.layer.cornerRadius = S(10);
    [self.containerView addSubview:dotOk];

    y += S(195) + S(8);

    UILabel *cap3 = [UILabel new];
    cap3.text = @"Clear and unobstructed";
    cap3.font = [UIFont systemFontOfSize:S(13) weight:UIFontWeightRegular];
    cap3.textColor = MKHexColor(0x999999);
    cap3.textAlignment = NSTextAlignmentCenter;
    cap3.frame = CGRectMake(S(20), y, W - S(40), S(18));
    [self.containerView addSubview:cap3];
    y += S(18) + S(16);

    // Pencil: 单按钮 "Upload Again" 279pt, cornerRadius=43, fill=#385330
    y = [self addSingleButton:@"Upload Again" atY:y];
    self.contentMaxY = y;
}

#pragma mark - Picker

- (void)buildPicker:(NSString *)title items:(NSArray<NSString *> *)items {
    self.pickerItems = items ?: @[];
    NSInteger sel = [self.config[@"selectedIndex"] integerValue];
    if (sel < 0 || sel >= (NSInteger)self.pickerItems.count) sel = 0;
    self.pickerSelectedRow = sel;

    CGFloat W = self.cardWidth;
    CGFloat y = S(28);                  // 顶部留 28pt 给 title 呼吸
    // Pencil 精确: Poppins 20pt 400, color #000000
    UILabel *titleLbl = [UILabel new];
    titleLbl.text = title;
    titleLbl.font = [UIFont systemFontOfSize:S(20) weight:UIFontWeightRegular];
    titleLbl.textColor = MKHexColor(0x000000);
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.numberOfLines = 0;
    CGSize fit = [titleLbl sizeThatFits:CGSizeMake(W - S(36), CGFLOAT_MAX)];
    titleLbl.frame = CGRectMake(S(18), y, W - S(36), ceil(fit.height));
    [self.containerView addSubview:titleLbl];
    y = CGRectGetMaxY(titleLbl.frame) + S(16);

    // 滚轮 picker — Figma: 上下各 2 行虚化, 中间一行加粗高亮(系统自带效果)
    UIPickerView *wheel = [[UIPickerView alloc] initWithFrame:CGRectMake(0, y, W, S(216))];
    wheel.dataSource = self;
    wheel.delegate = self;
    [self.containerView addSubview:wheel];
    if (self.pickerItems.count > 0) {
        [wheel selectRow:self.pickerSelectedRow inComponent:0 animated:NO];
    }
    y = CGRectGetMaxY(wheel.frame) + S(12);

    // 底部双按钮: Cancel + Confirm
    y = [self addPickerButtonsAtY:y];
    self.contentMaxY = y;
}

#pragma mark - UIPickerView DataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView { return 1; }

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerItems.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
    UILabel *l = [view isKindOfClass:[UILabel class]] ? (UILabel *)view : [UILabel new];
    l.text = self.pickerItems[row];
    l.textAlignment = NSTextAlignmentCenter;
    BOOL isCenter = (row == self.pickerSelectedRow);
    l.font = [UIFont systemFontOfSize:S(isCenter ? 22 : 16)
                               weight:isCenter ? UIFontWeightSemibold : UIFontWeightRegular];
    l.textColor = isCenter ? MKHexColor(0x171718) : MKHexColor(0xA7A7A7);  // Pencil: 外圈 #A7A7A7
    return l;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return S(40);
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.pickerSelectedRow = row;
    [pickerView reloadComponent:0];   // 触发字号/颜色刷新
}

#pragma mark - Picker buttons

- (CGFloat)addPickerButtonsAtY:(CGFloat)y {
    // Pencil 精确: Cancel 90x56 #E9E9E4 文字 #385330; Confirm 170x56 #385330 文字白; 都 cornerRadius=28; Poppins 16/600
    CGFloat W = self.cardWidth;
    CGFloat sidePad = S(20);
    CGFloat gap = S(12);
    CGFloat h = S(56);
    CGFloat cancelW = S(90);
    CGFloat inner = W - sidePad * 2 - gap;
    CGFloat confirmW = inner - cancelW;

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(sidePad, y, cancelW, h);
    cancelBtn.backgroundColor = MKHexColor(0xE9E9E4);
    cancelBtn.layer.cornerRadius = h * 0.5;
    [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:kColorPrimary forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [cancelBtn addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelBtn];

    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(sidePad + cancelW + gap, y, confirmW, h);
    confirmBtn.backgroundColor = kColorPrimary;
    confirmBtn.layer.cornerRadius = h * 0.5;
    [confirmBtn setTitle:@"Confirm" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:kColorWhite forState:UIControlStateNormal];
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [confirmBtn addTarget:self action:@selector(pickerConfirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:confirmBtn];
    return y + h;
}

- (void)pickerConfirmTapped {
    if (self.pickerItems.count > 0 && self.onSelected) {
        NSInteger idx = self.pickerSelectedRow;
        if (idx >= 0 && idx < (NSInteger)self.pickerItems.count) {
            self.onSelected(idx, self.pickerItems[idx]);
        }
    }
    [self dismiss];
}

#pragma mark - 银行卡选择 (滚轮 + Cancel + "+ Please Add A Receiving Account")

- (void)buildBankCardPicker:(NSArray<NSString *> *)items addNewTitle:(NSString *)addNewTitle {
    self.pickerItems = items ?: @[];
    NSInteger sel = [self.config[@"selectedIndex"] integerValue];
    if (sel < 0 || sel >= (NSInteger)self.pickerItems.count) sel = 0;
    self.pickerSelectedRow = sel;

    CGFloat W = self.cardWidth;
    CGFloat y = S(20);  // 无标题, 上下留 20

    // 滚轮 (即使 items 空也保留高度, 用占位行)
    UIPickerView *wheel = [[UIPickerView alloc] initWithFrame:CGRectMake(0, y, W, S(216))];
    wheel.dataSource = self;
    wheel.delegate = self;
    [self.containerView addSubview:wheel];
    if (self.pickerItems.count > 0) {
        [wheel selectRow:self.pickerSelectedRow inComponent:0 animated:NO];
    }
    y = CGRectGetMaxY(wheel.frame) + S(12);

    // 左 Cancel(灰小90) + 右 "+ Add"(绿大,占余下)
    CGFloat sidePad = S(20);
    CGFloat gap = S(12);
    CGFloat h = S(56);
    CGFloat cancelW = S(90);
    CGFloat addW = W - sidePad * 2 - gap - cancelW;

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(sidePad, y, cancelW, h);
    cancelBtn.backgroundColor = MKHexColor(0xE9E9E4);
    cancelBtn.layer.cornerRadius = h * 0.5;
    [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:kColorPrimary forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [cancelBtn addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelBtn];

    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(sidePad + cancelW + gap, y, addW, h);
    addBtn.backgroundColor = kColorPrimary;
    addBtn.layer.cornerRadius = h * 0.5;
    [addBtn setTitle:addNewTitle forState:UIControlStateNormal];
    [addBtn setTitleColor:kColorWhite forState:UIControlStateNormal];
    addBtn.titleLabel.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightSemibold];
    addBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    addBtn.titleLabel.minimumScaleFactor = 0.85;
    addBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    addBtn.titleLabel.numberOfLines = 2;
    [addBtn addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:addBtn];

    self.contentMaxY = y + h;
}

#pragma mark - 还款计划 (title + subtitle + 4 列表格 + Confirm)

- (void)buildRepaymentPlan {
    CGFloat W = self.cardWidth;
    CGFloat y = S(28);

    // Title "Repayment Plan" — Poppins 20 semibold #171718, center
    UILabel *title = [UILabel new];
    title.text = @"Repayment Plan";
    title.font = [UIFont systemFontOfSize:S(20) weight:UIFontWeightSemibold];
    title.textColor = MKHexColor(0x171718);
    title.textAlignment = NSTextAlignmentCenter;
    title.frame = CGRectMake(S(18), y, W - S(36), S(28));
    [self.containerView addSubview:title];
    y = CGRectGetMaxY(title.frame) + S(12);

    // Subtitle 14 #666666 left, 多行
    UILabel *subtitle = [UILabel new];
    subtitle.text = @"If you repay the first amount due on time, the remaining balance will be automatically reset to zero for you.";
    subtitle.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    subtitle.textColor = MKHexColor(0x666666);
    subtitle.numberOfLines = 0;
    CGFloat subInsetX = S(18);
    CGSize sFit = [subtitle sizeThatFits:CGSizeMake(W - subInsetX * 2, CGFLOAT_MAX)];
    subtitle.frame = CGRectMake(subInsetX, y, W - subInsetX * 2, ceil(sFit.height));
    [self.containerView addSubview:subtitle];
    y = CGRectGetMaxY(subtitle.frame) + S(16);

    // 数据: caller 通过 config[@"plans"] 传 NSArray<NSDictionary>
    // 每项 keys: date / amount / principal / interest
    NSArray *plans = [self.config[@"plans"] isKindOfClass:[NSArray class]] ? self.config[@"plans"] : nil;
    if (plans.count == 0) {
        plans = @[
            @{ @"date": @"Aug 18, 2025", @"amount": @"₱3,753", @"principal": @"₱3,333", @"interest": @"₱420" },
            @{ @"date": @"Aug 18, 2025", @"amount": @"₱3,753", @"principal": @"₱3,333", @"interest": @"₱420" },
            @{ @"date": @"Aug 18, 2025", @"amount": @"₱3,753", @"principal": @"₱3,333", @"interest": @"₱420" }
        ];
    }

    // 表格容器: 灰底 (Pencil 看起来 #F3F3EE) cornerRadius 12
    // 行数超 maxVisibleRows 内部走滚动, 不超就按内容高度展开
    CGFloat tableInsetX = S(18);
    CGFloat tableW = W - tableInsetX * 2;
    CGFloat headerH = S(40);
    CGFloat rowH = S(54);
    NSInteger maxVisibleRows = 3;   // 默认显示 3 行 (够则按内容展开, 超出走内部滚动)
    CGFloat fullContentH = headerH + plans.count * rowH + S(8);
    CGFloat tableH = MIN(fullContentH, headerH + maxVisibleRows * rowH + S(8));
    UIView *table = [[UIView alloc] initWithFrame:CGRectMake(tableInsetX, y, tableW, tableH)];
    table.backgroundColor = MKHexColor(0xF3F3EE);
    table.layer.cornerRadius = S(12);
    table.clipsToBounds = YES;
    [self.containerView addSubview:table];

    // 数据区滚动容器 (header 之下), 行多于 maxVisibleRows 才实际滚动
    CGFloat scrollContentH = plans.count * rowH + S(8);
    UIScrollView *rowsScroll = [[UIScrollView alloc]
        initWithFrame:CGRectMake(0, headerH, tableW, tableH - headerH)];
    rowsScroll.contentSize = CGSizeMake(tableW, scrollContentH);
    rowsScroll.showsVerticalScrollIndicator = YES;
    rowsScroll.alwaysBounceVertical = (plans.count > maxVisibleRows);
    [table addSubview:rowsScroll];

    // Pencil csQgk 列宽比例: date 45 / amount 40 / principal 40 / interest 30 (总 155, 都 left-align)
    // 但实际数据 "₱ 10,728.15" 比 Pencil 的 "₱3,753" 长, 需按比例放大到 tableW 内
    CGFloat colPad = S(14);
    CGFloat inner = tableW - colPad * 2;
    CGFloat ratios[4] = { 0.26, 0.27, 0.27, 0.20 };   // date 略窄强制 2 行换行, 数值列 27%, interest 最窄
    CGFloat colX[4]; CGFloat colW[4];
    CGFloat acc = colPad;
    for (NSInteger i = 0; i < 4; i++) { colW[i] = inner * ratios[i]; colX[i] = acc; acc += colW[i]; }

    NSArray<NSString *> *headers = @[ @"Due date", @"Amount\nDue", @"Principal\ndue", @"Interest\ndue" ];
    for (NSInteger i = 0; i < 4; i++) {
        UILabel *h = [UILabel new];
        h.text = headers[i];
        h.font = [UIFont systemFontOfSize:S(12) weight:UIFontWeightRegular];
        h.textColor = MKHexColor(0x171718);
        h.numberOfLines = 2;
        h.textAlignment = NSTextAlignmentLeft;
        h.frame = CGRectMake(colX[i], S(8), colW[i], S(32));
        [table addSubview:h];
    }

    // 数据行: 日期允许 2 行 (e.g. "May 31,\n2026"), 数值列单行 (压缩字号防截断)
    // rowY 改为 scroll content 内坐标 (从 0 开始, 不带 headerH 偏移)
    NSArray *keys = @[ @"date", @"amount", @"principal", @"interest" ];
    for (NSInteger r = 0; r < (NSInteger)plans.count; r++) {
        NSDictionary *item = plans[r];
        CGFloat rowY = r * rowH;
        if (r > 0) {
            UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(S(12), rowY, tableW - S(24), 0.5)];
            sep.backgroundColor = MKHexColor(0xDFDFDF);
            [rowsScroll addSubview:sep];
        }
        for (NSInteger c = 0; c < 4; c++) {
            UILabel *v = [UILabel new];
            v.text = item[keys[c]] ?: @"";
            BOOL isDate = (c == 0);
            v.font = [UIFont systemFontOfSize:S(12) weight:isDate ? UIFontWeightRegular : UIFontWeightBold];
            v.textColor = isDate ? MKHexColor(0x666666) : MKHexColor(0x171718);
            v.numberOfLines = isDate ? 2 : 1;
            if (isDate) {
                v.lineBreakMode = NSLineBreakByWordWrapping;
            } else {
                v.adjustsFontSizeToFitWidth = YES;
                v.minimumScaleFactor = 0.7;
            }
            CGFloat valueH = isDate ? S(40) : S(20);
            CGFloat valueY = rowY + (rowH - valueH) * 0.5;
            v.frame = CGRectMake(colX[c], valueY, colW[c], valueH);
            [rowsScroll addSubview:v];
        }
    }

    y = CGRectGetMaxY(table.frame) + S(24);

    // Confirm 单按钮
    y = [self addSingleButton:@"Confirm" atY:y];
    self.contentMaxY = y;
}

#pragma mark - 通用元素 (返回新的 Y)

- (CGFloat)addTitle:(NSString *)title atY:(CGFloat)y {
    CGFloat W = self.cardWidth;
    UILabel *l = [[UILabel alloc] init];
    l.text = title;
    l.font = [UIFont systemFontOfSize:S(17) weight:UIFontWeightSemibold];
    l.textColor = MKHexColor(0x171718);
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 0;
    CGSize fit = [l sizeThatFits:CGSizeMake(W - S(36), CGFLOAT_MAX)];
    l.frame = CGRectMake(S(18), y, W - S(36), ceil(fit.height));
    [self.containerView addSubview:l];
    return CGRectGetMaxY(l.frame);
}

- (CGFloat)addBody:(NSString *)body atY:(CGFloat)y {
    // 默认 center (短文案/标题型 sheet)
    return [self addBody:body atY:y align:NSTextAlignmentCenter];
}

- (CGFloat)addBody:(NSString *)body atY:(CGFloat)y align:(NSTextAlignment)align {
    CGFloat W = self.cardWidth;
    UILabel *l = [[UILabel alloc] init];
    l.text = body;
    l.font = [UIFont systemFontOfSize:S(14) weight:UIFontWeightRegular];
    l.textColor = MKHexColor(0x666666);
    l.numberOfLines = 0;
    l.textAlignment = align;
    CGFloat maxW = W - S(48);
    CGSize fit = [l sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    l.frame = CGRectMake(S(24), y, maxW, ceil(fit.height));
    [self.containerView addSubview:l];
    return CGRectGetMaxY(l.frame);
}

- (CGFloat)addSingleButton:(NSString *)title atY:(CGFloat)y {
    // Pencil: 279pt宽, 56pt高, cornerRadius=80 (全圆), fill=#385330, text=white/Poppins/16/600
    CGFloat W = self.cardWidth;
    CGFloat btnW = S(279);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((W - btnW) * 0.5, y, btnW, S(56));
    btn.backgroundColor = kColorPrimary;
    btn.layer.cornerRadius = S(28);  // 56/2 = 28 (全圆角)
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:kColorWhite forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [btn addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:btn];
    return CGRectGetMaxY(btn.frame);
}

// Upgrade 强更单按钮 (279pt, fill=#385330, cornerRadius=28)
- (CGFloat)addSingleButtonUpgrade:(NSString *)title atY:(CGFloat)y {
    CGFloat W = self.cardWidth;
    CGFloat btnW = S(279);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((W - btnW) * 0.5, y, btnW, S(56));
    btn.backgroundColor = kColorPrimary;
    btn.layer.cornerRadius = S(28);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:kColorWhite forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [btn addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:btn];
    return CGRectGetMaxY(btn.frame);
}

// Upgrade 普通更新: Cancel(90pt,左,#ffffff,text=#385330) + Upgrade(170pt,右,#385330,white)
// Pencil 坐标: Cancel x=52→card 内 30, Upgrade x=153→card 内 131, gap=11
- (CGFloat)addDoubleButtonsUpgrade:(NSString *)confirm cancel:(NSString *)cancel atY:(CGFloat)y {
    CGFloat W = self.cardWidth;
    CGFloat sidePad = S(30);
    CGFloat gap = S(11);
    CGFloat h = S(56);
    CGFloat cancelW = S(90);
    CGFloat confirmW = S(170);

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(sidePad, y, cancelW, h);
    cancelBtn.backgroundColor = [UIColor whiteColor];
    cancelBtn.layer.cornerRadius = h * 0.5;
    [cancelBtn setTitle:cancel forState:UIControlStateNormal];
    [cancelBtn setTitleColor:kColorPrimary forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [cancelBtn addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelBtn];

    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(sidePad + cancelW + gap, y, confirmW, h);
    confirmBtn.backgroundColor = kColorPrimary;
    confirmBtn.layer.cornerRadius = h * 0.5;
    [confirmBtn setTitle:confirm forState:UIControlStateNormal];
    [confirmBtn setTitleColor:kColorWhite forState:UIControlStateNormal];
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [confirmBtn addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:confirmBtn];
    return y + h;
}

// 通用双按钮: 左小(90pt,#e9e9e4,text=#385330) + 右大(170pt,#385330,white)
- (CGFloat)addDoubleButtonsCancelLeftConfirmRightAtY:(CGFloat)y
                                         confirmTitle:(NSString *)confirmTitle
                                          cancelTitle:(NSString *)cancelTitle
                                           cancelFill:(MKSheetCancelFillStyle)cancelFill {
    // Pencil 双按钮统一布局 — 相对 sheet frame(375) x=52, base 容器宽 331(去掉左右各 22 边距)
    // 转 cardWidth(331) 内坐标 = Pencil x − 22 → sidePad=30, gap=11, smallW=90, largeW=170
    CGFloat sidePad = S(30);
    CGFloat gap = S(11);
    CGFloat h = S(56);
    CGFloat smallW = S(90);
    CGFloat largeW = S(170);

    // 左小 Cancel (灰底 #E9E9E4 或白底 #FFFFFF)
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(sidePad, y, smallW, h);
    cancelBtn.backgroundColor = (cancelFill == MKSheetCancelFillWhite) ? kColorWhite : MKHexColor(0xE9E9E4);
    cancelBtn.layer.cornerRadius = h * 0.5;
    [cancelBtn setTitle:cancelTitle forState:UIControlStateNormal];
    [cancelBtn setTitleColor:kColorPrimary forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [cancelBtn addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelBtn];

    // 右大 Confirm (主色 #385330)
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(sidePad + smallW + gap, y, largeW, h);
    confirmBtn.backgroundColor = kColorPrimary;
    confirmBtn.layer.cornerRadius = h * 0.5;
    [confirmBtn setTitle:confirmTitle forState:UIControlStateNormal];
    [confirmBtn setTitleColor:kColorWhite forState:UIControlStateNormal];
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [confirmBtn addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:confirmBtn];
    return y + h;
}

- (CGFloat)addDoubleButtonsConfirm:(NSString *)c cancel:(NSString *)cancel atY:(CGFloat)y {
    CGFloat W = self.cardWidth;
    CGFloat sidePad = S(20);
    CGFloat gap = S(10);
    CGFloat half = (W - sidePad * 2 - gap) * 0.5;
    CGFloat h = S(46);

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(sidePad, y, half, h);
    cancelBtn.backgroundColor = MKHexColor(0xE9E9E4);
    cancelBtn.layer.cornerRadius = h * 0.5;
    [cancelBtn setTitle:cancel forState:UIControlStateNormal];
    [cancelBtn setTitleColor:MKHexColor(0x171718) forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [cancelBtn addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelBtn];

    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(sidePad + half + gap, y, half, h);
    confirmBtn.backgroundColor = kColorPrimary;
    confirmBtn.layer.cornerRadius = h * 0.5;
    [confirmBtn setTitle:c forState:UIControlStateNormal];
    [confirmBtn setTitleColor:kColorWhite forState:UIControlStateNormal];
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:S(16) weight:UIFontWeightSemibold];
    [confirmBtn addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:confirmBtn];
    return y + h;
}

#pragma mark - 按钮事件

- (void)confirmTapped {
    if (self.onConfirmTapped) self.onConfirmTapped();
    [self dismiss];
}

- (void)cancelTapped {
    if (self.onCancelTapped) self.onCancelTapped();
    [self dismiss];
}

#pragma mark - 显示/关闭

- (void)show {
    UIView *host = nil;
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *w in scene.windows) { if (w.isKeyWindow) { host = w; break; } }
        }
        if (host) break;
    }
    if (!host) {
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.windows.firstObject) { host = scene.windows.firstObject; break; }
        }
    }
    if (!host) return;
    self.frame = host.bounds;
    self.dimView.frame = self.bounds;
    [self anchorContainerToBottom];
    [host addSubview:self];

    // 起始: 在屏幕外下方
    CGRect endFrame = self.containerView.frame;
    CGRect startFrame = endFrame;
    startFrame.origin.y = self.bounds.size.height;
    self.containerView.frame = startFrame;
    self.containerView.alpha = 1;

    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.92 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.dimView.alpha = 1;
        self.containerView.frame = endFrame;
    } completion:nil];
}

- (void)dismiss {
    CGRect endFrame = self.containerView.frame;
    endFrame.origin.y = self.bounds.size.height;
    [UIView animateWithDuration:0.22 animations:^{
        self.dimView.alpha = 0;
        self.containerView.frame = endFrame;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
