//
//  MKKYCLivenessViewController.m
//  Figma 3:1155/3:1171 KYC-活体认证 (前置相机 + Ready/Captured 状态机)
//
//  布局: 品牌绿 nav "ID Information"
//        Hint card (18,110) 339×42
//        圆形预览框 (34,178) 307×307 (前置相机 preview 圆形 mask)
//        Ready: 单按钮 "Take A Photo" 主色实心
//        Captured: 双按钮 上=Confirm 主色实心 / 下=Restart 描边
//

#import "MKKYCLivenessViewController.h"
#import "MKConstants.h"
#import "MKHintBannerView.h"
#import <AVFoundation/AVFoundation.h>

@interface MKKYCLivenessViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) UIView *previewContainer;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIImageView *placeholderFaceIcon;
@property (nonatomic, strong) UIButton *takeBtn;
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UIButton *restartBtn;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong, nullable) UIImage *capturedImage;
@property (nonatomic, assign) BOOL hasCamera;
@end

@implementation MKKYCLivenessViewController

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
    [self setupUI];
    [self setupCameraIfAvailable];
    [self enterReadyState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopSession];
}

#pragma mark - UI

- (void)setupUI {
    NSString *hintText = @"Align the frame and take a clear front photo.";
    CGFloat hintH = [MKHintBannerView heightForText:hintText];
    MKHintBannerView *hint = [[MKHintBannerView alloc] initWithText:hintText];
    hint.frame = CGRectMake(kScaleW(18), kNavBarHeight + kScaleH(12), kScaleW(339), hintH);
    [self.view addSubview:hint];

    // Pencil: 活体预览框 307×328 (tall oval, cornerRadius=153.5) bg #252F2C
    CGFloat ovalW = kScaleW(307);
    CGFloat ovalH = kScaleH(328);
    CGFloat size = ovalW; // keep 'size' for inner subviews
    self.previewContainer = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth - ovalW) * 0.5,
                                                                      kNavBarHeight + hintH + kScaleH(40),
                                                                      ovalW, ovalH)];
    self.previewContainer.backgroundColor = MKHexColor(0x252F2C);
    self.previewContainer.layer.cornerRadius = kScaleW(153.5);
    self.previewContainer.clipsToBounds = YES;
    [self.view addSubview:self.previewContainer];

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:80
                                                                                       weight:UIImageSymbolWeightUltraLight];
    self.placeholderFaceIcon = [[UIImageView alloc] initWithImage:
        [[UIImage systemImageNamed:@"person.fill" withConfiguration:cfg]
         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.placeholderFaceIcon.tintColor = MKHexColor(0xFFFFFF);
    self.placeholderFaceIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.placeholderFaceIcon.frame = CGRectMake((size - kScaleW(120)) * 0.5,
                                                  (size - kScaleW(120)) * 0.5,
                                                  kScaleW(120), kScaleW(120));
    [self.previewContainer addSubview:self.placeholderFaceIcon];

    // captured image 占满预览圈
    self.capturedImageView = [[UIImageView alloc] initWithFrame:self.previewContainer.bounds];
    self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.capturedImageView.clipsToBounds = YES;
    self.capturedImageView.hidden = YES;
    [self.previewContainer addSubview:self.capturedImageView];

    // Take A Photo (Ready 主按钮)
    self.takeBtn = [self primaryButtonWithTitle:@"Take A Photo" action:@selector(takePhoto)];
    self.takeBtn.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(76),
                                     kScaleW(303), kScaleH(56));
    [self.view addSubview:self.takeBtn];

    // Confirm (Captured 主按钮, 上方)
    self.confirmBtn = [self primaryButtonWithTitle:@"Confirm" action:@selector(confirmTap)];
    self.confirmBtn.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(144),
                                        kScaleW(303), kScaleH(56));
    self.confirmBtn.hidden = YES;
    [self.view addSubview:self.confirmBtn];

    // Restart (Captured 描边按钮, 下方)
    // Pencil 活体认证后: Restart 按钮 bg=#E9E9E4, cornerRadius=49, 无描边, 文字 #385330
    self.restartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.restartBtn.frame = CGRectMake(kScaleW(36), kScreenHeight - kBottomSafeHeight - kScaleH(76),
                                        kScaleW(303), kScaleH(56));
    self.restartBtn.backgroundColor = MKHexColor(0xE9E9E4);
    // Pencil 标注 49 是设计 token, 但 button height=56, 实际 pill 形圆角应 = height/2 = 28
    self.restartBtn.layer.cornerRadius = kScaleH(28);
    [self.restartBtn setTitle:@"Restart" forState:UIControlStateNormal];
    [self.restartBtn setTitleColor:kColorPrimary forState:UIControlStateNormal];
    self.restartBtn.titleLabel.font = kFontSemibold(16);
    [self.restartBtn addTarget:self action:@selector(restartTap) forControlEvents:UIControlEventTouchUpInside];
    self.restartBtn.hidden = YES;
    [self.view addSubview:self.restartBtn];
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = kColorPrimary;
    btn.layer.cornerRadius = kScaleH(28);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:kColorWhite forState:UIControlStateNormal];
    btn.titleLabel.font = kFontSemibold(16);
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

