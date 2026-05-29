//
//  MKLoanApplyBottomBar.h
//  Pencil b4hMw0: 底部 fixed 区
//
//  布局 (Pencil 坐标):
//    Radio (36, 662) 16×16
//    Terms text (58, 657) 280×36 — "I have read and agreed with the Terms of the loans"
//    Apply Now btn (36, 705) 303×56 r=28 #385330
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKLoanApplyBottomBar : UIView

@property (nonatomic, assign) BOOL termsAccepted;   // 默认 NO
@property (nonatomic, copy, nullable) void(^onTermsTapped)(void);
@property (nonatomic, copy, nullable) void(^onCheckboxTapped)(void);
@property (nonatomic, copy, nullable) void(^onApplyTapped)(void);

+ (CGFloat)barHeight;   // 不含 safeArea

@end

NS_ASSUME_NONNULL_END
