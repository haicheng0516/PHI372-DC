//
//  MKActionButton.m
//

#import "MKActionButton.h"
#import "MKConstants.h"

@implementation MKActionButton

+ (instancetype)buttonWithTitle:(NSString *)title {
    MKActionButton *btn = [MKActionButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    btn.backgroundColor = kColorOrange;
    btn.layer.cornerRadius = 20;
    btn.clipsToBounds = YES;
    return btn;
}

- (void)pinToBottomOfView:(UIView *)superview {
    [superview addSubview:self];
    CGFloat w = superview.bounds.size.width;
    CGFloat safeBottom = mk_keyWindow().safeAreaInsets.bottom;
    CGFloat y = superview.bounds.size.height - 64 - 20 - safeBottom;
    self.frame = CGRectMake(20, y, w - 40, 64);
}

- (void)addToView:(UIView *)superview atY:(CGFloat)y {
    [superview addSubview:self];
    CGFloat w = superview.bounds.size.width;
    self.frame = CGRectMake(20, y, w - 40, 64);
}

@end
