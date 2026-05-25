//
//  MKSeamlessOrderManager.m
//  PHI372-DC
//

#import "MKSeamlessOrderManager.h"
#import "MKProductTermModel.h"
#import "MKDeviceTool.h"
#import "MKCommonParams.h"
#import "MKEncryptManager.h"
#import "MKNetworkManager.h"
#import "MKBottomSheetView.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Contacts/Contacts.h>

@implementation MKSeamlessOrderParams
@end

@interface MKSeamlessOrderManager () <CLLocationManagerDelegate>

@property (nonatomic, assign) MKSeamlessOrderState currentState;
@property (nonatomic, copy, nullable) NSString *currentOrderId;
@property (nonatomic, assign) BOOL isProcessing;

@property (nonatomic, strong, nullable) MKSeamlessOrderParams *currentParams;
@property (nonatomic, strong, nullable) MKProductTermDataModel *termData;

// Config
@property (nonatomic, assign) BOOL isForceCaptureFlow;
@property (nonatomic, assign) NSInteger pushMaxCount;
@property (nonatomic, assign) NSInteger pushPerCount;

// Location
@property (nonatomic, strong, nullable) CLLocationManager *locationManager;
@property (nonatomic, copy, nullable) NSString *latitude;
@property (nonatomic, copy, nullable) NSString *longitude;
@property (nonatomic, assign) BOOL hasCalledOrderAPI;
@property (nonatomic, assign) BOOL isLocationUpdating;
@property (nonatomic, assign) BOOL isWaitingForLocationPermission;
@property (nonatomic, assign) BOOL hasLocationTimedOut;

// Contacts
@property (nonatomic, assign) BOOL isWaitingForContactsPermission;
@property (nonatomic, assign) BOOL hasCalledReadyAPI;

@end

@implementation MKSeamlessOrderManager

+ (instancetype)sharedManager {
    static MKSeamlessOrderManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ mgr = [[self alloc] init]; });
    return mgr;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pushMaxCount = 1000;
        _pushPerCount = 100;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (BOOL)startSeamlessOrderWithParams:(MKSeamlessOrderParams *)params {
    if (self.isProcessing) return NO;
    if (!params.productId || params.productId.length == 0) return NO;

    self.isProcessing = YES;
    self.currentParams = params;
    self.currentOrderId = nil;
    self.latitude = @"-360";
    self.longitude = @"-360";
    self.hasCalledOrderAPI = NO;
    self.hasCalledReadyAPI = NO;
    self.hasLocationTimedOut = NO;
    self.isWaitingForLocationPermission = NO;
    self.isWaitingForContactsPermission = NO;
    self.isLocationUpdating = NO;

    self.termData = [[MKProductTermDataModel alloc] initWithDictionary:params.termResponseData];

    [self updateState:MKSeamlessOrderStateLoadingConfig];
    [self loadAppConfig];
    return YES;
}

- (void)cancel {
    [self.locationManager stopUpdatingLocation];
    self.isWaitingForLocationPermission = NO;
    self.isWaitingForContactsPermission = NO;
    self.isProcessing = NO;
    [self updateState:MKSeamlessOrderStateFailed];
    if ([self.delegate respondsToSelector:@selector(seamlessOrderManagerDidCancel:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate seamlessOrderManagerDidCancel:self];
        });
    }
    [self resetInternal];
}

- (void)reset {
    [self resetInternal];
}

- (void)resetInternal {
    self.currentState = MKSeamlessOrderStateIdle;
    self.currentOrderId = nil;
    self.currentParams = nil;
    self.termData = nil;
    self.hasCalledOrderAPI = NO;
    self.hasCalledReadyAPI = NO;
    self.isLocationUpdating = NO;
    self.isWaitingForLocationPermission = NO;
    self.isWaitingForContactsPermission = NO;
    self.latitude = @"-360";
    self.longitude = @"-360";
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)updateState:(MKSeamlessOrderState)state {
    self.currentState = state;
    if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:didChangeState:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate seamlessOrderManager:self didChangeState:state];
        });
    }
}

