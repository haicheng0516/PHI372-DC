//
//  MKHomeDecorationCell.m
//

#import "MKHomeDecorationCell.h"
#import "MKConstants.h"
#import <Masonry/Masonry.h>

@interface MKHomeDecorationCell ()
@property (nonatomic, strong) UIImageView *imageView_;
@end

@implementation MKHomeDecorationCell

+ (CGFloat)rowHeight { return kScaleH(100); }   // Figma: partners 459..535 = 76, +24 padding

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView_ = [[UIImageView alloc] init];
        self.imageView_.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.imageView_];
        [self.imageView_ mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.centerY.equalTo(self.contentView);
            make.width.mas_equalTo(kScaleW(159));   // Figma 装饰图 159×76
            make.height.mas_equalTo(kScaleH(76));
        }];
    }
    return self;
}

- (void)configureImage:(NSString *)imageName {
    self.imageView_.image = [UIImage imageNamed:imageName];
}

@end
