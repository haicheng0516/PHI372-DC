//  MKKYCIDViewController.m
//  Figma 3:1099 KYC-身份证认证
//    - /app/v3/kyc/four/search-iterm (kycId=identity_liveness) 拉证件类型 (取首个 buttonList[0].buttonKey)
//    - face box → push Liveness, callback 回填 faceImage
//    - front box → push IDCamera, callback 回填 idImage
//    - /app/v3/kyc/four/liveness (identity_front_img + liveness_img + card_type) 提交
//      成功后 popToRootViewController (回 Home), Home viewWillAppear 自动刷接口 → userStatus 翻转

#import "MKKYCIDViewController.h"
#import "MKConstants.h"
#import "MKHintBannerView.h"
#import "MKKYCIDCameraViewController.h"
#import "MKKYCLivenessViewController.h"
#import "UIImage+MKOrientation.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKKYCInitResponse.h"
#import "MKKYCCommitResponse.h"
#import "MKKYCProgressBarView.h"
#import "MKBottomSheetView.h"
#import <AVFoundation/AVFoundation.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>

#pragma mark - Dashed Box (UI 不动, 内部加 image preview)

@interface MKKYCDashedBox : UIControl
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIImageView *photoPreview;   // 拍完显示
- (void)showCaptured:(UIImage *)image;
@end

@implementation MKKYCDashedBox {
    CAShapeLayer *_dashLayer;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = MKHexColor(0xF5F5EF);
        self.layer.cornerRadius = kScaleH(14);
        self.clipsToBounds = YES;

        _dashLayer = [CAShapeLayer layer];
        _dashLayer.strokeColor = MKHexColor(0xBBCB2F).CGColor;
        _dashLayer.fillColor = [UIColor clearColor].CGColor;
        _dashLayer.lineWidth = 2;
        _dashLayer.lineDashPattern = @[ @5, @5 ];
        [self.layer addSublayer:_dashLayer];

        _iconView = [UIImageView new];
        _iconView.tintColor = kColorPrimary;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconView];

        _titleLabel = [UILabel new];
        _titleLabel.font = kFontSemibold(16);
        _titleLabel.textColor = MKHexColor(0x171718);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];

        _photoPreview = [UIImageView new];
        _photoPreview.contentMode = UIViewContentModeScaleAspectFill;
        _photoPreview.clipsToBounds = YES;
        _photoPreview.layer.cornerRadius = kScaleH(14);
        _photoPreview.hidden = YES;
        [self addSubview:_photoPreview];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _dashLayer.frame = self.bounds;
    _dashLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 1, 1)
                                                  cornerRadius:kScaleH(14)].CGPath;
    CGFloat iconSize = kScaleW(40);
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    BOOL hasTitle = self.titleLabel.text.length > 0;
    if (hasTitle) {
        self.titleLabel.frame = CGRectMake(0, kScaleH(20), W, kScaleH(24));
        self.iconView.frame   = CGRectMake((W - iconSize) * 0.5, (H - iconSize) * 0.5 + kScaleH(10), iconSize, iconSize);
    } else {
        self.iconView.frame = CGRectMake((W - iconSize) * 0.5, (H - iconSize) * 0.5, iconSize, iconSize);
    }
    self.photoPreview.frame = self.bounds;
}
- (void)showCaptured:(UIImage *)image {
    self.photoPreview.image = image;
    self.photoPreview.hidden = (image == nil);
}
@end

#pragma mark - VC

@interface MKKYCIDViewController ()
@property (nonatomic, strong) MKKYCProgressBarView *progressBar;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) MKKYCDashedBox *faceBox;
@property (nonatomic, strong) MKKYCDashedBox *frontBox;
@property (nonatomic, strong) UIImage *idImage;
@property (nonatomic, strong) UIImage *faceImage;
@property (nonatomic, copy)   NSString *idTypeKey;   // 来自 search-iterm 首个 buttonList[0].buttonKey
@end

