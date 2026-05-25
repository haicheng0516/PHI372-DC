//
//  MKHomeViewController.h
//  PHI372-DC
//
//  统一首页 - 替代 MKHomeBeforeKYC + MKHomeAfterKYC
//  按 /user/suphome 返回的 userStatus 切 cell:
//    userStatus == 10 → showEmpty=YES → 装饰图 + 底部 Apply Now
//    其他            → showEmpty=NO  → 产品列表
//

#import "MKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKHomeViewController : MKBaseViewController
@end

NS_ASSUME_NONNULL_END
