//
//  MKKYCItemModel.m
//

#import "MKKYCItemModel.h"

@implementation MKKYCButtonModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _buttonKey = [NSString stringWithFormat:@"%@", dict[@"buttonKey"] ?: @""];
        _buttonLabel = [NSString stringWithFormat:@"%@", dict[@"buttonLabel"] ?: @""];
        _buttonSort = [dict[@"buttonSort"] integerValue];
    }
    return self;
}

@end

@implementation MKKYCItemModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    self = [super init];
    if (self) {
        _itemCode = [NSString stringWithFormat:@"%@", dict[@"itemCode"] ?: @""];
        _itemName = [NSString stringWithFormat:@"%@", dict[@"itemName"] ?: @""];
        _itemType = [dict[@"itemType"] integerValue];
        _itemSort = [dict[@"itemSort"] integerValue];
        _itemStatus = [dict[@"itemStatus"] integerValue];
        _regularExpression = dict[@"regularExpression"];
        _isRequired = [dict[@"isRequired"] integerValue];
        _frontPrompts = dict[@"frontPrompts"];
        _rearPrompts = dict[@"rearPrompts"];
        _selectedIndex = -1;

        NSArray *btnArr = dict[@"buttonList"];
        if ([btnArr isKindOfClass:[NSArray class]]) {
            NSMutableArray *btns = [NSMutableArray array];
            for (NSDictionary *d in btnArr) {
                MKKYCButtonModel *btn = [[MKKYCButtonModel alloc] initWithDictionary:d];
                if (btn) [btns addObject:btn];
            }
            [btns sortUsingComparator:^NSComparisonResult(MKKYCButtonModel *a, MKKYCButtonModel *b) {
                return a.buttonSort - b.buttonSort;
            }];
            _buttonList = [btns copy];
        } else {
            _buttonList = @[];
        }
    }
    return self;
}

- (BOOL)isPickerType {
    return self.itemType != 1;
}

+ (instancetype)inputItemWithCode:(NSString *)code name:(NSString *)name required:(BOOL)required {
    MKKYCItemModel *item = [[MKKYCItemModel alloc] init];
    item.itemCode = code;
    item.itemName = name;
    item.itemType = 1;
    item.isRequired = required ? 1 : 0;
    item.selectedIndex = -1;
    item.buttonList = @[];
    return item;
}

+ (instancetype)pickerItemWithCode:(NSString *)code name:(NSString *)name options:(NSArray<NSString *> *)options required:(BOOL)required {
    MKKYCItemModel *item = [[MKKYCItemModel alloc] init];
    item.itemCode = code;
    item.itemName = name;
    item.itemType = 3;
    item.isRequired = required ? 1 : 0;
    item.selectedIndex = -1;

    NSMutableArray *btns = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)options.count; i++) {
        MKKYCButtonModel *btn = [[MKKYCButtonModel alloc] init];
        btn.buttonKey = options[i];
        btn.buttonLabel = options[i];
        btn.buttonSort = i;
        [btns addObject:btn];
    }
    item.buttonList = [btns copy];
    return item;
}

@end
