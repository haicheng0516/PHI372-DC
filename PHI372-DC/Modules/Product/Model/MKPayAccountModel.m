//
//  MKPayAccountModel.m
//

#import "MKPayAccountModel.h"

@implementation MKPayAccountModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        if (![dict isKindOfClass:[NSDictionary class]]) return self;
        _recordId        = [dict[@"recordId"] integerValue];
        _bankCardBindId  = [dict[@"bankCardBindId"] integerValue];
        _defaultFlag     = [self truthy:dict[@"defaultFlag"]];
        _editFlag        = [self truthy:dict[@"editFlag"]];
        _status          = [dict[@"status"] integerValue];
        _originalDict    = [dict copy];

        [self resolveDisplayFieldsFromDict:dict];
    }
    return self;
}

/// 解析 "1"/"0"/YES/NO/1/0 为 BOOL
- (BOOL)truthy:(id)val {
    if ([val isKindOfClass:[NSNumber class]]) return [val boolValue];
    if ([val isKindOfClass:[NSString class]]) {
        return [val isEqualToString:@"1"] || [val isEqualToString:@"true"] || [val isEqualToString:@"YES"];
    }
    return NO;
}

/// 从 dict 模糊匹配 3 个独立字段 + displayName
- (void)resolveDisplayFieldsFromDict:(NSDictionary *)dict {
    NSSet *metaKeys = [NSSet setWithArray:@[
        @"recordId", @"bankCardBindId", @"defaultFlag", @"editFlag",
        @"createTime", @"updateTime", @"userId", @"id", @"status"
    ]];

    NSString *bankCode = nil;
    NSString *cardNumber = nil;
    NSString *accountName = nil;
    NSString *fallback = nil;

    for (NSString *key in dict) {
        if ([metaKeys containsObject:key]) continue;
        id val = dict[key];
        NSString *str = nil;
        if ([val isKindOfClass:[NSString class]])      str = val;
        else if ([val isKindOfClass:[NSNumber class]]) str = [val stringValue];
        if (str.length == 0) continue;

        NSString *lower = key.lowercaseString;

        // 户名: holdername / accountname / username
        if (!accountName && ([lower containsString:@"holder"] || [lower containsString:@"accountname"]
                              || [lower containsString:@"account_name"] || [lower containsString:@"username"]
                              || [lower containsString:@"realname"])) {
            accountName = str;
        }
        // 卡号: accountno / cardnumber / cardno / cardaccount
        else if (!cardNumber && ([lower containsString:@"accountno"] || [lower containsString:@"account_no"]
                                  || [lower containsString:@"cardnumber"] || [lower containsString:@"card_number"]
                                  || [lower containsString:@"cardno"] || [lower containsString:@"cardaccount"])) {
            cardNumber = str;
        }
        // bank ID/name: bankname / bankcode / branchcode
        else if (!bankCode && ([lower containsString:@"bank"] && ![lower containsString:@"account"])) {
            bankCode = str;
        }
        if (!fallback) fallback = str;
    }

    // 二次兜底: 没识别出 cardNumber 时, 找剩余里像卡号的 (纯数字 8 位以上)
    if (!cardNumber) {
        for (NSString *key in dict) {
            if ([metaKeys containsObject:key]) continue;
            id val = dict[key];
            NSString *str = [val isKindOfClass:[NSString class]] ? val : nil;
            if (str.length >= 8) {
                NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
                NSString *trimmed = [[str componentsSeparatedByCharactersInSet:[digits invertedSet]] componentsJoinedByString:@""];
                if (trimmed.length >= 8) { cardNumber = str; break; }
            }
        }
    }

    _bankCode    = bankCode ?: fallback;
    _cardNumber  = cardNumber;
    _accountName = accountName;
    _displayName = [self composeDisplayName];
}

/// 下单页弹窗 / receiving account 子卡用: 仅卡号 (脱敏)
- (NSString *)composeDisplayName {
    NSString *cn = self.cardNumber;
    if (cn.length > 0) return [self maskedCardNumber:cn];
    if (self.bankCode.length > 0) return self.bankCode;
    return @"Bank account";
}

- (NSString *)maskedCardNumber:(NSString *)num {
    if (num.length <= 8) return num;
    NSString *head = [num substringToIndex:4];
    NSString *tail = [num substringFromIndex:num.length - 4];
    return [NSString stringWithFormat:@"%@ **** **** %@", head, tail];
}

+ (NSArray<MKPayAccountModel *> *)modelsFromList:(NSArray *)rawList {
    if (![rawList isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSDictionary *d in rawList) {
        if ([d isKindOfClass:[NSDictionary class]]) {
            [arr addObject:[[MKPayAccountModel alloc] initWithDictionary:d]];
        }
    }
    return arr;
}

@end
