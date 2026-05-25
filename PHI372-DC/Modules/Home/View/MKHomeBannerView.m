//
//  MKHomeBannerView.m
//  PHI372-DC
//
//  Figma 26:4355 Se_banner — 直接用 PNG 包含全部内容(标题/胶囊/箭头/插画/副标题)
//

#import "MKHomeBannerView.h"
#import "MKConstants.h"

@implementation MKHomeBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Pencil Rectangle 4218: fill #252f2c, cornerRadius 14 (fixed, not relative)
        self.backgroundColor = MKHexColor(0x252F2C);
        self.layer.cornerRadius = kScaleH(14);
        self.clipsToBounds = YES;
        UIImageView *img = [[UIImageView alloc] initWithFrame:self.bounds];
        img.image = [UIImage imageNamed:@"mk_home_banner"];
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.layer.cornerRadius = kScaleH(14);
        img.clipsToBounds = YES;
        img.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:img];
    }
    return self;
}

@end
