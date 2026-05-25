//
//  MKFeedbackDescCell.m
//  PHI372-DC
//

#import "MKFeedbackDescCell.h"
#import "MKConstants.h"

@implementation MKFeedbackDescCell

+ (CGFloat)cellHeight {
    return kScaleH(54) + kScaleH(20);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = kColorBackground;
        self.backgroundColor = kColorBackground;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // Pencil l9LvDD: PingFang SC 14 normal #999999, width 303
        UILabel *desc = [UILabel new];
        desc.text = @"The results of your credit assessment will determine your loan limit; having good credit can provide you with greater borrowing power.";
        desc.font = kFontRegular(14);
        desc.textColor = MKHexColor(0x999999);
        desc.numberOfLines = 0;
        desc.tag = 801;
        [self.contentView addSubview:desc];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UILabel *desc = (UILabel *)[self.contentView viewWithTag:801];
    // Pencil 36,586 → cell 内 x=36, y=10
    desc.frame = CGRectMake(kScaleW(36), kScaleH(10), kScaleW(303), kScaleH(54));
}

@end
