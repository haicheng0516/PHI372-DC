//
//  MKHomeProductCardView.h
//  PHI372-DC
//
//  首页(KYC 后) 产品卡片 - 339x126
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeProductCardView : UIView
@property (nonatomic, copy) NSString *productName;     // 接口 productName
@property (nonatomic, copy) NSString *quotaRange;      // ₱ {low}-{high}
@property (nonatomic, copy) NSString *interestRate;    // {rate} %
@property (nonatomic, copy, nullable) NSString *logoUrl;  // 接口 productLogo URL, 渲染到左下色块位置
@property (nonatomic, copy, nullable) void (^onApplyTapped)(void);
@end

NS_ASSUME_NONNULL_END
