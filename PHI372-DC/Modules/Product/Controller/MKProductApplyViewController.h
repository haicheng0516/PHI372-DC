//  MKProductApplyViewController.h
//  UI 走 Pencil 372:
//    - 多金额: Hero amount chevron + picker (Pencil b4hMw0)
//    - 单金额: Hero amount 静态文本, 无 chevron     (Pencil LbSVz)
//  term picker 独立按 当前 amount.termDetailList.count > 1 决定可点

#import "MKBaseViewController.h"
@class MKProductTermDataModel;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKLoanAmountSelectionMode) {
    MKLoanAmountSelectionModeSingle = 0,
    MKLoanAmountSelectionModeMultiple
};

@interface MKProductApplyViewController : MKBaseViewController

@property (nonatomic, strong, nullable) MKProductTermDataModel *termData;
@property (nonatomic, assign) MKLoanAmountSelectionMode selectionMode;

- (instancetype)initWithTermData:(MKProductTermDataModel *)termData
                            mode:(MKLoanAmountSelectionMode)mode;

@end

NS_ASSUME_NONNULL_END