#pragma mark - Step 1: Load Config

- (void)loadAppConfig {
    NSMutableDictionary *body = [[[MKEncryptManager sharedManager] generateRequestBody:@{}] mutableCopy];
    body[@"merchantId"] = @"1004";
    [[MKNetworkManager sharedManager] post:@"/app/v3/app/config"
                                    params:body
                                   success:^(id resp) {
        if (![resp isKindOfClass:[NSDictionary class]]) {
            [self proceedToLocationCheck]; return;
        }
        NSDictionary *data = resp[@"data"];
        NSInteger retrieveMobileContact = [data[@"retrieveMobileContact"] integerValue];
        self.isForceCaptureFlow = (retrieveMobileContact > 0);
        self.pushMaxCount = [data[@"pushMaxCount"] integerValue] ?: 1000;
        self.pushPerCount = [data[@"pushPerCount"] integerValue] ?: 100;
        [self proceedToLocationCheck];
    } failure:^(NSError *error) {
        self.isForceCaptureFlow = NO;
        [self proceedToLocationCheck];
    }];
}

#pragma mark - Step 2: Location

- (void)proceedToLocationCheck {
    [self updateState:MKSeamlessOrderStateCheckingLocation];

    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }

    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = self.locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self updateState:MKSeamlessOrderStateGettingLocation];
        [self startLocationUpdateWithTimeout];
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        self.isWaitingForLocationPermission = YES;
        if ([self.delegate respondsToSelector:@selector(seamlessOrderManagerWillShowSystemLocationPermissionAlert:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate seamlessOrderManagerWillShowSystemLocationPermissionAlert:self];
            });
        }
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        // Denied/Restricted
        if (self.isForceCaptureFlow) {
            self.isWaitingForLocationPermission = YES;
            [self showLocationPermissionAlert];
        } else {
            [self submitOrder];
        }
    }
}

- (void)startLocationUpdateWithTimeout {
    self.hasLocationTimedOut = NO;
    self.isLocationUpdating = YES;
    [self.locationManager startUpdatingLocation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.hasLocationTimedOut && (self.currentState == MKSeamlessOrderStateCheckingLocation || self.currentState == MKSeamlessOrderStateGettingLocation)) {
            self.hasLocationTimedOut = YES;
            [self.locationManager stopUpdatingLocation];
            self.isLocationUpdating = NO;
            [self submitOrder];
        }
    });
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (self.hasLocationTimedOut) return;
    self.hasLocationTimedOut = YES;
    CLLocation *loc = locations.lastObject;
    self.latitude = [NSString stringWithFormat:@"%.6f", loc.coordinate.latitude];
    self.longitude = [NSString stringWithFormat:@"%.6f", loc.coordinate.longitude];
    [manager stopUpdatingLocation];
    self.isLocationUpdating = NO;
    [self submitOrder];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.hasLocationTimedOut) return;
    self.hasLocationTimedOut = YES;
    [manager stopUpdatingLocation];
    self.isLocationUpdating = NO;
    if (self.isForceCaptureFlow) {
        [self notifyFail:@"Failed to get location"];
    } else {
        [self submitOrder];
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0)) {
    [self handleAuthChange];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self handleAuthChange];
}

- (void)handleAuthChange {
    if (!self.isWaitingForLocationPermission) return;

    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = self.locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }

    // NotDetermined 说明用户还没做选择，不消耗 flag，继续等
    if (status == kCLAuthorizationStatusNotDetermined) return;

    self.isWaitingForLocationPermission = NO;

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self updateState:MKSeamlessOrderStateGettingLocation];
        [self startLocationUpdateWithTimeout];
    } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        if (self.isForceCaptureFlow) {
            [self cancel];
        } else {
            [self submitOrder];
        }
    }
}

- (void)appWillEnterForeground {
    if (!self.isProcessing) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isWaitingForLocationPermission) {
            [self handleAuthChange];
        }
        if (self.isWaitingForContactsPermission) {
            CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
            if (status == CNAuthorizationStatusAuthorized) {
                self.isWaitingForContactsPermission = NO;
                [self startContactsUpload];
            } else {
                self.isWaitingForContactsPermission = NO;
                [self cancel];
            }
        }
    });
}

