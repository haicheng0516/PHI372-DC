//
//  MKHomeIconGridView.h
//  PHI372-DC
//
//  首页 4 个圆形 icon 阵列(Contact / Bank / Order / Me)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKHomeIconKind) {
    MKHomeIconKindContact,
    MKHomeIconKindBank,
    MKHomeIconKindOrder,
    MKHomeIconKindMe,
};

@interface MKHomeIconGridView : UIView
@property (nonatomic, copy, nullable) void (^onIconTapped)(MKHomeIconKind kind);
@end

NS_ASSUME_NONNULL_END
