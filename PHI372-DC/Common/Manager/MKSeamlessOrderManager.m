//  MKSeamlessOrderManager.m

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
#import <SVProgressHUD/SVProgressHUD.h>

NSNotificationName const MKSeamlessOrderDataCaptureCompletedNotification = @"MKSeamlessOrderDataCaptureCompletedNotification";

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

// 二次权限自定义弹窗引用
// 跳设置时动画 dismiss 会被 background 打断, 必须用 removeFromSuperview 立即移除
@property (nonatomic, strong, nullable) MKBottomSheetView *locationPermissionAlert;
@property (nonatomic, strong, nullable) MKBottomSheetView *contactsPermissionAlert;

/// YES 时跳过下单环节, submitOrder 命中即直接走 startDataCaptureWithOrderId
@property (nonatomic, assign) BOOL isDataCaptureOnly;

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
    self.isDataCaptureOnly = NO;

    self.termData = [[MKProductTermDataModel alloc] initWithDictionary:params.termResponseData];

    [self updateState:MKSeamlessOrderStateLoadingConfig];
    [self loadAppConfig];
    return YES;
}

- (BOOL)startDataCaptureOnlyWithOrderId:(NSString *)orderId {
    if (self.isProcessing) return NO;
    if (orderId.length == 0) return NO;

    self.isProcessing = YES;
    self.currentParams = nil;
    self.currentOrderId = orderId;
    self.latitude = @"-360";
    self.longitude = @"-360";
    self.hasCalledOrderAPI = YES;   // 跳过下单, 视为已下过单
    self.hasCalledReadyAPI = NO;
    self.hasLocationTimedOut = NO;
    self.isWaitingForLocationPermission = NO;
    self.isWaitingForContactsPermission = NO;
    self.isLocationUpdating = NO;
    self.isDataCaptureOnly = YES;

    [self updateState:MKSeamlessOrderStateLoadingConfig];
    [self loadAppConfig];
    return YES;
}

- (void)cancel {
    [self.locationManager stopUpdatingLocation];
    self.isWaitingForLocationPermission = NO;
    self.isWaitingForContactsPermission = NO;
    self.isProcessing = NO;
    [self resetInternal];
}

- (void)reset {
    [self resetInternal];
}