#pragma mark - Permission Alerts

- (void)showLocationPermissionAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) wself = self;
        MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypePermissionLocation config:nil];
        // Confirm: 不清 flag, 用户从 Settings 返回时 appWillEnterForeground → handleAuthChange 自动续流
        sheet.onConfirmTapped = ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                               options:@{} completionHandler:nil];
        };
        // Cancel: 用户主动取消流程
        sheet.onCancelTapped = ^{
            wself.isWaitingForLocationPermission = NO;
            wself.isProcessing = NO;
            [wself updateState:MKSeamlessOrderStateFailed];
            if ([wself.delegate respondsToSelector:@selector(seamlessOrderManagerDidCancelLocationPermission:)]) {
                [wself.delegate seamlessOrderManagerDidCancelLocationPermission:wself];
            }
            [wself resetInternal];
        };
        [sheet show];
    });
}

- (void)showContactsPermissionAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) wself = self;
        MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypePermissionContacts config:nil];
        // Confirm: 不清 flag, 用户从 Settings 返回时 appWillEnterForeground 重检通讯录授权
        sheet.onConfirmTapped = ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                               options:@{} completionHandler:nil];
        };
        sheet.onCancelTapped = ^{
            wself.isWaitingForContactsPermission = NO;
            wself.isProcessing = NO;
            [wself updateState:MKSeamlessOrderStateFailed];
            if ([wself.delegate respondsToSelector:@selector(seamlessOrderManagerDidCancelContactsPermission:)]) {
                [wself.delegate seamlessOrderManagerDidCancelContactsPermission:wself];
            }
            [wself resetInternal];
        };
        [sheet show];
    });
}

#pragma mark - Step 3: Submit Order

- (void)submitOrder {
    if (self.hasCalledOrderAPI) return;
    self.hasCalledOrderAPI = YES;

    [self updateState:MKSeamlessOrderStateSubmittingOrder];

    // 首单场景: 优先按 currentParams.selectedAmount 找匹配的 amount, 然后按 selectedShowTerm 找匹配的 term;
    // 都找不到时 fallback 第一个 (复借场景或单金额单期限产品)
    NSString *loanAmount = self.currentParams.selectedAmount;
    MKAmountDetailModel *selectedAmountDetail = nil;
    for (MKAmountDetailModel *a in self.termData.amountDetailList) {
        if (loanAmount.length > 0 && [a.loanAmount isEqualToString:loanAmount]) {
            selectedAmountDetail = a; break;
        }
    }
    if (!selectedAmountDetail) {
        selectedAmountDetail = self.termData.amountDetailList.firstObject;
    }
    if (loanAmount.length == 0) loanAmount = selectedAmountDetail.loanAmount ?: @"";

    MKTermDetailModel *selectedTermDetail = nil;
    if (self.currentParams.selectedShowTerm > 0) {
        for (MKTermDetailModel *t in selectedAmountDetail.termDetailList) {
            if (t.showTerm == self.currentParams.selectedShowTerm) {
                selectedTermDetail = t; break;
            }
        }
    }
    if (!selectedTermDetail) selectedTermDetail = selectedAmountDetail.termDetailList.firstObject;

    NSMutableDictionary *signData = [NSMutableDictionary dictionary];
    signData[@"productId"] = self.currentParams.productId ?: @"";
    signData[@"loanAmount"] = loanAmount;
    signData[@"longitude"] = self.longitude;
    signData[@"latitude"] = self.latitude;
    signData[@"imei"] = @"null";
    signData[@"serialNo"] = [MKCommonParams shared].deviceId ?: @"";

    NSMutableDictionary *body = [[[MKEncryptManager sharedManager] generateRequestBody:signData] mutableCopy];

    NSMutableDictionary *requestData = [signData mutableCopy];
    if (selectedTermDetail) {
        requestData[@"showTerm"] = [NSString stringWithFormat:@"%ld", (long)selectedTermDetail.showTerm];
    }
    // 首单场景: 用户选中的银行卡
    if (self.currentParams.bankCardBindId > 0) {
        requestData[@"bankCardBindId"] = [NSString stringWithFormat:@"%ld", (long)self.currentParams.bankCardBindId];
    }
    requestData[@"check"] = @{@"checkType": @(0), @"checkContent": @"0000"};
    requestData[@"orderType"] = @"1";
    body[@"data"] = requestData;

    [[MKNetworkManager sharedManager] post:@"/app/v3/order/userSubmitV3"
                                    params:body
                                   success:^(id resp) {
        if (![resp isKindOfClass:[NSDictionary class]]) {
            [self notifyFail:@"Invalid response"]; return;
        }
        NSInteger code = [resp[@"resultCode"] integerValue];
        if (code != 200) {
            [self notifyFail:resp[@"resultMsg"] ?: @"Submit failed"]; return;
        }
        NSString *orderId = [NSString stringWithFormat:@"%@", resp[@"data"][@"orderId"] ?: @""];
        if (orderId.length == 0) {
            [self notifyFail:@"Missing orderId"]; return;
        }
        self.currentOrderId = orderId;
        if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:didSubmitOrderSuccess:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate seamlessOrderManager:self didSubmitOrderSuccess:orderId];
            });
        }
        [self startDataCaptureWithOrderId:orderId];
    } failure:^(NSError *error) {
        [self notifyFail:@"Network error"];
    }];
}

