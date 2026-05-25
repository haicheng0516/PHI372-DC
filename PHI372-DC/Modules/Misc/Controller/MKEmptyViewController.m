#import "MKEmptyViewController.h"
#import "MKConstants.h"

@interface MKEmptyViewController ()
@property (nonatomic, strong) UILabel *emptyLabel;
@end

@implementation MKEmptyViewController
- (instancetype)init { if (self = [super init]) { self.navBarStyle = MKNavBarStyleLight; self.navTitle = @""; } return self; }
- (instancetype)initWithTitle:(NSString *)title emptyText:(NSString *)emptyText {
    if (self = [self init]) {
        self.navTitle = title;
        _emptyLabel = [UILabel new];
        _emptyLabel.text = emptyText;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Pencil: bg #f8f8f7
    self.view.backgroundColor = MKHexColor(0xF8F8F7);

    // Pencil: 图片占位 image-import-11, 159x76, (108, 239)
    UIView *imgPlaceholder = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(108), kScaleH(239), kScaleW(159), kScaleH(76))];
    imgPlaceholder.backgroundColor = MKHexColor(0xE9E9E4);
    imgPlaceholder.layer.cornerRadius = kScaleW(8);
    [self.view addSubview:imgPlaceholder];

    // Pencil: "No xxx" Poppins/14/#999999, textAlign center, y=348
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(348), kScreenWidth, kScaleH(20))];
    l.text = self.emptyLabel.text ?: @"No data";
    l.font = kFontRegular(14);
    l.textColor = MKHexColor(0x999999);
    l.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:l];
}
@end
