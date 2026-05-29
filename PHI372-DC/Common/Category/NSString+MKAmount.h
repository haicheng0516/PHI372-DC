//
//  NSString+MKAmount.h
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MKAmount)

/// 将数字字符串格式化为千分位（如 "100000" → "100,000"）
- (NSString *)rd_formattedAmount;

/// 格式化为带 ₱ 符号的千分位金额（如 "100000" → "₱ 100,000"）
- (NSString *)rd_formattedPesoAmount;

/// MK 命名版本（与 rd_ 等价，新代码用这两个）
- (NSString *)mk_formattedAmount;
- (NSString *)mk_formattedPesoAmount;

/// 利率格式化: 最多 2 位小数, 去尾零, 千分位
/// 入参示例 "3.00" → "3", "0.10" → "0.1", "1234.5" → "1,234.5"
- (NSString *)mk_formattedRate;

@end

NS_ASSUME_NONNULL_END
