//
//  MKDocPageViewController.m
//

#import "MKDocPageViewController.h"
#import "MKConstants.h"
#import "MKHintBannerView.h"
#import "MKDocCardView.h"
#import "MKContactRowCell.h"
#import <Masonry/Masonry.h>

typedef NS_ENUM(NSUInteger, MKDocItemKind) {
    MKDocItemKindHint,
    MKDocItemKindDoc,
    MKDocItemKindWebsite,
    MKDocItemKindEmail,
    MKDocItemKindSpacing,
    MKDocItemKindCustom,
};

@interface MKDocPageItem ()
@property (nonatomic, assign) MKDocItemKind kind;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *sectionTitle;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) UIView * (^viewProvider)(CGFloat width);
@property (nonatomic, assign) CGFloat spacing;
@end

@implementation MKDocPageItem
+ (instancetype)hintWithText:(NSString *)text {
    MKDocPageItem *i = [self new]; i.kind = MKDocItemKindHint; i.text = text; return i;
}
+ (instancetype)docWithSectionTitle:(NSString *)title body:(NSString *)body {
    MKDocPageItem *i = [self new]; i.kind = MKDocItemKindDoc; i.sectionTitle = title; i.body = body; return i;
}
+ (instancetype)websiteWithURL:(NSString *)url {
    MKDocPageItem *i = [self new]; i.kind = MKDocItemKindWebsite; i.text = url; return i;
}
+ (instancetype)emailWithAddress:(NSString *)email {
    MKDocPageItem *i = [self new]; i.kind = MKDocItemKindEmail; i.text = email; return i;
}
+ (instancetype)spacingWithHeight:(CGFloat)height {
    MKDocPageItem *i = [self new]; i.kind = MKDocItemKindSpacing; i.spacing = height; return i;
}
+ (instancetype)customViewWithProvider:(UIView * (^)(CGFloat))provider {
    MKDocPageItem *i = [self new]; i.kind = MKDocItemKindCustom; i.viewProvider = provider; return i;
}
@end

@interface MKDocPageViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation MKDocPageViewController

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<MKDocPageItem *> *)items {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = title;
        _items = [items copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = kColorBackground;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(self.heroHeaderView ? 0 : kNavBarHeight);
        make.left.right.bottom.equalTo(self.view);
    }];

    if (self.heroHeaderView) {
        [self.scrollView addSubview:self.heroHeaderView];
    }

    [self renderDocItems];
}

- (void)reloadDocItems {
    if (!self.scrollView) return;
    for (UIView *sub in [self.scrollView.subviews copy]) {
        if (sub != self.heroHeaderView) [sub removeFromSuperview];
    }
    [self renderDocItems];
}

- (void)renderDocItems {
    CGFloat y = self.heroHeaderView ? CGRectGetMaxY(self.heroHeaderView.frame) - kNavBarHeight + kScaleH(16) : kScaleH(12);
    CGFloat cardW = kScaleW(339);
    CGFloat cardX = kScaleW(18);

    for (MKDocPageItem *it in self.items) {
        UIView *child = nil;
        CGFloat childH = 0;
        switch (it.kind) {
            case MKDocItemKindHint: {
                child = [[MKHintBannerView alloc] initWithText:it.text];
                childH = [MKHintBannerView heightForText:it.text];
                break;
            }
            case MKDocItemKindDoc: {
                child = [[MKDocCardView alloc] initWithSectionTitle:it.sectionTitle body:it.body];
                childH = [MKDocCardView heightForSectionTitle:it.sectionTitle body:it.body];
                break;
            }
            case MKDocItemKindWebsite:
                child = [[MKContactRowCell alloc] initWithKind:MKContactRowKindWebsite value:it.text];
                childH = [MKContactRowCell cellHeight];
                break;
            case MKDocItemKindEmail:
                child = [[MKContactRowCell alloc] initWithKind:MKContactRowKindEmail value:it.text];
                childH = [MKContactRowCell cellHeight];
                break;
            case MKDocItemKindSpacing:
                y += kScaleH(it.spacing);
                continue;
            case MKDocItemKindCustom:
                child = it.viewProvider ? it.viewProvider(cardW) : nil;
                childH = child.bounds.size.height;
                break;
        }
        if (child) {
            child.frame = CGRectMake(cardX, y, cardW, childH);
            [self.scrollView addSubview:child];
            y += childH + kScaleH(12);
        }
    }
    self.scrollView.contentSize = CGSizeMake(kScreenWidth, y + kBottomSafeHeight + kScaleH(20));
}
@end
