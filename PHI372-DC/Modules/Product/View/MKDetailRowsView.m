//
//  MKDetailRowsView.m
//

#import "MKDetailRowsView.h"
#import "MKConstants.h"

// 行间距 (Pencil 平均 ≈ 10pt)
static const CGFloat kRowSpacing = 10.0;

@interface MKDetailRowsView ()
@property (nonatomic, strong) NSArray<MKDetailRow *> *rows;
@end

@implementation MKDetailRowsView

+ (CGFloat)viewHeightForCount:(NSInteger)count {
    if (count <= 0) return 0;
    return [MKDetailRow rowHeight] * count + kScaleH(kRowSpacing) * (count - 1);
}

- (instancetype)initWithRowConfigs:(NSArray<NSDictionary *> *)configs {
    if (self = [super initWithFrame:CGRectZero]) {
        NSMutableArray *arr = [NSMutableArray array];
        for (NSDictionary *cfg in configs) {
            NSString *label = cfg[@"label"];
            BOOL hasInfo = [cfg[@"hasInfo"] boolValue];
            MKDetailRow *row = [[MKDetailRow alloc] initWithLabel:label hasInfoIcon:hasInfo];
            row.tag = arr.count;
            __weak typeof(self) wself = self;
            row.onInfoTapped = ^(UIView *anchor) {
                if (wself.onInfoTapped) wself.onInfoTapped(row.tag, anchor);
            };
            [self addSubview:row];
            [arr addObject:row];
        }
        _rows = arr;
    }
    return self;
}

- (void)setValues:(NSArray<NSString *> *)values {
    for (NSInteger i = 0; i < self.rows.count && i < values.count; i++) {
        self.rows[i].value = values[i];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat rowH = [MKDetailRow rowHeight];
    CGFloat spacing = kScaleH(kRowSpacing);
    for (NSInteger i = 0; i < self.rows.count; i++) {
        CGFloat y = i * (rowH + spacing);
        self.rows[i].frame = CGRectMake(0, y, W, rowH);
    }
}

@end
