//
//  MKDeviceTool.m
//  PHI372-DC
//

#import "MKDeviceTool.h"
#import "MKCommonParams.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <AdSupport/ASIdentifierManager.h>
#import <Contacts/Contacts.h>

@implementation MKDeviceTool

#pragma mark - Hardware identifier (inlined from 334 RDDeviceInfo)

+ (NSString *)hardwareMachineIdentifier {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"";
}

#pragma mark - Device Info

+ (NSDictionary *)collectDeviceInfoWithOrderId:(NSString *)orderId {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[@"orderId"] = orderId ?: @"";

    // Identifiers
    info[@"uuid"] = [UIDevice currentDevice].identifierForVendor.UUIDString ?: @"";
    info[@"idfv"] = [UIDevice currentDevice].identifierForVendor.UUIDString ?: @"";
    info[@"idfa"] = [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString ?: @"";
    info[@"androidId"] = @"";
    info[@"gaid"] = @"";

    // Device
    info[@"phoneMark"] = [UIDevice currentDevice].name ?: @"";
    info[@"phoneType"] = [self hardwareMachineIdentifier] ?: @"";
    info[@"phoneBrand"] = @"Apple";
    info[@"phoneBoard"] = @"";
    info[@"systemVersions"] = [UIDevice currentDevice].systemVersion ?: @"";
    info[@"versionCode"] = [MKCommonParams shared].clientVersion ?: @"";
    info[@"versionName"] = [MKCommonParams shared].appDisplayVersion ?: @"";
    info[@"sdkVersion"] = @"";
    info[@"productionDate"] = @"";
    info[@"serial"] = @"";
    info[@"operatingSystem"] = @"2"; // iOS

    // Screen
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat scale = [UIScreen mainScreen].scale;
    NSInteger w = (NSInteger)(screenBounds.size.width * scale);
    NSInteger h = (NSInteger)(screenBounds.size.height * scale);
    info[@"screenResolution"] = [NSString stringWithFormat:@"%ldx%ld", (long)w, (long)h];
    info[@"screenWidth"] = @(w).stringValue;
    info[@"screenHeight"] = @(h).stringValue;
    info[@"screenBrightness"] = [NSString stringWithFormat:@"%.2f", [UIScreen mainScreen].brightness];

    // CPU
    info[@"cpuNum"] = @([NSProcessInfo processInfo].processorCount).stringValue;

    // Memory (GB)
    unsigned long long totalRAM = [NSProcessInfo processInfo].physicalMemory;
    info[@"ramTotal"] = [NSString stringWithFormat:@"%.6f", totalRAM / 1073741824.0];

    mach_port_t host = mach_host_self();
    vm_size_t pageSize;
    host_page_size(host, &pageSize);
    vm_statistics64_data_t vmStat;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    if (host_statistics64(host, HOST_VM_INFO64, (host_info64_t)&vmStat, &count) == KERN_SUCCESS) {
        unsigned long long freeRAM = (unsigned long long)(vmStat.free_count + vmStat.inactive_count) * pageSize;
        info[@"ramCanUse"] = [NSString stringWithFormat:@"%.6f", freeRAM / 1073741824.0];
    } else {
        info[@"ramCanUse"] = @"0";
    }

    // Storage (GB)
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    if (attrs) {
        unsigned long long totalDisk = [attrs[NSFileSystemSize] unsignedLongLongValue];
        unsigned long long freeDisk = [attrs[NSFileSystemFreeSize] unsignedLongLongValue];
        info[@"cashTotal"] = [NSString stringWithFormat:@"%.6f", totalDisk / 1073741824.0];
        info[@"cashCanUse"] = [NSString stringWithFormat:@"%.6f", freeDisk / 1073741824.0];
    }

    // Battery
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    info[@"batteryLevel"] = [NSString stringWithFormat:@"%d", (int)(batteryLevel * 100)];
    info[@"batteryMax"] = @"100";
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    info[@"isCharging"] = (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull) ? @"true" : @"false";

    // Uptime
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    info[@"totalBootTime"] = [NSString stringWithFormat:@"%.0f", uptime];
    info[@"totalBootTimeWake"] = [NSString stringWithFormat:@"%.0f", uptime];

    // Locale
    info[@"defaultLanguage"] = [NSLocale preferredLanguages].firstObject ?: @"en";
    info[@"defaultTimeZone"] = [NSTimeZone localTimeZone].name ?: @"";

    // Network
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    if (@available(iOS 12.0, *)) {
        NSDictionary *carriers = netInfo.serviceSubscriberCellularProviders;
        NSArray *keys = carriers.allKeys;
        if (keys.count > 0) {
            CTCarrier *c = carriers[keys[0]];
            info[@"telephony"] = c.carrierName ?: @"";
        }
        if (keys.count > 1) {
            CTCarrier *c = carriers[keys[1]];
            info[@"telephony2"] = c.carrierName ?: @"";
        }
        info[@"slotCount"] = @(keys.count).stringValue;
        info[@"simCount"] = @(keys.count).stringValue;
    } else {
        CTCarrier *carrier = netInfo.subscriberCellularProvider;
        info[@"telephony"] = carrier.carrierName ?: @"";
        info[@"telephony2"] = @"";
        info[@"slotCount"] = @"1";
        info[@"simCount"] = carrier ? @"1" : @"0";
    }

    info[@"network"] = [self currentNetworkType] ?: @"unknown";
    info[@"mac"] = @"";
    info[@"wifiName"] = @"";

    // Security
    info[@"rooted"] = [self isJailbroken] ? @"true" : @"false";
    info[@"debugged"] = @"false";
    info[@"simulated"] = [self isSimulator] ? @"true" : @"false";
    info[@"isvpn"] = [self isVPNConnected] ? @"true" : @"false";
    info[@"proxied"] = @"false";

    // Misc
    info[@"deviceType"] = @"1";
    info[@"lastBootTime"] = @"";
    info[@"videoInternal"] = @"-99";
    info[@"imageInternal"] = @"-99";
    info[@"albumFile"] = @"-99";
    info[@"phoneNum"] = @"";
    info[@"phoneNum2"] = @"";

    return [info copy];
}

#pragma mark - Network Type

+ (NSString *)currentNetworkType {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSString *radio = nil;
    if (@available(iOS 12.0, *)) {
        NSDictionary *radios = info.serviceCurrentRadioAccessTechnology;
        radio = radios.allValues.firstObject;
    }
    if (!radio) return @"WiFi"; // fallback

    if ([radio isEqualToString:CTRadioAccessTechnologyLTE]) return @"4G";
    if (@available(iOS 14.1, *)) {
        if ([radio isEqualToString:CTRadioAccessTechnologyNRNSA] ||
            [radio isEqualToString:CTRadioAccessTechnologyNR]) return @"5G";
    }
    if ([radio isEqualToString:CTRadioAccessTechnologyWCDMA] ||
        [radio isEqualToString:CTRadioAccessTechnologyHSDPA] ||
        [radio isEqualToString:CTRadioAccessTechnologyHSUPA]) return @"3G";
    return @"2G";
}

#pragma mark - Security Checks

+ (BOOL)isJailbroken {
    NSArray *paths = @[@"/Applications/Cydia.app", @"/usr/sbin/sshd",
                       @"/bin/bash", @"/private/var/lib/apt/"];
    for (NSString *path in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return YES;
    }
    return NO;
}

+ (BOOL)isSimulator {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isVPNConnected {
    NSDictionary *proxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
    NSDictionary *scoped = proxySettings[@"__SCOPED__"];
    for (NSString *key in scoped.allKeys) {
        if ([key containsString:@"tap"] || [key containsString:@"tun"] ||
            [key containsString:@"ppp"] || [key containsString:@"ipsec"]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Contacts

+ (NSArray<NSArray<NSDictionary *> *> *)collectContactsWithMaxCount:(NSInteger)maxCount
                                                           perCount:(NSInteger)perCount {
    if (maxCount <= 0) maxCount = 1000;
    if (perCount <= 0) perCount = 100;

    CNContactStore *store = [[CNContactStore alloc] init];
    NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];

    NSMutableArray<NSDictionary *> *allContacts = [NSMutableArray array];
    [store enumerateContactsWithFetchRequest:request error:nil
                                  usingBlock:^(CNContact *contact, BOOL *stop) {
        if ((NSInteger)allContacts.count >= maxCount) { *stop = YES; return; }
        NSString *name = [NSString stringWithFormat:@"%@ %@",
                          contact.givenName ?: @"", contact.familyName ?: @""];
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (CNLabeledValue<CNPhoneNumber *> *pv in contact.phoneNumbers) {
            if ((NSInteger)allContacts.count >= maxCount) break;
            NSString *phone = pv.value.stringValue ?: @"";
            if (phone.length == 0) continue;
            [allContacts addObject:@{@"name": name ?: @"", @"phone": phone}];
        }
    }];

    // 分批
    NSMutableArray<NSArray<NSDictionary *> *> *batches = [NSMutableArray array];
    NSInteger total = allContacts.count;
    for (NSInteger i = 0; i < total; i += perCount) {
        NSInteger len = MIN(perCount, total - i);
        [batches addObject:[allContacts subarrayWithRange:NSMakeRange(i, len)]];
    }
    return [batches copy];
}

@end
