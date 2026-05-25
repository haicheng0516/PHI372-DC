//
//  MKDocCardView.m
//

#import "MKDocCardView.h"
#import "MKConstants.h"

@interface MKDocCardView ()
@property (nonatomic, strong) UILabel *sectionTitleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, copy) NSString *sectionTitle;
@property (nonatomic, copy) NSString *body;
@end

@implementation MKDocCardView

+ (CGFloat)heightForSectionTitle:(NSString *)sectionTitle body:(NSString *)body {
    CGFloat width = kScaleW(339) - kScaleW(32);   // 16 左右 padding
    CGFloat top = kScaleH(14);
    CGFloat h = top;
    if (sectionTitle.length) {
        h += kScaleH(20) + kScaleH(10);  // section title 20h + 10 gap
    }
    UIFont *bodyFont = [UIFont systemFontOfSize:kScaleW(14)];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineSpacing = kScaleH(6);
    CGFloat bodyH = [body ?: @"" boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{ NSFontAttributeName: bodyFont, NSParagraphStyleAttributeName: style }
                                              context:nil].size.height;
    h += ceilf(bodyH) + kScaleH(14);
    return h;
}

- (instancetype)initWithSectionTitle:(NSString *)sectionTitle body:(NSString *)body {
    if (self = [super init]) {
        self.backgroundColor = MKHexColor(0xE9E9E4);
        self.layer.cornerRadius = kScaleH(14);
        _sectionTitle = [sectionTitle copy];
        _body = [body copy];

        if (sectionTitle.length) {
            _sectionTitleLabel = [UILabel new];
            _sectionTitleLabel.text = sectionTitle;
            _sectionTitleLabel.font = kFontSemibold(14);
            _sectionTitleLabel.textColor = MKHexColor(0x171718);
            [self addSubview:_sectionTitleLabel];
        }

        _bodyLabel = [UILabel new];
        _bodyLabel.font = kFontRegular(14);
        _bodyLabel.textColor = MKHexColor(0x666666);
        _bodyLabel.numberOfLines = 0;
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineSpacing = kScaleH(6);
        _bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:body ?: @""
                                                                    attributes:@{ NSFontAttributeName: _bodyLabel.font,
                                                                                  NSForegroundColorAttributeName: _bodyLabel.textColor,
                                                                                  NSParagraphStyleAttributeName: style }];
        [self addSubview:_bodyLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat pad = kScaleW(16);
    CGFloat y = kScaleH(14);
    if (self.sectionTitleLabel) {
        self.sectionTitleLabel.frame = CGRectMake(pad, y, W - pad * 2, kScaleH(20));
        y += kScaleH(20) + kScaleH(10);
    }
    self.bodyLabel.frame = CGRectMake(pad, y, W - pad * 2, self.bounds.size.height - y - kScaleH(14));
}
@end
