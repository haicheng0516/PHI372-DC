//
//  MKOrderDetailCard.h
//  Figma 3:719 / 3:761 / 3:814 明细卡 (灰底 + N 行 label/value + 可选卡号 + 可选分组分割线 + 可选 hint)
//
//  尺寸: 339×N (高度由行数决定) r=14 #E9E9E4
//  内部布局:
//    顶部右上: 可选卡号 (4523 **** 8451 5238) Poppins 14 white-ish
//    第一组分割线 (顶部 ~22pt 下)
//    N 行 label/value (行高 30, label PingFang 14 #999, value 14 #333 right)
//    分组之间额外分割线 (可选)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKOrderDetailCard : UIView
/// 顶部右上卡号 (可选, nil 时不显示)
@property (nonatomic, copy, nullable) NSString *cardNumber;
/// rows: 数组里每个对象是 NSArray<NSString*> = [label, value, optionalGroupBreakAfter(@"break")]
/// 简化 API: setRows: 传 [@[@"label", @"value"]] 数组
- (void)setRows:(NSArray<NSArray<NSString *> *> *)rows;
/// 在第 idx 行后画一条分割线
- (void)addBreakAfterRowIndex:(NSInteger)idx;
+ (CGFloat)heightForRowCount:(NSInteger)rowCount breakCount:(NSInteger)breakCount;
@end

NS_ASSUME_NONNULL_END
