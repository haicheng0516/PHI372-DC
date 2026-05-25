//
//  MKHomeNoticeCell.m
//

#import "MKHomeNoticeCell.h"
#import "MKConstants.h"
#import "MKHomeKYCTipCardView.h"
#import <Masonry/Masonry.h>

@interface MKHomeNoticeCell ()
@property (nonatomic, strong) MKHomeKYCTipCardView *tipCard;
@end

@implementation MKHomeNoticeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.tipCard = [[MKHomeKYCTipCardView alloc] init];
        [self.contentView addSubview:self.tipCard];
        [self.tipCard mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(kScaleW(18));
            make.right.equalTo(self.contentView).offset(-kScaleW(18));
            make.top.equalTo(self.contentView).offset(0);
            make.bottom.equalTo(self.contentView).offset(-kScaleH(12));
        }];
    }
    return self;
}

- (void)configureWithText:(NSString *)text {
    self.tipCard.tipText = text;
}

@end
