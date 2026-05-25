//
//  MKResultView.h
//  PHI372-DC — Figma 3:1394 申请成功 / 3:1509 好评成功 / 3:1441 注销成功 / 3:1468 失败 通用 ResultView
//
//  布局:
//    顶部 Hero icon (68×60 或 187 大插画)
//    标题: "Success!" / "Failed!" / 自定义, PingFang SC 600 20pt center
//    副标题: 14pt #666666 lh 1.5 center
//    主 CTA: " Confirm" or 自定义, 303×56 r=28 #385330 white
//    可选次 CTA
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MKResultKind) {
    MKResultKindSuccess,
    MKResultKindFailure,
    MKResultKindHint,
};

@interface MKResultView : UIView
@property (nonatomic, copy) void (^onPrimaryTapped)(void);
@property (nonatomic, copy) void (^onSecondaryTapped)(void);

- (instancetype)initWithKind:(MKResultKind)kind
                       title:(NSString *)title
                    subtitle:(NSString *)subtitle
                primaryTitle:(NSString *)primaryTitle
              secondaryTitle:(nullable NSString *)secondaryTitle;
@end

NS_ASSUME_NONNULL_END
