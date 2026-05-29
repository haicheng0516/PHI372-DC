//
//  MKBaseTableViewCell.m
//

#import "MKBaseTableViewCell.h"

@implementation MKBaseTableViewCell

+ (NSString *)cellIdentifier {
    return NSStringFromClass(self);
}

+ (void)registerForTableView:(UITableView *)tableView {
    [tableView registerClass:self forCellReuseIdentifier:[self cellIdentifier]];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.separatorInset = UIEdgeInsetsMake(0, 0, 0, UIScreen.mainScreen.bounds.size.width);
    }
    return self;
}

@end
