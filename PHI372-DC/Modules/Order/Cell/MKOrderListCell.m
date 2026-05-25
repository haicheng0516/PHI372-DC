//
//  MKOrderListCell.m
//

#import "MKOrderListCell.h"
#import "MKConstants.h"

@interface MKOrderListCell ()
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *dueLabel;
@end

@implementation MKOrderListCell

+ (CGFloat)cellHeight { return kScaleH(116); }

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.card = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(18), kScaleH(8), kScreenWidth - kScaleW(36), kScaleH(100))];
        self.card.backgroundColor = kColorCardBg; self.card.layer.cornerRadius = kScaleH(14);
        [self.contentView addSubview:self.card];

        self.amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(20), kScaleH(20), kScaleW(220), kScaleH(34))];
        self.amountLabel.font = kFontBold(22); self.amountLabel.textColor = kColorTextPrimary;
        [self.card addSubview:self.amountLabel];

        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.card.frame.size.width - kScaleW(120), kScaleH(20), kScaleW(100), kScaleH(28))];
        self.statusLabel.font = kFontSemibold(13);
        self.statusLabel.textAlignment = NSTextAlignmentRight;
        [self.card addSubview:self.statusLabel];

        self.dueLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(20), kScaleH(64), self.card.frame.size.width - kScaleW(40), kScaleH(20))];
        self.dueLabel.font = kFontRegular(13); self.dueLabel.textColor = kColorTextSecondary;
        [self.card addSubview:self.dueLabel];
    }
    return self;
}

- (void)configureAmount:(NSString *)amount status:(NSString *)status dueDate:(NSString *)due statusColor:(UIColor *)c {
    self.amountLabel.text = amount;
    self.statusLabel.text = status;
    self.statusLabel.textColor = c;
    self.dueLabel.text = due;
}

@end
