//
//  MKKYCIDCameraViewController.m
//  PHI372-DC — Figma 3:1126/1140 KYC-身份证拍照 (AVFoundation 相机预览 + 取景框 + 双态)
//
//  布局:
//    AVCaptureVideoPreviewLayer 全屏 (后置相机)
//    黑遮罩 0.85 (覆盖在 preview 上, 取景区域抠掉)
//    337×541 取景框 (虚线 #BBCB2F 3px dash 9-9 r=30)
//    顶部提示文 + 右上 x 按钮
//    底部按钮: 拍前=圆形快门 / 拍后=旋转(retake) + 圆形勾(confirm)
//

#import "MKKYCIDCameraViewController.h"
#import "MKConstants.h"
#import "MKKYCLivenessViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

@interface MKKYCIDCameraViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, assign) BOOL captured;
@property (nonatomic, strong) UIButton *shutter;
@property (nonatomic, strong) UIButton *retakeBtn;
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) UIImage *capturedImage;
@property (nonatomic, assign) CGRect viewfinderRect;
// 照搬 334 RDKYC5: CMMotionManager 监听设备方向, confirm 时回传真实 orientation
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) UIDeviceOrientation currentDeviceOrientation;
@property (nonatomic, assign) UIDeviceOrientation capturedDeviceOrientation;
@end

@implementation MKKYCIDCameraViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStyleNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    self.view.backgroundColor = [UIColor blackColor];
    self.currentDeviceOrientation = UIDeviceOrientationPortrait;
    self.capturedDeviceOrientation = UIDeviceOrientationUnknown;

    // 取景框矩形 (Figma 19,121, 337×541, r=30)
    self.viewfinderRect = CGRectMake(kScaleW(19), kScaleH(121), kScaleW(337), kScaleH(541));

    [self setupCamera];
    [self setupOverlay];
    [self setupControls];

    [self requestCameraAuthThenStart];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startMonitoringOrientation];
}

#pragma mark - Camera

- (void)requestCameraAuthThenStart {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [self startSession];
    } else if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) [self startSession];
            });
        }];
    } else {
        // 模拟器 / 拒绝 — 显示静态预览框 (开发可 demo)
    }
}

- (void)setupCamera {
    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    }

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                 mediaType:AVMediaTypeVideo
                                                                  position:AVCaptureDevicePositionBack];
    if (!device) return;
    NSError *err = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
    if (input && [self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }

    self.photoOutput = [AVCapturePhotoOutput new];
    if ([self.captureSession canAddOutput:self.photoOutput]) {
        [self.captureSession addOutput:self.photoOutput];
    }

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
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

#pragma mark - Overlay (黑遮罩 + 取景框虚线)

- (void)setupOverlay {
    // 黑半透明遮罩, 通过 path 抠掉取景框区域 (mask 反向)
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    // Pencil: 遮罩 #00000099 = 60% opacity
    overlay.backgroundColor = MKColorAlpha(0, 0, 0, 0.6);
    overlay.userInteractionEnabled = NO;
    [self.view addSubview:overlay];

    CAShapeLayer *mask = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:overlay.bounds];
    UIBezierPath *cutout = [UIBezierPath bezierPathWithRoundedRect:self.viewfinderRect cornerRadius:kScaleH(30)];
    [path appendPath:cutout];
    path.usesEvenOddFillRule = YES;
    mask.path = path.CGPath;
    mask.fillRule = kCAFillRuleEvenOdd;
    overlay.layer.mask = mask;

    // 取景框虚线
    CAShapeLayer *dash = [CAShapeLayer layer];
    dash.frame = self.view.bounds;
    dash.fillColor = [UIColor clearColor].CGColor;
    dash.strokeColor = MKHexColor(0xBBCB2F).CGColor;
    dash.lineWidth = 3;
    dash.lineDashPattern = @[ @9, @9 ];
    dash.path = [UIBezierPath bezierPathWithRoundedRect:self.viewfinderRect cornerRadius:kScaleH(30)].CGPath;
    [self.view.layer addSublayer:dash];

    // 提示文 (顶部, Figma 文案)
    UILabel *hint = [UILabel new];
    hint.text = @"When taking the photo, please align the dotted frame with the edges of your ID.";
    hint.font = kFontRegular(14);
    hint.textColor = MKHexColor(0xF89E21);
    hint.numberOfLines = 0;
    hint.textAlignment = NSTextAlignmentCenter;
    hint.frame = CGRectMake(kScaleW(28), kStatusBarHeight + kScaleH(20), kScreenWidth - kScaleW(56), kScaleH(40));
    [self.view addSubview:hint];

    // 拍照预览图 (拍完显示, 默认隐藏) — 占据取景框区域
    self.previewImageView = [[UIImageView alloc] initWithFrame:self.viewfinderRect];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.previewImageView.clipsToBounds = YES;
    self.previewImageView.layer.cornerRadius = kScaleH(30);
    self.previewImageView.hidden = YES;
    [self.view addSubview:self.previewImageView];
}

