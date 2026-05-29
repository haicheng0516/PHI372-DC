//
//  UIImageView+MKProductLogo.m
//

#import "UIImageView+MKProductLogo.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation UIImageView (MKProductLogo)

- (void)mk_setProductLogoURL:(NSString *)urlString fallbackColor:(UIColor *)fallback {
    self.image = nil;
    self.backgroundColor = fallback;
    if (urlString.length == 0) return;
    __weak typeof(self) weakSelf = self;
    [self sd_setImageWithURL:[NSURL URLWithString:urlString]
            placeholderImage:nil
                     options:0
                   completed:^(UIImage *img, NSError *err, SDImageCacheType type, NSURL *url) {
        if (img && !err) weakSelf.backgroundColor = [UIColor clearColor];
    }];
}

@end
