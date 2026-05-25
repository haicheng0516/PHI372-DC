//
//  MKOrderDetailCard.m
//

#import "MKOrderDetailCard.h"
#import "MKConstants.h"

@interface MKOrderDetailCard ()
@property (nonatomic, strong) UILabel *cardNumberLabel;
@property (nonatomic, strong) NSMutableArray<UILabel *> *labels;
@property (nonatomic, strong) NSMutableArray<UILabel *> *values;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *breakAfterIndexes;
@end

@implementation MKOrderDetailCard

+ (CGFloat)heightForRowCount:(NSInteger)rowCount breakCount:(NSInteger)breakCount {
    // 顶部 22pt padding (含卡号) + 分割线 + rows * 30 + breakCount * 18 + 14 bottom
    return kScaleH(22) + kScaleH(1) + kScaleH(rowCount * 30) + kScaleH(breakCount * 18) + kScaleH(14);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = MKHexColor(0xE9E9E4);
        self.layer.cornerRadius = kScaleH(14);
        self.clipsToBounds = YES;
        _labels = [NSMutableArray array];
        _values = [NSMutableArray array];
        _breakAfterIndexes = [NSMutableArray array];

        _cardNumberLabel = [UILabel new];
        _cardNumberLabel.font = kFontRegular(14);
        _cardNumberLabel.textColor = MKHexColor(0x333333);
        _cardNumberLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_cardNumberLabel];
    }
    return self;
}

- (void)setCardNumber:(NSString *)cardNumber {
    _cardNumber = [cardNumber copy];
    self.cardNumberLabel.text = cardNumber;
    [self setNeedsLayout];
}

- (void)setRows:(NSArray<NSArray<NSString *> *> *)rows {
    for (UILabel *l in self.labels) [l removeFromSuperview];
    for (UILabel *v in self.values) [v removeFromSuperview];
    [self.labels removeAllObjects];
    [self.values removeAllObjects];

    for (NSArray<NSString *> *row in rows) {
        UILabel *l = [UILabel new];
        l.text = row[0];
        l.font = kFontRegular(14);
        l.textColor = MKHexColor(0x999999);
        [self addSubview:l];
        [self.labels addObject:l];

        UILabel *v = [UILabel new];
        v.text = row.count > 1 ? row[1] : @"";
        v.font = kFontSemibold(14);
        v.textColor = MKHexColor(0x333333);
        v.textAlignment = NSTextAlignmentRight;
        [self addSubview:v];
        [self.values addObject:v];
    }
    [self setNeedsLayout];
}

- (void)addBreakAfterRowIndex:(NSInteger)idx {
    [self.breakAfterIndexes addObject:@(idx)];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    // 卡号 右上 (201-18, 315-293) = (183, 22) 138×20
    self.cardNumberLabel.frame = CGRectMake(W - kScaleW(180), kScaleH(22), kScaleW(160), kScaleH(20));

    // 顶部分割线 (37-18, 352-293) = (19, 59) 301×1
    // (虚拟绘制 — 通过下方 row 上方 padding 实现)
    CGFloat rowH = kScaleH(30);
    CGFloat y = kScaleH(60);   // first row baseline ~y=60
    NSSet *breaks = [NSSet setWithArray:self.breakAfterIndexes];
    for (NSInteger i = 0; i < self.labels.count; i++) {
        self.labels[i].frame  = CGRectMake(kScaleW(18), y, kScaleW(180), rowH);
        self.values[i].frame  = CGRectMake(W * 0.5, y, W * 0.5 - kScaleW(18), rowH);
        y += rowH;
        if ([breaks containsObject:@(i)]) {
            // 画一条分割线
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(19), y + kScaleH(8), W - kScaleW(38), 1)];
            line.backgroundColor = MKHexColor(0xD1D1CF);
            [self addSubview:line];
            y += kScaleH(18);
        }
    }

    // 顶部固定分割线 (放在 y=58)
    static const NSInteger kTopDividerTag = 8888;
    UIView *topLine = [self viewWithTag:kTopDividerTag];
    if (!topLine) {
        topLine = [[UIView alloc] init];
        topLine.tag = kTopDividerTag;
        topLine.backgroundColor = MKHexColor(0xD1D1CF);
        [self addSubview:topLine];
    }
    topLine.frame = CGRectMake(kScaleW(19), kScaleH(58), W - kScaleW(38), 1);
}

@end
