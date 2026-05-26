//
//  MKBottomSheetView.h
//  PHI372-DC
//
//  22 个底部弹窗统一实现 — 单类 + 枚举区分,从底部 slide-up 弹出。
//  用户决策:不用页面中心弹窗,所有 modal 改 bottom sheet 形式。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MKBottomSheetType) {
    // 版本更新
    MKBottomSheetTypeForceUpdate,                   // 3:1373 版本更新-强更
    MKBottomSheetTypeNormalUpdate,                  // 3:1383 版本更新-普通更新
    // 个人中心相关
    MKBottomSheetTypeLogoutConfirm,                 // 3:1421 退出提示
    MKBottomSheetTypeAccountDelete,                 // 3:1431 注销提示
    MKBottomSheetTypeAccountDeleteSuccess,          // 3:1441 注销成功
    MKBottomSheetTypeAccountDeleteFail,             // 3:1468 注销失败
    // 通用提示
    MKBottomSheetTypeBackConfirm,                   // 3:1478 返回弹窗
    MKBottomSheetTypeExistingOrder,                 // 3:1518 有处理中订单提示
    MKBottomSheetTypeCommonPicker,                  // 3:1654 通用选择弹窗
    // 产品申请相关
    MKBottomSheetTypeRatingGuide,                   // 3:1487 好评引导
    MKBottomSheetTypeRatingSuccess,                 // 3:1509 好评成功
    MKBottomSheetTypeProductReloan,                 // 3:1551 产品申请-复借提示
    MKBottomSheetTypeRepaymentPlan,                 // 3:1605 还款计划 (title+subtitle+4列表格+Confirm)
    MKBottomSheetTypeBankCardSelect,                // 选择银行卡 (滚轮 + Cancel + "+ Please Add A Receiving Account")
    // 订单/首页 复借
    MKBottomSheetTypeOrderReloan,                   // 3:1564 订单详情-复借提示
    MKBottomSheetTypeHomeReloan,                    // 3:1538 首页-复借提示
    MKBottomSheetTypeWithdrawPending,               // 3:1635 待提现
    MKBottomSheetTypeWithdrawSuccess,               // 3:1645 提现成功
    // KYC 失败
    MKBottomSheetTypeKYCFail,                       // 3:284 KYC-身份证认证失败
    // 权限二次确认
    MKBottomSheetTypePermissionCamera,              // 3:1577 二次弹窗-相机
    MKBottomSheetTypePermissionLocation,            // 3:1587 二次弹窗-定位
    MKBottomSheetTypePermissionContacts,            // 3:1596 二次弹窗-通讯录
    // 下单流程
    MKBottomSheetTypeDataCapture,                   // opiuJ 数据抓取 (通讯录上传进度)
    MKBottomSheetTypeApplySuccess,                  // Q5IzQ 产品申请-申请成功-老客
    MKBottomSheetTypeLoanDisbursedSuccess,          // 数据抓取完成 — 放款成功
};

@interface MKBottomSheetView : UIView

/// 工厂方法
+ (instancetype)sheetWithType:(MKBottomSheetType)type
                       config:(nullable NSDictionary *)config;

/// 类型对应的 sheet 高度 (基础设计稿值, 实际渲染走 kScaleH)
+ (CGFloat)heightForType:(MKBottomSheetType)type;

/// 弹出 (附 dim 蒙层 + slide-up 动画)
- (void)show;
/// 关闭
- (void)dismiss;

/// 是否允许点 dim 蒙层关闭 (默认 YES; 强更类弹窗强制 NO; 调用方也可手动覆盖)
@property (nonatomic, assign) BOOL dismissibleByDim;

@property (nonatomic, copy, nullable) void (^onConfirmTapped)(void);
@property (nonatomic, copy, nullable) void (^onCancelTapped)(void);
@property (nonatomic, copy, nullable) void (^onSelected)(NSInteger index, id _Nullable value);

/// DataCapture 进度更新 (0~100)
- (void)setDataCaptureProgress:(NSInteger)progress animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