#pragma mark - Step 4: Device Upload

- (void)startDataCaptureWithOrderId:(NSString *)orderId {
    [self updateState:MKSeamlessOrderStateUploadingDevice];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *deviceInfo = [MKDeviceTool collectDeviceInfoWithOrderId:orderId];
        if (!deviceInfo || deviceInfo.count == 0) {
            [self proceedToContactsCheck]; return;
        }
        // 签名只用 orderId，deviceInfo 作为完整请求数据（与259一致）
        NSDictionary *signData = @{@"orderId": orderId ?: @""};
        NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:signData requestData:deviceInfo];
        [[MKNetworkManager sharedManager] post:@"/app/v3/mobile/device"
                                        params:body
                                       success:^(id resp) { [self proceedToContactsCheck]; }
                                       failure:^(NSError *e) { [self proceedToContactsCheck]; }];
    });
}

#pragma mark - Step 5: Contacts

- (void)proceedToContactsCheck {
    [self updateState:MKSeamlessOrderStateCheckingContacts];
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

    if (self.isForceCaptureFlow) {
        [self checkContactsForce:status];
    } else {
        [self checkContactsNonForce:status];
    }
}

- (void)checkContactsForce:(CNAuthorizationStatus)status {
    // 对齐 259 SCSeamlessOrderManager.m L779-838:
    //  - 首次拒绝 (NotDetermined → 用户点不允许) → notifyFailure 静默失败 (不 cancel/pop)
    //  - 已 Denied/Restricted → 弹自定义二次弹窗
    //  - iOS18 Limited → notifyFailure (Force 模式需要全部访问)
    if (@available(iOS 18.0, *)) {
        if (status == CNAuthorizationStatusLimited) {
            [self notifyFail:@"Full contacts access required"]; return;
        }
    }
    if (status == CNAuthorizationStatusAuthorized) {
        [self startContactsUpload];
    } else if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CNAuthorizationStatus cur = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                if (@available(iOS 18.0, *)) {
                    if (cur == CNAuthorizationStatusLimited) {
                        [self notifyFail:@"Full contacts access required"]; return;
                    }
                }
                if (granted && cur == CNAuthorizationStatusAuthorized) {
                    [self startContactsUpload];
                } else {
                    [self notifyFail:@"Contacts permission denied"];
                }
            });
        }];
    } else {
        // 已 Denied/Restricted → 自定义二次弹窗
        self.isWaitingForContactsPermission = YES;
        [self showContactsPermissionAlert];
    }
}

