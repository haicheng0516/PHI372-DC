//
//  MKKYCProgressBarView.m
//

#import "MKKYCProgressBarView.h"
#import "MKConstants.h"

@interface MKKYCProgressBarView ()
@property (nonatomic, strong) UIView *track;           // 浅底胶囊
@property (nonatomic, strong) UIView *fill;            // 深色填充
@property (nonatomic, strong) UIImageView *patternView; // 条纹覆盖 (placeholder, 待替换)
@end

@implementation MKKYCProgressBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _totalSteps = 4;     // KYC 固定 4 步
        _currentStep = 1;
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    // Pencil 精确: 整条胶囊深绿底 #385330, 内部走黄绿斜条纹 #BBCB2F (条纹素材未到, 用纯填色占位)
    self.track = [UIView new];
    self.track.backgroundColor = kColorPrimary;          // #385330
    self.track.layer.masksToBounds = YES;
    [self addSubview:self.track];

    // fill: 黄绿色, 撑到当前进度
    self.fill = [UIView new];
    self.fill.backgroundColor = MKHexColor(0xBBCB2F);   // 黄绿
    self.fill.layer.masksToBounds = YES;
    [self.track addSubview:self.fill];

    // 条纹层 (待替换为真实条纹图)
    self.patternView = [UIImageView new];
    self.patternView.backgroundColor = [UIColor clearColor];
    self.patternView.contentMode = UIViewContentModeScaleToFill;
    self.patternView.userInteractionEnabled = NO;
    [self.track addSubview:self.patternView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    self.track.frame = self.bounds;
    self.track.layer.cornerRadius = H * 0.5;

    NSInteger total = MAX(self.totalSteps, 1);
    NSInteger cur = MAX(0, MIN(self.currentStep, total));
    CGFloat p = (CGFloat)cur / (CGFloat)total;     // 1/4=0.25, 2/4=0.5, 3/4=0.75, 4/4=1.0
    CGFloat fillW = MAX(H, p * W);                  // 至少撑满胶囊一头, 避免成竖条
    self.fill.frame = CGRectMake(0, 0, fillW, H);
    self.fill.layer.cornerRadius = H * 0.5;

    self.patternView.frame = self.track.bounds;
}

- (void)setCurrentStep:(NSInteger)currentStep {
    _currentStep = currentStep;
    [self setNeedsLayout];
}

- (void)setTotalSteps:(NSInteger)totalSteps {
    _totalSteps = totalSteps;
    [self setNeedsLayout];
}

- (void)setStripePattern:(UIImage *)stripePattern {
    _stripePattern = stripePattern;
    self.patternView.image = stripePattern ? [stripePattern resizableImageWithCapInsets:UIEdgeInsetsZero
                                                                           resizingMode:UIImageResizingModeTile]
                                            : nil;
}

@end