- (void)resetInternal {
    self.isProcessing = NO;
    self.currentState = MKSeamlessOrderStateIdle;
    self.currentOrderId = nil;
    self.currentParams = nil;
    self.termData = nil;
    self.hasCalledOrderAPI = NO;
    self.hasCalledReadyAPI = NO;
    self.isLocationUpdating = NO;
    self.isForceCaptureFlow = NO;
    self.isWaitingForLocationPermission = NO;
    self.isWaitingForContactsPermission = NO;
    self.isDataCaptureOnly = NO;
    self.latitude = @"-360";
    self.longitude = @"-360";
    // 清掉自定义权限弹窗
    if (self.locationPermissionAlert) {
        [self.locationPermissionAlert removeFromSuperview];
        self.locationPermissionAlert = nil;
    }
    if (self.contactsPermissionAlert) {
        [self.contactsPermissionAlert removeFromSuperview];
        self.contactsPermissionAlert = nil;
    }
    if (self.locationManager) {
        self.locationManager.delegate = nil;
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
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
    if (self.isForceCaptureFlow) {
        [self checkLocationPermissionForForceCapture];
    } else {
        [self checkLocationPermissionForNonForceCapture];
    }
}

- (CLAuthorizationStatus)getLocationAuthorizationStatus {
    if (self.locationManager) {
        if (@available(iOS 14.0, *)) {
            return self.locationManager.authorizationStatus;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [CLLocationManager authorizationStatus];
#pragma clang diagnostic pop
}

- (BOOL)isLocationAuthorized {
    CLAuthorizationStatus status = [self getLocationAuthorizationStatus];
    return (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways);
}

- (void)setupLocationManager {
    if (self.locationManager) return;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
}

- (void)checkLocationPermissionForForceCapture {
    // 先用类方法读 pre-status (在 setupLocationManager 之前, 避免设 delegate 触发回调)
    CLAuthorizationStatus preStatus;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    preStatus = [CLLocationManager authorizationStatus];
#pragma clang diagnostic pop

    // 已拒绝: 先标 isWaiting=YES, 防止 setupLocationManager 设 delegate 触发 handleAuthChange 误 cancel
    if (preStatus == kCLAuthorizationStatusDenied || preStatus == kCLAuthorizationStatusRestricted) {
        self.isWaitingForLocationPermission = YES;
    }

    [self setupLocationManager];

    CLAuthorizationStatus status = [self getLocationAuthorizationStatus];

    if (status == kCLAuthorizationStatusNotDetermined) {
        if ([self.delegate respondsToSelector:@selector(seamlessOrderManagerWillShowSystemLocationPermissionAlert:)]) {
            [self.delegate seamlessOrderManagerWillShowSystemLocationPermissionAlert:self];
        }
        [self.locationManager requestWhenInUseAuthorization];
    } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        self.isWaitingForLocationPermission = YES;
        [self showLocationPermissionAlert];
    } else if ([self isLocationAuthorized]) {
        self.isWaitingForLocationPermission = NO;
        [self updateState:MKSeamlessOrderStateGettingLocation];
        [self startLocationUpdate];
    }
}

- (void)checkLocationPermissionForNonForceCapture {
    [self setupLocationManager];

    CLAuthorizationStatus status = [self getLocationAuthorizationStatus];

    if (status == kCLAuthorizationStatusNotDetermined) {
        if ([self.delegate respondsToSelector:@selector(seamlessOrderManagerWillShowSystemLocationPermissionAlert:)]) {
            [self.delegate seamlessOrderManagerWillShowSystemLocationPermissionAlert:self];
        }
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        if ([self isLocationAuthorized]) {
            [self updateState:MKSeamlessOrderStateGettingLocation];
            [self tryGetLocationForNonForceCapture];
        } else {
            [self submitOrder];
        }
    }
}

- (void)tryGetLocationForNonForceCapture {
    if (self.isLocationUpdating) return;

    CLAuthorizationStatus status = [self getLocationAuthorizationStatus];
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [self submitOrder]; return;
    }
    if (![self isLocationAuthorized]) {
        [self submitOrder]; return;
    }

    self.isLocationUpdating = YES;
    [self.locationManager startUpdatingLocation];

    // 非强抓: 3s 超时, 用 -360 提交
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!wself || wself.hasCalledOrderAPI) return;
        if (!wself.latitude || [wself.latitude isEqualToString:@"-360"]) {
            [wself.locationManager stopUpdatingLocation];
            wself.isLocationUpdating = NO;
            [wself submitOrder];
        }
    });
}

- (void)startLocationUpdate {
    if (self.isLocationUpdating) return;

    CLAuthorizationStatus status = [self getLocationAuthorizationStatus];
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [self notifyFail:@"Location services are disabled"]; return;
    }
    if (![self isLocationAuthorized]) return;

    self.isLocationUpdating = YES;
    [self.locationManager startUpdatingLocation];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count > 0) {
        CLLocation *loc = locations[0];
        self.latitude = [NSString stringWithFormat:@"%.6f", loc.coordinate.latitude];
        self.longitude = [NSString stringWithFormat:@"%.6f", loc.coordinate.longitude];
        [self.locationManager stopUpdatingLocation];
        self.isLocationUpdating = NO;
        if (!self.hasCalledOrderAPI) {
            [self submitOrder];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationManager stopUpdatingLocation];
    self.isLocationUpdating = NO;

    if (error && error.code == kCLErrorDenied) {
        if (self.isForceCaptureFlow) {
            [self notifyFail:@"Location services are disabled"];
        } else {
            [self submitOrder];
        }
        return;
    }

    if (!self.isForceCaptureFlow) {
        [self submitOrder];
    } else {
        [self notifyFail:@"Failed to get location"];
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0)) {
    [self handleAuthChange];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self handleAuthChange];
}

- (void)handleAuthChange {
    CLAuthorizationStatus status;
    if (@available(iOS 14.0, *)) {
        status = self.locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }

    if (self.isForceCaptureFlow) {
        // 等待中 (二次弹窗显示 / 设置返回中 / 新建 locationManager 首回调): 不在这里 cancel
        if (self.isWaitingForLocationPermission) {
            if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
                // 用户从设置返回并授权
                self.isWaitingForLocationPermission = NO;
                [self updateState:MKSeamlessOrderStateGettingLocation];
                [self startLocationUpdate];
            }
            return;
        }

        // 系统权限弹窗的首次结果
        if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
            self.isWaitingForLocationPermission = NO;
            [self updateState:MKSeamlessOrderStateGettingLocation];
            [self startLocationUpdate];
        } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
            // 系统弹窗首次拒绝: notifyMessage("") + cancel — 让 delegate 收掉 loading, 复借弹窗保留, 下次 Apply Now 走自定义弹窗
            self.isWaitingForLocationPermission = NO;
            [self notifyMessage:@""];
            [self cancel];
        }
    } else {
        // 非强抓: 无论同意或拒绝都 submitOrder (用 -360)
        if (self.isProcessing) [self submitOrder];
    }
}

