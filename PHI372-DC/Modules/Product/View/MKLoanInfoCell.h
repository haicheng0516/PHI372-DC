//
//  MKLoanInfoCell.h
//  Pencil b4hMw0 (产品申请-多) / LbSVz (产品申请-单)
//
//  Loan details 整页 cell, 两层卡片堆叠 + 组装可复用子组件:
//    底层 MKLoanProductHeroView (Hero 绿卡, 跨页面复用)
//    覆盖层 奶白圆角大卡 #E9E9E4 (容器, 本页特有)
//      内: 银行卡子卡 + MKDetailRowsView + MKRepaymentPlanButton + Disclaimer + Radio+Terms + Apply Now
//

#import <UIKit/UIKit.h>
@class MKLoanProductModel;

NS_ASSUME_NONNULL_BEGIN

@interface MKLoanInfoCell : UITableViewCell

/// 协议是否已勾选
@property (nonatomic, assign, readonly) BOOL termsAccepted;

/// 一次性灌入数据 (替代之前的 configureHeroAppName: / configureBankAccount: / configureAmountReceived:)
- (void)configureWithProduct:(MKLoanProductModel *)product;

/// 行高
+ (CGFloat)cellHeight;

/// 用户操作回调
@property (nonatomic, copy, nullable) void(^onAmountSubLabelTapped)(UIView *anchor);   // Hero sub label
@property (nonatomic, copy, nullable) void(^onTermCapsuleTapped)(void);                // Hero 胶囊 (multi only)
@property (nonatomic, copy, nullable) void(^onAmountChevronTapped)(void);              // Hero 金额白圆 (multi only)
@property (nonatomic, copy, nullable) void(^onAccountTapped)(void);                    // 银行卡子卡
@property (nonatomic, copy, nullable) void(^onAmountInfoTapped)(NSInteger row, UIView *anchor);
@property (nonatomic, copy, nullable) void(^onRepaymentPlanTapped)(void);
@property (nonatomic, copy, nullable) void(^onTermsLinkTapped)(void);
@property (nonatomic, copy, nullable) void(^onApplyTapped)(void);

@end

NS_ASSUME_NONNULL_END