#pragma mark - Controls

- (void)setupControls {
    // 右上 x 关闭
    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(kScreenWidth - kScaleW(60), kStatusBarHeight + kScaleH(8), 44, 44);
    UIImageSymbolConfiguration *xcfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold];
    [close setImage:[[UIImage systemImageNamed:@"xmark" withConfiguration:xcfg]
                     imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
           forState:UIControlStateNormal];
    close.tintColor = kColorWhite;
    [close addTarget:self action:@selector(closeTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:close];

    CGFloat shutterSize = kScaleW(72);
    CGFloat shutterY = kScreenHeight - kBottomSafeHeight - kScaleH(140);
    CGFloat shutterCenterY = shutterY + shutterSize * 0.5;
    // Pencil 拍后两按钮水平对称: confirm 圆心居中偏左 -60, retake 图标居中偏右 +60
    CGFloat dualOffset = kScaleW(60);

    // Pencil: 快门圆 #BBCB2F 实心, stroke #385330 1.5px (拍前居中单按钮)
    self.shutter = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shutter.frame = CGRectMake((kScreenWidth - shutterSize) * 0.5, shutterY, shutterSize, shutterSize);
    self.shutter.backgroundColor = MKHexColor(0xBBCB2F);
    self.shutter.layer.cornerRadius = shutterSize * 0.5;
    self.shutter.layer.borderColor = MKHexColor(0x385330).CGColor;
    self.shutter.layer.borderWidth = 1.5;
    [self.shutter addTarget:self action:@selector(snap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shutter];

    // 确认 (Pencil: 绿圆 #bbcb2f + 深绿 check #385330, 圆心居中偏左)
    self.confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.confirmBtn.frame = CGRectMake(kScreenWidth * 0.5 - dualOffset - shutterSize * 0.5,
                                       shutterCenterY - shutterSize * 0.5,
                                       shutterSize, shutterSize);
    self.confirmBtn.backgroundColor = MKHexColor(0xBBCB2F);
    self.confirmBtn.layer.cornerRadius = shutterSize * 0.5;
    UIImageSymbolConfiguration *ccfg = [UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightBold];
    [self.confirmBtn setImage:[[UIImage systemImageNamed:@"checkmark" withConfiguration:ccfg]
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                     forState:UIControlStateNormal];
    self.confirmBtn.tintColor = MKHexColor(0x385330);  // Pencil: 深绿 check, 不是白色
    [self.confirmBtn addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    self.confirmBtn.hidden = YES;
    [self.view addSubview:self.confirmBtn];

    // 重拍 (Pencil: 24×24 透明背景 refresh 图标 #2a2a2a, 居中偏右)
    // 相机预览背景是黑色, 用白色保证可视 — 在 Pencil 浅灰设计稿上是 #2a2a2a, 这里换设备背景做最小适配
    CGFloat retakeSize = kScaleW(48);
    self.retakeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.retakeBtn.frame = CGRectMake(kScreenWidth * 0.5 + dualOffset - retakeSize * 0.5,
                                       shutterCenterY - retakeSize * 0.5,
                                       retakeSize, retakeSize);
    self.retakeBtn.backgroundColor = [UIColor clearColor];
    UIImageSymbolConfiguration *rcfg = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightRegular];
    [self.retakeBtn setImage:[[UIImage systemImageNamed:@"arrow.clockwise" withConfiguration:rcfg]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                    forState:UIControlStateNormal];
    self.retakeBtn.tintColor = kColorWhite;
    [self.retakeBtn addTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
    self.retakeBtn.hidden = YES;
    [self.view addSubview:self.retakeBtn];
}

#pragma mark - Capture

- (void)snap {
    if (!self.photoOutput) {
        // 模拟器 fallback: 用截屏代替
        [self handleCapturedImage:[self snapshotPreview]];
        return;
    }
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    [self.photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhoto:(AVCapturePhoto *)photo
                error:(NSError *)error {
    NSData *data = [photo fileDataRepresentation];
    UIImage *img = data ? [UIImage imageWithData:data] : nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleCapturedImage:img];
    });
}

- (UIImage *)snapshotPreview {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
    [self.previewLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)handleCapturedImage:(UIImage *)img {
    self.capturedImage = img;
    if (img) {
        self.previewImageView.image = img;
        self.previewImageView.hidden = NO;
    }
    // 照搬 334: 拍照瞬间快照当前 orientation
    self.capturedDeviceOrientation = self.currentDeviceOrientation;
    self.captured = YES;
    self.shutter.hidden = YES;
    self.retakeBtn.hidden = NO;
    self.confirmBtn.hidden = NO;
    [self stopSession];
}

- (void)retake {
    self.captured = NO;
    self.capturedImage = nil;
    self.previewImageView.image = nil;
    self.previewImageView.hidden = YES;
    self.shutter.hidden = NO;
    self.retakeBtn.hidden = YES;
    self.confirmBtn.hidden = YES;
    [self startSession];
}

- (void)confirm {
    if (self.onImageCaptured) {
        // 照搬 334: 优先用拍照瞬间方向, faceUp/faceDown/unknown 兜底当前/Portrait
        UIDeviceOrientation orientation = self.capturedDeviceOrientation;
        if (orientation == UIDeviceOrientationUnknown ||
            orientation == UIDeviceOrientationFaceUp ||
            orientation == UIDeviceOrientationFaceDown) {
            orientation = self.currentDeviceOrientation;
        }
        if (orientation == UIDeviceOrientationUnknown) {
            orientation = UIDeviceOrientationPortrait;
        }
        self.onImageCaptured(self.capturedImage, orientation);
        // 照搬 334: present 出来的相机用 dismiss 关闭
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    // 兜底 (无 callback 时): 旧流程 push Liveness
    [self.navigationController pushViewController:[MKKYCLivenessViewController new] animated:YES];
}

- (void)closeTap {
    // 照搬 334: present 出来的相机用 dismiss 关闭
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopMonitoringOrientation];
    [self stopSession];
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

#pragma mark - Orientation (照搬 334 RDKYC5)

- (void)startMonitoringOrientation {
    [self stopMonitoringOrientation];
    if (!self.motionManager) self.motionManager = [[CMMotionManager alloc] init];
    if (self.motionManager.deviceMotionAvailable) {
        self.motionManager.deviceMotionUpdateInterval = 0.2;
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                                withHandler:^(CMDeviceMotion *motion, NSError *error) {
            if (!motion) return;
            [weakSelf updateOrientationWithGravityX:motion.gravity.x y:motion.gravity.y];
        }];
    }
}

- (void)stopMonitoringOrientation {
    if (self.motionManager.deviceMotionActive) {
        [self.motionManager stopDeviceMotionUpdates];
    }
}

- (void)updateOrientationWithGravityX:(double)x y:(double)y {
    UIDeviceOrientation orientation;
    if (fabs(y) >= fabs(x)) {
        orientation = (y >= 0) ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
    } else {
        orientation = (x >= 0) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationLandscapeRight;
    }
    self.currentDeviceOrientation = orientation;
}

@end
