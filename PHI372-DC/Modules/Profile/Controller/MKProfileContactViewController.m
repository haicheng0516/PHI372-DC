//
//  MKProfileContactViewController.m
//  PHI372-DC — Figma 3:1281 联系我们
//
//  hint banner + website row + email row
//

#import "MKProfileContactViewController.h"

@implementation MKProfileContactViewController

- (instancetype)init {
    NSArray *items = @[
        [MKDocPageItem hintWithText:@"If you have any questions, please save the proof and contact customer service."],
        [MKDocPageItem websiteWithURL:@"https://bj.XXX.xXX"],
        [MKDocPageItem emailWithAddress:@"XXcash@Hotmail.com"],
    ];
    return [super initWithTitle:@"Contact Us" items:items];
}

@end