@implementation MKKYCIDViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"ID Information";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    // 进度条 — step 4/4
    self.progressBar = [[MKKYCProgressBarView alloc] init];
    self.progressBar.totalSteps = 4;
    self.progressBar.currentStep = 4;
    [self.view addSubview:self.progressBar];
    [self.progressBar mas_makeConstraints:^(MASConstraintMaker *m) {
        m.top.equalTo(self.view).offset(kNavBarHeight + 12);
        m.left.equalTo(self.view).offset(20);
        m.right.equalTo(self.view).offset(-20);
        m.height.mas_equalTo(28);
    }];

    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = kColorBackground;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *m) {
        m.top.equalTo(self.progressBar.mas_bottom).offset(12);
        m.left.right.bottom.equalTo(self.view);
    }];

    CGFloat y = kScaleH(12);

    // Hint 1
    NSString *hint1 = @"Please upload one valid ID. Supported IDs include UMID, National ID, SSS, TIN, Passport, Driver's License, Postal ID, Voter ID, or Health Card.";
    CGFloat h1 = [MKHintBannerView heightForText:hint1];
    MKHintBannerView *b1 = [[MKHintBannerView alloc] initWithText:hint1];
    b1.frame = CGRectMake(kScaleW(18), y, kScaleW(339), h1);
    [self.scrollView addSubview:b1];
    y += h1 + kScaleH(16);

    // Front upload (Pencil: Rectangle 20 y=278, before hint2 and faceBox)
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:36 weight:UIImageSymbolWeightLight];
    self.frontBox = [[MKKYCDashedBox alloc] initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), kScaleH(177))];
    self.frontBox.titleLabel.text = @"Front";
    self.frontBox.iconView.image = [[UIImage systemImageNamed:@"camera" withConfiguration:cfg]
                                     imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.frontBox addTarget:self action:@selector(frontTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.frontBox];
    y += kScaleH(177) + kScaleH(16);

    // Hint 2 (Pencil: ZbOxK y=467, h=123)
    NSString *hint2 = @"1. Please make sure that the ID card you upload is genuine and valid.\n\n2. Please make sure that the uploaded ID card photo is clear and complete, otherwise it will not pass verification.";
    CGFloat h2 = [MKHintBannerView heightForText:hint2];
    MKHintBannerView *b2 = [[MKHintBannerView alloc] initWithText:hint2];
    b2.frame = CGRectMake(kScaleW(18), y, kScaleW(339), h2);
    [self.scrollView addSubview:b2];
    y += h2 + kScaleH(16);

    // Hint 3 — tap reminder (Pencil: lm7bC y=634, h=52)
    NSString *hint3 = @"Tap the photo area to take or retake your face photo";
    CGFloat h3 = [MKHintBannerView heightForText:hint3];
    MKHintBannerView *b3 = [[MKHintBannerView alloc] initWithText:hint3];
    b3.frame = CGRectMake(kScaleW(18), y, kScaleW(339), h3);
    [self.scrollView addSubview:b3];
    y += h3 + kScaleH(16);

    // Face identification (Pencil: Rectangle 4219 y=698, after hint3)
    self.faceBox = [[MKKYCDashedBox alloc] initWithFrame:CGRectMake(kScaleW(18), y, kScaleW(339), kScaleH(177))];
    self.faceBox.titleLabel.text = @"Face identification";
    self.faceBox.iconView.image = [[UIImage systemImageNamed:@"person.fill.viewfinder" withConfiguration:cfg]
                                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.faceBox addTarget:self action:@selector(faceTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.faceBox];
    y += kScaleH(177) + kScaleH(24);

    // Continue
    UIButton *cont = [UIButton buttonWithType:UIButtonTypeCustom];
    cont.frame = CGRectMake(kScaleW(36), y, kScaleW(303), kScaleH(56));
    cont.backgroundColor = kColorPrimary;
    cont.layer.cornerRadius = kScaleH(28);
    [cont setTitle:@"Continue" forState:UIControlStateNormal];
    [cont setTitleColor:kColorWhite forState:UIControlStateNormal];
    cont.titleLabel.font = kFontSemibold(16);
    [cont addTarget:self action:@selector(continueTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:cont];
    y += kScaleH(56) + kScaleH(20);

    self.scrollView.contentSize = CGSizeMake(kScreenWidth, y + kBottomSafeHeight);

    [self requestIDTypeKey];
}

#pragma mark - search-iterm 拉证件类型

- (void)requestIDTypeKey {
    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{}
                            requestData:@{@"kycId": @"identity_liveness"}];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/search-iterm"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        MKKYCInitResponse *r = [[MKKYCInitResponse alloc] initWithDictionary:resp];
        if (![r isSuccess] || r.kycItemList.count == 0) return;
        [strongSelf resolveIDTypeKeyFromList:r.kycItemList];
        NSLog(@"[KYC4] idTypeKey resolved = %@", strongSelf.idTypeKey);
    } failure:^(NSError *error) { /* 证件类型可后退兜底 */ }];
}

