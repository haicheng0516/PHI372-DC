//
//  MKLoginManager.m
//

#import "MKLoginManager.h"

NSNotificationName const MKLoginStateDidChangeNotification = @"MKLoginStateDidChangeNotification";

static NSString * const kMKKeyLoggedIn   = @"MK.isLoggedIn";
static NSString * const kMKKeyMobile     = @"MK.mobile";
static NSString * const kMKKeyToken      = @"MK.token";
static NSString * const kMKKeyUserId     = @"MK.userId";
static NSString * const kMKKeyKYCDone    = @"MK.kycCompleted";

@implementation MKLoginManager

+ (instancetype)sharedManager {
    static MKLoginManager *inst; static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [[self alloc] init]; });
    return inst;
}

- (BOOL)isLoggedIn { return [[NSUserDefaults standardUserDefaults] boolForKey:kMKKeyLoggedIn]; }
- (NSString *)mobile { return [[NSUserDefaults standardUserDefaults] stringForKey:kMKKeyMobile]; }
- (NSString *)token { return [[NSUserDefaults standardUserDefaults] stringForKey:kMKKeyToken]; }
- (NSString *)userId { return [[NSUserDefaults standardUserDefaults] stringForKey:kMKKeyUserId]; }
- (BOOL)kycCompleted { return [[NSUserDefaults standardUserDefaults] boolForKey:kMKKeyKYCDone]; }
- (void)setKycCompleted:(BOOL)v {
    [[NSUserDefaults standardUserDefaults] setBool:v forKey:kMKKeyKYCDone];
}

- (void)loginWithMobile:(NSString *)mobile token:(NSString *)token {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:YES forKey:kMKKeyLoggedIn];
    [d setObject:mobile ?: @"" forKey:kMKKeyMobile];
    [d setObject:token ?: [[NSUUID UUID] UUIDString] forKey:kMKKeyToken];
    [[NSNotificationCenter defaultCenter] postNotificationName:MKLoginStateDidChangeNotification
                                                        object:nil
                                                      userInfo:@{@"isLoggedIn":@YES}];
}

- (void)loginWithUserId:(NSString *)userId token:(NSString *)token mobile:(NSString *)mobile {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:YES forKey:kMKKeyLoggedIn];
    [d setObject:userId ?: @"" forKey:kMKKeyUserId];
    [d setObject:token ?: @"" forKey:kMKKeyToken];
    [d setObject:mobile ?: @"" forKey:kMKKeyMobile];
    [d synchronize];
    NSLog(@"[Login] persisted userId=%@ token=%@ mobile=%@", userId, token, mobile);
    [[NSNotificationCenter defaultCenter] postNotificationName:MKLoginStateDidChangeNotification
                                                        object:nil
                                                      userInfo:@{@"isLoggedIn":@YES}];
}

- (void)logout {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:kMKKeyLoggedIn];
    [d removeObjectForKey:kMKKeyMobile];
    [d removeObjectForKey:kMKKeyToken];
    [d removeObjectForKey:kMKKeyUserId];
    [d removeObjectForKey:kMKKeyKYCDone];
    [d synchronize];
    NSLog(@"[Login] cleared");
    [[NSNotificationCenter defaultCenter] postNotificationName:MKLoginStateDidChangeNotification
                                                        object:nil
                                                      userInfo:@{@"isLoggedIn":@NO}];
}

@end