#pragma mark - Camera (前置)

- (void)setupCameraIfAvailable {
    AVCaptureDevice *front = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                 mediaType:AVMediaTypeVideo
                                                                  position:AVCaptureDevicePositionFront];
    if (!front) {
        self.hasCamera = NO;   // 模拟器走 placeholder fallback
        return;
    }
    self.hasCamera = YES;

    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    }

    NSError *err = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:front error:&err];
    if (input && [self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }

    self.photoOutput = [AVCapturePhotoOutput new];
    if ([self.captureSession canAddOutput:self.photoOutput]) {
        [self.captureSession addOutput:self.photoOutput];
    }

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.previewContainer.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewContainer.layer insertSublayer:self.previewLayer atIndex:0];
    self.placeholderFaceIcon.hidden = YES;

    [self requestAuthThenStart];
}

- (void)requestAuthThenStart {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [self startSession];
    } else if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) [self startSession];
            });
        }];
    }
}

- (void)startSession {
    if (!self.captureSession.isRunning) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)stopSession {
    if (self.captureSession.isRunning) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self.captureSession stopRunning];
        });
    }
}

#pragma mark - 状态机

- (void)enterReadyState {
    self.capturedImage = nil;
    self.capturedImageView.image = nil;
    self.capturedImageView.hidden = YES;
    self.takeBtn.hidden = NO;
    self.confirmBtn.hidden = YES;
    self.restartBtn.hidden = YES;
    if (self.hasCamera) [self startSession];
}

- (void)enterCapturedStateWithImage:(UIImage *)image {
    self.capturedImage = image;
    if (image) {
        self.capturedImageView.image = image;
        self.capturedImageView.hidden = NO;
    }
    self.takeBtn.hidden = YES;
    self.confirmBtn.hidden = NO;
    self.restartBtn.hidden = NO;
    [self stopSession];
}

#pragma mark - Actions

- (void)takePhoto {
    if (self.hasCamera && self.photoOutput) {
        AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
        [self.photoOutput capturePhotoWithSettings:settings delegate:self];
    } else {
        [self enterCapturedStateWithImage:[self placeholderFaceImage]];
    }
}

- (void)confirmTap {
    if (!self.capturedImage) return;
    if (self.onLivenessCompleted) self.onLivenessCompleted(self.capturedImage);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)restartTap {
    [self enterReadyState];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhoto:(AVCapturePhoto *)photo
                error:(NSError *)error {
    NSData *data = [photo fileDataRepresentation];
    UIImage *img = data ? [UIImage imageWithData:data] : nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enterCapturedStateWithImage:img];
    });
}

#pragma mark - 模拟器 fallback

- (UIImage *)placeholderFaceImage {
    CGSize size = CGSizeMake(400, 400);
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
    [[UIColor lightGrayColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:200
                                                                                       weight:UIImageSymbolWeightRegular];
    UIImage *icon = [[UIImage systemImageNamed:@"person.fill" withConfiguration:cfg]
                     imageWithTintColor:[UIColor darkGrayColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
    [icon drawInRect:CGRectMake((size.width - 200) * 0.5, (size.height - 200) * 0.5, 200, 200)];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out;
}

@end
