//
//  MKHomeHeaderView.m
//

#import "MKHomeHeaderView.h"
#import "MKConstants.h"
#import "MKGradientBackgroundView.h"
#import "MKHomeBannerView.h"

@interface MKHomeHeaderView ()
@property (nonatomic, strong) MKGradientBackgroundView *gradient;
@property (nonatomic, strong) MKHomeBannerView *banner;
@property (nonatomic, strong) MKHomeIconGridView *iconGrid;
@end

@implementation MKHomeHeaderView

+ (CGFloat)height { return kScaleH(362); }   // Figma: notice card 顶部 y=362, 留出 iconGrid 双行 label (Bank/Account) 溢出区

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.height == 0) frame.size.height = [MKHomeHeaderView height];
    if (frame.size.width  == 0) frame.size.width  = kScreenWidth;
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kColorBackground;
        // gradient 占满 header (frame 已经界定大小, 不需要 clipsToBounds);
        // iconGrid 内 label 多行需溢出 header 显示, 所以 header 不能 clipsToBounds
        self.gradient = [[MKGradientBackgroundView alloc]
            initWithFrame:CGRectMake(0, 0, kScreenWidth, frame.size.height)];
        [self addSubview:self.gradient];

        // Banner (Figma 18,79,339×153)
        self.banner = [[MKHomeBannerView alloc]
            initWithFrame:CGRectMake(kScaleW(18), kScaleH(79), kScaleW(339), kScaleH(153))];
        [self addSubview:self.banner];

        // Icon Grid (Figma 38,255,283×80)
        self.iconGrid = [[MKHomeIconGridView alloc]
            initWithFrame:CGRectMake(kScaleW(38), kScaleH(255), kScaleW(283), kScaleH(80))];
        __weak typeof(self) wself = self;
        self.iconGrid.onIconTapped = ^(MKHomeIconKind kind) {
            if (wself.onIconTapped) wself.onIconTapped(kind);
        };
        [self addSubview:self.iconGrid];
    }
    return self;
}

@end