- (void)appWillEnterForeground {
    if (!self.isProcessing) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isWaitingForLocationPermission) {
            CLAuthorizationStatus status;
            if (@available(iOS 14.0, *)) {
                status = self.locationManager.authorizationStatus;
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                status = [CLLocationManager authorizationStatus];
#pragma clang diagnostic pop
            }
            if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
                self.isWaitingForLocationPermission = NO;
                if (self.isForceCaptureFlow) {
                    [self updateState:MKSeamlessOrderStateGettingLocation];
                    [self startLocationUpdate];
                }
            } else {
                // 用户从设置返回仍未授权: notifyMessage("") + cancel,
                // shouldShowMessage 负责收掉 loading, 不发 didCancel (避免业务方误判主动取消)
                self.isWaitingForLocationPermission = NO;
                [self notifyMessage:@"Location permission is required"];
                [self cancel];
            }
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
    // 防重复
    if (self.locationPermissionAlert) return;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self showLocationPermissionAlert]; });
        return;
    }
    [SVProgressHUD dismiss];
    __weak typeof(self) wself = self;
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypePermissionLocation config:nil];
    self.locationPermissionAlert = sheet;

    // Confirm (Go to Settings): 立即 remove 弹窗 (不靠动画 — 跳 Settings 时 background 会打断动画)
    // 不清 isWaiting flag, 让用户从 Settings 返回 appWillEnterForeground 检测授权
    sheet.onConfirmTapped = ^{
        if (wself.locationPermissionAlert) {
            [wself.locationPermissionAlert removeFromSuperview];
            wself.locationPermissionAlert = nil;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:@{} completionHandler:nil];
    };
    // Cancel: 用户主动取消流程
    sheet.onCancelTapped = ^{
        wself.locationPermissionAlert = nil;
        wself.isWaitingForLocationPermission = NO;
        if ([wself.delegate respondsToSelector:@selector(seamlessOrderManagerDidCancelLocationPermission:)]) {
            [wself.delegate seamlessOrderManagerDidCancelLocationPermission:wself];
        }
        [wself cancel];
    };
    [sheet show];
}

- (void)showContactsPermissionAlert {
    if (self.contactsPermissionAlert) return;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self showContactsPermissionAlert]; });
        return;
    }
    [SVProgressHUD dismiss];
    __weak typeof(self) wself = self;
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:MKBottomSheetTypePermissionContacts config:nil];
    self.contactsPermissionAlert = sheet;

    sheet.onConfirmTapped = ^{
        if (wself.contactsPermissionAlert) {
            [wself.contactsPermissionAlert removeFromSuperview];
            wself.contactsPermissionAlert = nil;
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:@{} completionHandler:nil];
    };
    sheet.onCancelTapped = ^{
        wself.contactsPermissionAlert = nil;
        wself.isWaitingForContactsPermission = NO;
        if ([wself.delegate respondsToSelector:@selector(seamlessOrderManagerDidCancelContactsPermission:)]) {
            [wself.delegate seamlessOrderManagerDidCancelContactsPermission:wself];
        }
        [wself cancel];
    };
    [sheet show];
}

#pragma mark - Step 3: Submit Order

- (void)submitOrder {
    // 数据抓取模式: 跳过下单, 复用现有 orderId 直接进设备/通讯录上传
    if (self.isDataCaptureOnly) {
        [self startDataCaptureFlowWithOrderId:self.currentOrderId];
        return;
    }

    if (self.isForceCaptureFlow) {
        if (!self.latitude || [self.latitude isEqualToString:@"-360"] ||
            !self.longitude || [self.longitude isEqualToString:@"-360"]) {
            return;
        }
    }

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
        [self startDataCaptureFlowWithOrderId:orderId];
    } failure:^(NSError *error) {
        [self notifyFail:@"Network error"];
    }];
}

#pragma mark - Step 4: Data Capture (Router) 

