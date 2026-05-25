//
//  MKNavBar.m
//  PHI372-DC
//

#import "MKNavBar.h"
#import "MKConstants.h"

@interface MKNavBar ()
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, copy) void(^backActionBlock)(void);
@end

@implementation MKNavBar

- (instancetype)initWithFrame:(CGRect)frame {
    CGFloat statusH = mk_keyWindow().safeAreaInsets.top ?: 54;
    CGFloat totalH = statusH + 44.0;
    self = [super initWithFrame:CGRectMake(0, 0, frame.size.width ?: UIScreen.mainScreen.bounds.size.width, totalH)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupSubviews:statusH];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)setupSubviews:(CGFloat)statusH {
    // Background image (covers status bar + nav bar)
    self.bgImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.bgImageView.image = [UIImage imageNamed:@"gsssss_xq_bg"];
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.bgImageView.clipsToBounds = YES;
    self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.bgImageView];

    // Back button
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backButton.frame = CGRectMake(10, statusH + 2, 40, 40);
    UIImage *backImg = [UIImage imageNamed:@"gsssss_xq_fh"];
    [self.backButton setImage:backImg forState:UIControlStateNormal];
    self.backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.backButton.hidden = YES;
    [self.backButton addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backButton];

    // Title
    CGFloat screenW = self.bounds.size.width;
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, statusH + 2, screenW - 120, 40)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.titleLabel];
}

- (CGFloat)barHeight {
    return self.bounds.size.height;
}

#pragma mark - Public

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)setTitle:(NSString *)title color:(UIColor *)color {
    self.titleLabel.text = title;
    if (color) self.titleLabel.textColor = color;
}

- (void)showBackButton {
    self.backButton.hidden = NO;
}

- (void)hideBackButton {
    self.backButton.hidden = YES;
}

- (void)setBackAction:(void (^)(void))action {
    self.backActionBlock = action;
}

- (void)setTheme:(MKNavBarTheme)theme {
    _theme = theme;
    switch (theme) {
        case MKNavBarThemeDark:
            self.titleLabel.textColor = [UIColor whiteColor];
            break;
        case MKNavBarThemeLight:
            self.titleLabel.textColor = [UIColor whiteColor];
            break;
        case MKNavBarThemeTransparent:
            self.titleLabel.hidden = YES;
            self.backButton.hidden = YES;
            break;
    }
}

#pragma mark - Actions

- (void)backTapped {
    if (self.backActionBlock) {
        self.backActionBlock();
    }
}

@end
