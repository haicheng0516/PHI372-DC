//
//  MKBankCardItemView.h
//  PHI372-DC — Figma 3:1188 银行卡 cell (339×171)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKBankCardItemView : UIView
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *cardNumber;
@property (nonatomic, copy) NSString *holderName;
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, copy, nullable) void (^onSelected)(void);
@property (nonatomic, copy, nullable) void (^onSubmitTapped)(void);
+ (CGFloat)cardHeight;   // 171
@end

NS_ASSUME_NONNULL_END