- (void)startDataCaptureFlowWithOrderId:(NSString *)orderId {
    // 强抓: 先查通讯录权限, 通过再上传设备 (避免用户不授权时浪费 device 上报)
    // 非强抓: 直接上传设备, 通讯录在 device 之后再说
    if (self.isForceCaptureFlow) {
        [self checkContactsPermissionAfterOrderApplicationWithOrderId:orderId];
    } else {
        [self collectAndUploadDeviceInfoWithOrderId:orderId];
    }
}

#pragma mark - Step 5: Force Capture — 先查通讯录

- (void)checkContactsPermissionAfterOrderApplicationWithOrderId:(NSString *)orderId {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkContactsPermissionAfterOrderApplicationWithOrderId:orderId];
        });
        return;
    }

    [self updateState:MKSeamlessOrderStateCheckingContacts];

    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

    // iOS 18 Limited 在强抓不算授权
    if (@available(iOS 18.0, *)) {
        if (status == CNAuthorizationStatusLimited) {
            [self notifyFail:@"Contacts permission limited - not authorized"];
            return;
        }
    }

    if (status == CNAuthorizationStatusNotDetermined) {
        // 弹系统通讯录权限弹窗
        CNContactStore *store = [[CNContactStore alloc] init];
        __weak typeof(self) wself = self;
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [wself collectAndUploadDeviceInfoWithOrderId:orderId];
                } else {
                    [wself notifyFail:@"Contacts permission denied"];
                }
            });
        }];
    } else if (status == CNAuthorizationStatusAuthorized) {
        [self collectAndUploadDeviceInfoWithOrderId:orderId];
    } else if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted) {
        // 已拒绝: 自定义二次弹窗, 等用户从设置返回
        self.isWaitingForContactsPermission = YES;
        [self showContactsPermissionAlert];
    } else {
        [self notifyFail:@"Contacts permission unknown status"];
    }
}

#pragma mark - Step 6: 上传设备

- (void)collectAndUploadDeviceInfoWithOrderId:(NSString *)orderId {
    [self updateState:MKSeamlessOrderStateUploadingDevice];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *deviceInfo = [MKDeviceTool collectDeviceInfoWithOrderId:orderId];
        if (!deviceInfo || deviceInfo.count == 0) {
            // 设备信息收集失败也继续后续步骤 (与原行为一致, 不阻塞流程)
            if (self.isForceCaptureFlow) {
                [self startContactsUpload];
            } else {
                CNAuthorizationStatus s = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                [self checkContactsNonForce:s];
            }
            return;
        }
        NSDictionary *signData = @{@"orderId": orderId ?: @""};
        NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:signData requestData:deviceInfo];
        [[MKNetworkManager sharedManager] post:@"/app/v3/mobile/device"
                                        params:body
                                       success:^(id resp) {
            // 强抓: 设备上传完直接抓通讯录; 非强抓: 检查通讯录权限
            if (self.isForceCaptureFlow) {
                [self startContactsUpload];
            } else {
                CNAuthorizationStatus s = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                [self checkContactsNonForce:s];
            }
        } failure:^(NSError *e) {
            if (self.isForceCaptureFlow) {
                [self startContactsUpload];
            } else {
                CNAuthorizationStatus s = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                [self checkContactsNonForce:s];
            }
        }];
    });
}

#pragma mark - Step 7: 通讯录 (非强抓) 

- (void)checkContactsForce:(CNAuthorizationStatus)status {
    // 此方法保留兼容. 强抓流程已在 checkContactsPermissionAfterOrderApplicationWithOrderId 中处理.
    if (status == CNAuthorizationStatusAuthorized) {
        [self startContactsUpload];
    } else if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CNAuthorizationStatus cur = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                if (granted && cur == CNAuthorizationStatusAuthorized) {
                    [self startContactsUpload];
                } else {
                    [self notifyFail:@"Contacts permission denied"];
                }
            });
        }];
    } else {
        // 已 Denied / Restricted / iOS18 Limited → 自定义二次弹窗
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
            // 签名只用 orderId，list 和 allowContact 不参与签名
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

    // 签名只用 orderId，allowContact 不参与签名
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
    [self resetInternal];
}

- (void)notifyMessage:(NSString *)message {
    if ([self.delegate respondsToSelector:@selector(seamlessOrderManager:shouldShowMessage:)]) {
        [self.delegate seamlessOrderManager:self shouldShowMessage:message];
    }
}

@end
