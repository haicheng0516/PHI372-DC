//
//  MKRatingPromptManager.m
//  PHI372-DC
//

#import "MKRatingPromptManager.h"

static NSString * const kMKRatingHasCompletedFirstOrder = @"MK.RatingPrompt.HasCompletedFirstOrder";
static NSString * const kMKRatingShouldShowOnHome       = @"MK.RatingPrompt.ShouldShowOnHome";
static NSString * const kMKRatingHasShownPrompt         = @"MK.RatingPrompt.HasShown";

@implementation MKRatingPromptManager

+ (void)noteOrderCompleted {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d boolForKey:kMKRatingHasCompletedFirstOrder]) return; // 非首单,不触发
    [d setBool:YES forKey:kMKRatingHasCompletedFirstOrder];
    [d setBool:YES forKey:kMKRatingShouldShowOnHome];
    [d synchronize];
}

+ (BOOL)consumePendingFlag {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (![d boolForKey:kMKRatingShouldShowOnHome]) return NO;
    [d setBool:NO forKey:kMKRatingShouldShowOnHome];
    [d synchronize];
    return YES;
}

+ (BOOL)hasShownPrompt {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kMKRatingHasShownPrompt];
}

+ (void)markPromptShown {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMKRatingHasShownPrompt];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
