//
//  MKPickerView.m
//
//  历史遗留 picker — 早期色板不属于本项目 (kColorBgTeal 浅青 + kColorOrange 橙色, 跟主色深绿 #385330 不搭).
//  2026-05-20 修正: 工厂方法转发给 MKBottomSheetTypeCommonPicker (Figma 3:1654 通用选择弹窗).
//  调用点不动 (Personal/Finance/Contact/Payment/BankCardEdit), 一次性纠正全部 picker 色板.
//

#import "MKPickerView.h"
#import "MKBottomSheetView.h"

@implementation MKPickerView

+ (void)showWithTitle:(NSString *)title
              options:(NSArray<NSString *> *)options
        selectedIndex:(NSInteger)index
             onSelect:(MKPickerSelectBlock)selectBlock {
    [self showWithTitle:title options:options selectedIndex:index onSelect:selectBlock onCancel:nil];
}

+ (void)showWithTitle:(NSString *)title
              options:(NSArray<NSString *> *)options
        selectedIndex:(NSInteger)index
             onSelect:(MKPickerSelectBlock)selectBlock
             onCancel:(nullable MKPickerCancelBlock)cancelBlock {
    // MKBottomSheetTypeCommonPicker = Figma 3:1654. 行点击立即触发 + dismiss, 无 Confirm 按钮.
    // selectedIndex 在新设计里不展示预选高亮 (跟 Figma 一致); 调用方若需要回显当前 value, 由 cell 自己展示即可.
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypeCommonPicker
                                                          config:@{
                                                              @"title": title ?: @"",
                                                              @"items": options ?: @[],
                                                              @"selectedIndex": @(index)
                                                          }];
    sheet.onSelected = ^(NSInteger idx, id value) {
        if (selectBlock) {
            NSString *str = [value isKindOfClass:[NSString class]] ? (NSString *)value : [value description];
            selectBlock(idx, str);
        }
    };
    sheet.onCancelTapped = ^{ if (cancelBlock) cancelBlock(); };
    [sheet show];
}

// 实例方法保留 dummy 实现以兼容旧头文件 (已无外部调用方).
- (void)show {}
- (void)dismiss {}

@end
