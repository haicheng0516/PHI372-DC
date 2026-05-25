//
//  MKBankCardView.h
//  PHI372-DC
//  银行卡渐变卡片组件
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKBankCardView : UIView

@property (nonatomic, copy, nullable) void(^deleteBlock)(void);
@property (nonatomic, copy, nullable) void(^editBlock)(void);
@property (nonatomic, copy, nullable) void(^defaultBlock)(void);
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) BOOL showDeleteButton;
@property (nonatomic, assign) BOOL showEditButton;
@property (nonatomic, assign) BOOL showDefaultToggle;

- (void)setBankName:(NSString *)bankName
        accountName:(NSString *)accountName
         cardNumber:(NSString *)cardNumber
               ifsc:(NSString *)ifsc;

/// 推荐高度
+ (CGFloat)preferredHeight;

@end

NS_ASSUME_NONNULL_END
