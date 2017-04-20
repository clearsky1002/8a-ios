//
//  SPNetworkReachability.h
//  LibBle
//
//  Created by Kristoffer Yap on 4/7/17.
//  Copyright © 2017 Kristoffer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <SBJson4Writer.h>

typedef enum : unsigned char
{
    SPNetworkReachabilityStatusNotReachable = 1 << 0,
    SPNetworkReachabilityStatusWWAN         = 1 << 1,
    SPNetworkReachabilityStatusWiFi         = 1 << 2
} SPNetworkReachabilityStatus;

extern NSString * const kSPNetworkReachabilityDidChangeNotification;
extern NSString * const kSPNetworkReachabilityStatusKey;

@interface SPNetworkReachability : NSObject

+ (instancetype)reachabilityWithHostName:(NSString *)hostName;

+ (instancetype)reachabilityWithHostAddress:(const struct sockaddr *)hostAddress;

+ (instancetype)reachabilityWithInternetAddress:(in_addr_t)internetAddress;

+ (instancetype)reachabilityWithInternetAddressString:(NSString *)internetAddress;

+ (instancetype)reachabilityWithIPv6Address:(const struct in6_addr)internetAddress;

+ (instancetype)reachabilityWithIPv6AddressString:(NSString *)internetAddress;

+ (instancetype)reachabilityForInternetConnection;

+ (instancetype)reachabilityForLocalWiFi;


- (id)initWithHostAddress:(const struct sockaddr *)hostAddress;

- (id)initWithHostName:(NSString *)hostName;

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability;


- (void)startMonitoringNetworkReachabilityWithHandler:(void(^)(SPNetworkReachabilityStatus status))block;

- (void)startMonitoringNetworkReachabilityWithNotification;

- (void)stopMonitoringNetworkReachability;


- (SPNetworkReachabilityStatus)currentReachabilityStatus;


- (BOOL)isReachable;

- (BOOL)isReachableViaWiFi;

#if TARGET_OS_IPHONE
- (BOOL)isReachableViaWWAN;
#endif

- (SCNetworkReachabilityFlags)reachabilityFlags;

@end