- (void)resolveIDTypeKeyFromList:(NSArray<MKKYCItemModel *> *)list {
    for (MKKYCItemModel *it in list) {
        if ([it isPickerType] && it.buttonList.count > 0) {
            self.idTypeKey = it.buttonList.firstObject.buttonKey;
            return;
        }
    }
}

#pragma mark - 拍照入口

- (BOOL)ensureCameraPermissionOrAlert {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [self showCameraPermissionAlert];
        return NO;
    }
    return YES;
}

- (void)showCameraPermissionAlert {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Camera Permission"
                                message:@"Camera access is required for KYC verification. Please enable it in Settings."
                                preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)faceTapped {
    if (![self ensureCameraPermissionOrAlert]) return;
    MKKYCLivenessViewController *vc = [[MKKYCLivenessViewController alloc] init];
    kWeakSelf
    vc.onLivenessCompleted = ^(UIImage *image) {
        kStrongSelf
        strongSelf.faceImage = image;
        [strongSelf.faceBox showCaptured:image];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)frontTapped {
    if (![self ensureCameraPermissionOrAlert]) return;
    MKKYCIDCameraViewController *vc = [[MKKYCIDCameraViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    kWeakSelf
    vc.onImageCaptured = ^(UIImage *image, UIDeviceOrientation orientation) {
        kStrongSelf
        UIImage *processed = [strongSelf processedImage:image deviceOrientation:orientation];
        strongSelf.idImage = processed;
        [strongSelf.frontBox showCaptured:processed];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Image Processing

- (UIImage *)processedImage:(UIImage *)image deviceOrientation:(UIDeviceOrientation)orientation {
    if (!image) return nil;
    UIImage *fixed = [image fixOrientation];
    BOOL shouldRotate = (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight);
    if (!shouldRotate) return fixed;
    UIImage *rotated = [fixed rotateBasedOnDeviceOrientation:orientation];
    return rotated ?: fixed;
}

#pragma mark - Continue → 提交 /kyc/four/liveness

- (void)continueTapped {
    if (!self.idImage) {
        [SVProgressHUD showErrorWithStatus:@"Please upload your ID photo"];
        return;
    }
    if (!self.faceImage) {
        [SVProgressHUD showErrorWithStatus:@"Please complete face identification"];
        return;
    }
    if (self.idTypeKey.length == 0) {
        // 兜底: 重拉一次 idTypeKey 后再让用户重试
        [self requestIDTypeKey];
        [SVProgressHUD showErrorWithStatus:@"Loading ID type, please retry"];
        return;
    }

    [SVProgressHUD showWithStatus:@"Uploading..."];
    NSString *idBase64 = [self base64FromImage:self.idImage];
    NSString *faceBase64 = [self base64FromImage:self.faceImage];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    if (idBase64.length > 0)    data[@"identity_front_img"] = idBase64;
    if (faceBase64.length > 0)  data[@"liveness_img"] = faceBase64;
    if (self.idTypeKey.length > 0) data[@"card_type"] = self.idTypeKey;

    NSDictionary *params = [[MKEncryptManager sharedManager]
                            generateRequestBodyWithSignData:@{} requestData:data];
    kWeakSelf
    [[MKNetworkManager sharedManager] post:@"/app/v3/kyc/four/liveness"
                                    params:params
                                   success:^(id resp) {
        kStrongSelf
        [SVProgressHUD dismiss];
        MKKYCCommitResponse *r = [[MKKYCCommitResponse alloc] initWithDictionary:resp];
        if ([r isSuccess]) {
            [SVProgressHUD showSuccessWithStatus:@"Submitted"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [strongSelf.navigationController popToRootViewControllerAnimated:YES];
            });
        } else if (r.resultCode == 6212011 || r.resultCode == 6212009) {
            MKBottomSheetView *fail = [MKBottomSheetView sheetWithType:MKBottomSheetTypeKYCFail config:nil];
            fail.onConfirmTapped = ^{
                kStrongSelf
                strongSelf.idImage = nil;
                strongSelf.faceImage = nil;
                [strongSelf.faceBox showCaptured:nil];
                [strongSelf.frontBox showCaptured:nil];
            };
            [fail show];
        } else {
            [SVProgressHUD showErrorWithStatus:r.resultMsg ?: @"Submit failed"];
            [SVProgressHUD dismissWithDelay:2.0];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"Network error"];
        [SVProgressHUD dismissWithDelay:2.0];
    }];
}

#pragma mark - base64

- (NSString *)base64FromImage:(UIImage *)image {
    if (!image) return @"";

    NSInteger minSize = 100 * 1024;             // 最小 100KB
    NSInteger maxSize = 800 * 1024;             // 最大 800KB
    NSInteger recommendedMaxSize = 600 * 1024;  // 推荐最大 600KB
    CGFloat maxDimension = 2000.0;

    // 超大图片先缩小到 maxDimension
    UIImage *processed = image;
    if (image.size.width > maxDimension || image.size.height > maxDimension) {
        CGFloat scale = MIN(maxDimension / image.size.width, maxDimension / image.size.height);
        CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        processed = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (!processed) processed = image;
    }

    // 小于 100KB 直接返回
    NSData *data = UIImageJPEGRepresentation(processed, 1.0);
    if (data && data.length <= minSize) {
        return [data base64EncodedStringWithOptions:0];
    }

    // 大于 800KB 时目标压缩到 600KB, 否则压到 800KB 以内
    NSInteger targetSize = (data && data.length > maxSize) ? recommendedMaxSize : maxSize;

    // 逐步压缩 quality 0.9 → 0.1
    CGFloat compression = 0.9f;
    data = UIImageJPEGRepresentation(processed, compression);
    while (data && data.length > targetSize && compression > 0.1f) {
        compression -= 0.1f;
        data = UIImageJPEGRepresentation(processed, compression);
    }

    // 仍然超过 800KB → 按面积比例缩小尺寸再压
    if (data && data.length > maxSize) {
        CGFloat scale = sqrt((CGFloat)maxSize / (CGFloat)data.length);
        CGSize newSize = CGSizeMake(processed.size.width * scale, processed.size.height * scale);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [processed drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (scaled) {
            compression = 0.8f;
            data = UIImageJPEGRepresentation(scaled, compression);
            while (data && data.length > maxSize && compression > 0.1f) {
                compression -= 0.1f;
                data = UIImageJPEGRepresentation(scaled, compression);
            }
        }
    }

    return data ? [data base64EncodedStringWithOptions:0] : @"";
}

// resizeImage 保留以备其他地方调用 (KYC4 主流程已切到上面新 base64)
- (UIImage *)resizeImage:(UIImage *)image maxDimension:(CGFloat)maxDim {
    CGSize size = image.size;
    if (size.width <= maxDim && size.height <= maxDim) return image;
    CGFloat ratio = MIN(maxDim / size.width, maxDim / size.height);
    CGSize newSize = CGSizeMake(size.width * ratio, size.height * ratio);
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out;
}

#pragma mark - 拦截返回 (跟 KYC1/2/3 一致, 弹返回确认)

- (void)onBackTapped {
    [self.view endEditing:YES];
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeBackConfirm config:nil];
    kWeakSelf
    sheet.onConfirmTapped = ^{
        kStrongSelf
        [strongSelf.navigationController popToRootViewControllerAnimated:YES];
    };
    [sheet show];
}

@end
