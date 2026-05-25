//
//  MKHomeProductCell.m
//

#import "MKHomeProductCell.h"
#import "MKConstants.h"
#import "MKHomeProductCardView.h"
#import <Masonry/Masonry.h>

@interface MKHomeProductCell ()
@property (nonatomic, strong) MKHomeProductCardView *card;
@end

@implementation MKHomeProductCell

+ (CGFloat)rowHeight { return kScaleH(126 + 12); }    // 卡 126 + 间距 12 (Figma: card1.y=450, card2.y=588)

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.card = [[MKHomeProductCardView alloc]
            initWithFrame:CGRectMake(0, 0, kScaleW(339), kScaleH(126))];
        [self.contentView addSubview:self.card];
        [self.card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(kScaleW(18));
            make.right.equalTo(self.contentView).offset(-kScaleW(18));
            make.top.equalTo(self.contentView);
            make.height.mas_equalTo(kScaleH(126));
        }];

        __weak typeof(self) wself = self;
        self.card.onApplyTapped = ^{ if (wself.onApplyTapped) wself.onApplyTapped(); };
    }
    return self;
}

- (void)configureName:(NSString *)name quota:(NSString *)quota rate:(NSString *)rate logoUrl:(NSString *)logoUrl {
    self.card.productName  = name  ?: @"";
    self.card.quotaRange   = quota ?: @"";
    self.card.interestRate = rate  ?: @"";
    self.card.logoUrl      = logoUrl;
}

@end