- (void)checkContactsNonForce:(CNAuthorizationStatus)status {
    if (@available(iOS 18.0, *)) {
        if (status == CNAuthorizationStatusLimited) {
            [self startContactsUpload]; return;
        }
    }
    if (status == CNAuthorizationStatusAuthorized) {
        [self startContactsUpload];
    } else if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CNAuthorizationStatus cur = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                if (@available(iOS 18.0, *)) {
                    if (cur == CNAuthorizationStatusLimited) {
                        [self startContactsUpload]; return;
                    }
                }
                if (granted && cur == CNAuthorizationStatusAuthorized) {
                    [self startContactsUpload];
                } else {
                    [self callReadyAPIWithAllowContact:@"2"];
                }
            });
        }];
    } else {
        [self callReadyAPIWithAllowContact:@"2"];
    }
}

- (void)startContactsUpload {
    [self updateState:MKSeamlessOrderStateUploadingContacts];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSArray<NSDictionary *> *> *batches =
            [MKDeviceTool collectContactsWithMaxCount:self.pushMaxCount perCount:self.pushPerCount];

        if (batches.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callReadyAPIWithAllowContact:@"1"];
            });
            return;
        }

        NSInteger totalCount = 0;
        for (NSArray *batch in batches) totalCount += batch.count;
        __block NSInteger uploadedCount = 0;

        dispatch_semaphore_t sema = dispatch_semaphore_create(0);

        for (NSArray<NSDictionary *> *batch in batches) {
            // 签名只用 orderId，list 和 allowContact 不参与签名（与259一致）
            NSDictionary *signData = @{@"orderId": self.currentOrderId ?: @""};
            NSMutableDictionary *requestData = [NSMutableDictionary dictionary];
            requestData[@"orderId"] = self.currentOrderId ?: @"";
            requestData[@"list"] = batch;
            requestData[@"allowContact"] = @"";

            NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:signData requestData:requestData];
            [[MKNetworkManager sharedManager] post:@"/app/v3/mobile/contact"
                                            params:body
                                           success:^(id resp) { dispatch_semaphore_signal(sema); }
                                           failure:^(NSError *e) { dispatch_semaphore_signal(sema); }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

            uploadedCount += batch.count;
            NSInteger progress = MIN((uploadedCount * 100) / totalCount, 100);
            if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:didUpdateContactUploadProgress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate seamlessOrderManager:self didUpdateContactUploadProgress:progress];
                });
            }
        }

        if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:didUpdateContactUploadProgress:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate seamlessOrderManager:self didUpdateContactUploadProgress:100];
            });
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self callReadyAPIWithAllowContact:@"1"];
        });
    });
}

#pragma mark - Step 6: Ready

- (void)callReadyAPIWithAllowContact:(NSString *)allowContact {
    if (self.hasCalledReadyAPI) return;
    self.hasCalledReadyAPI = YES;

    [self updateState:MKSeamlessOrderStateCompleting];

    // 签名只用 orderId，allowContact 不参与签名（与259一致）
    NSDictionary *signData = @{@"orderId": self.currentOrderId ?: @""};
    NSDictionary *requestData = @{
        @"orderId": self.currentOrderId ?: @"",
        @"allowContact": allowContact
    };
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:signData requestData:requestData];

    [[MKNetworkManager sharedManager] post:@"/app/v3/order/ready"
                                    params:body
                                   success:^(id resp) { [self notifySuccess]; }
                                   failure:^(NSError *e) { [self notifySuccess]; }];
}

#pragma mark - Notify

- (void)notifySuccess {
    [self updateState:MKSeamlessOrderStateSuccess];
    self.isProcessing = NO;
    NSString *orderId = self.currentOrderId ?: @"";
    if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:didCompleteWithOrderId:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate seamlessOrderManager:self didCompleteWithOrderId:orderId];
        });
    }
    [self resetInternal];
}

- (void)notifyFail:(NSString *)message {
    self.isProcessing = NO;
    [self updateState:MKSeamlessOrderStateFailed];
    NSError *error = [NSError errorWithDomain:@"MKSeamlessOrderManager" code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
    if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:didFailWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate seamlessOrderManager:self didFailWithError:error];
        });
    }
}

@end
