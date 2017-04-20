//
//  SPNetworkReachability.m
//  LibBle
//
//  Created by Kristoffer Yap on 4/7/17.
//  Copyright © 2017 Kristoffer. All rights reserved.
//

#import "SPNetworkReachability.h"
#import <arpa/inet.h>

#if ! __has_feature(objc_arc)
#   error SPNetworkReachability is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

#ifdef DEBUG
#   define SPNRLog(fmt, ...) NSLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define SPNRLog(...) do {} while(0)
#endif

#if TARGET_OS_IPHONE
#   if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#       define SP_DISPATCH_RELEASE(v) do {} while(0)
#   else
#       define SP_DISPATCH_RELEASE(v) dispatch_release(v)
#   endif
#else
#   if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
#       define SP_DISPATCH_RELEASE(v) do {} while(0)
#   else
#       define SP_DISPATCH_RELEASE(v) dispatch_release(v)
#   endif
#endif

struct SPNetworkReachabilityFlagContext
{
    SCNetworkReachabilityRef target;
    uint32_t *value;
};

static BOOL _localWiFi = NO;
static dispatch_queue_t _reachability_queue, _lock_queue;

NSString * const kSPNetworkReachabilityDidChangeNotification    = @"NetworkReachabilityDidChangeNotification";
NSString * const kSPNetworkReachabilityStatusKey                = @"NetworkReachabilityStatusKey";

@interface SPNetworkReachability ()

@end

@implementation SPNetworkReachability
{
    SCNetworkReachabilityRef _networkReachability;
    void(^_handler_blk)(SPNetworkReachabilityStatus);
}

static inline dispatch_queue_t SPNetworkReachabilityLockQueue()
{
    return _lock_queue ?: (_lock_queue = dispatch_queue_create("com.spnetworkreachability.queue.lock", DISPATCH_QUEUE_SERIAL));
}

static void SPNetworkReachabilityPrintFlags(SCNetworkReachabilityFlags flags)
{
#if PRINT_REACHABILITY_FLAGS
    SPNRLog(@"SPNetworkReachability Flag Status: %c%c %c%c%c%c%c%c%c",
#if TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
#else
            '-',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'
            );
#endif
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName
{
    assert(hostName);
    
    return [[self alloc] initWithReachability:SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String])];
}

+ (instancetype)reachabilityWithHostAddress:(const struct sockaddr *)hostAddress
{
    assert(hostAddress);
    
    return [[self alloc] initWithReachability:SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress)];
}

static void SPNetworkReachabilitySetSocketAddress(struct sockaddr_in *addr)
{
    memset(addr, 0, sizeof(struct sockaddr_in));
    addr->sin_len = sizeof(struct sockaddr_in);
    addr->sin_family = AF_INET;
}

+ (instancetype)reachabilityWithInternetAddress:(in_addr_t)internetAddress
{
    assert(internetAddress >= (in_addr_t)0);
    
    struct sockaddr_in addr;
    SPNetworkReachabilitySetSocketAddress(&addr);
    addr.sin_addr.s_addr = htonl(internetAddress);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

+ (instancetype)reachabilityWithInternetAddressString:(NSString *)internetAddress
{
    assert(internetAddress);
    
    struct sockaddr_in addr;
    SPNetworkReachabilitySetSocketAddress(&addr);
    inet_pton(AF_INET, [internetAddress UTF8String], &addr.sin_addr);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

+ (instancetype)reachabilityForInternetConnection
{
    static const in_addr_t zeroAddr = INADDR_ANY;
    return [self reachabilityWithInternetAddress:zeroAddr];
}

+ (instancetype)reachabilityForLocalWiFi
{
    _localWiFi = YES;
    
    static const in_addr_t localAddr = IN_LINKLOCALNETNUM;
    return [self reachabilityWithInternetAddress:localAddr];
}

static void SPNetworkReachabilitySetIPv6SocketAddress(struct sockaddr_in6 *addr)
{
    memset(addr, 0, sizeof(struct sockaddr_in6));
    addr->sin6_len = sizeof(struct sockaddr_in6);
    addr->sin6_family = AF_INET6;
}

+ (instancetype)reachabilityWithIPv6Address:(const struct in6_addr)internetAddress
{
    assert(&internetAddress);
    
    char strAddr[INET6_ADDRSTRLEN];
    
    struct sockaddr_in6 addr;
    SPNetworkReachabilitySetIPv6SocketAddress(&addr);
    addr.sin6_addr = internetAddress;
    inet_ntop(AF_INET6, &addr.sin6_addr, strAddr, INET6_ADDRSTRLEN);
    inet_pton(AF_INET6, strAddr, &addr.sin6_addr);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

+ (instancetype)reachabilityWithIPv6AddressString:(NSString *)internetAddress
{
    assert(internetAddress);
    
    struct sockaddr_in6 addr;
    SPNetworkReachabilitySetIPv6SocketAddress(&addr);
    inet_pton(AF_INET6, [internetAddress UTF8String], &addr.sin6_addr);
    return [self reachabilityWithHostAddress:(const struct sockaddr *)&addr];
}

- (id)initWithHostAddress:(const struct sockaddr *)hostAddress
{
    assert(hostAddress);
    
    return [self initWithReachability:SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress)];
}

- (id)initWithHostName:(NSString *)hostName
{
    assert(hostName);
    
    return [self initWithReachability:SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String])];
}

- (id)initWithReachability:(SCNetworkReachabilityRef)reachability
{
    self = [super init];
    if (self)
    {
        if (!reachability)
        {
            SPNRLog(@"SCNetworkReachabilityRef failed with error code: %s", SCErrorString(SCError()));
            return nil;
        }
        
        self->_networkReachability = reachability;
    }
    return self;
}

- (void)createReachabilityQueue
{
    _reachability_queue = dispatch_queue_create("com.spnetworkreachability.queue.callback", DISPATCH_QUEUE_SERIAL);
    
    if (!SCNetworkReachabilitySetDispatchQueue(self->_networkReachability, _reachability_queue))
    {
        SPNRLog(@"SCNetworkReachabilitySetDispatchQueue() failed with error code: %s", SCErrorString(SCError()));
        
        [self releaseReachabilityQueue];
    }
}

- (void)releaseReachabilityQueue
{
    if (self->_networkReachability) SCNetworkReachabilitySetDispatchQueue(self->_networkReachability, NULL);
    
    if (_reachability_queue)
    {
        SP_DISPATCH_RELEASE(_reachability_queue);
        _reachability_queue = NULL;
    }
}

- (void)dealloc
{
    [self stopMonitoringNetworkReachability];
    
    if (self->_networkReachability)
    {
        CFRelease(self->_networkReachability);
        self->_networkReachability = NULL;
    }
    
    if (_lock_queue)
    {
        SP_DISPATCH_RELEASE(_lock_queue);
        _lock_queue = NULL;
    }
}

static SPNetworkReachabilityStatus SPNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags)
{
    SPNetworkReachabilityStatus status = (SPNetworkReachabilityStatus)0;
    
    if (flags & kSCNetworkFlagsReachable)
    {
        if (_localWiFi)
        {
            status |= (flags & kSCNetworkReachabilityFlagsIsDirect) ? SPNetworkReachabilityStatusWiFi : SPNetworkReachabilityStatusNotReachable;
        }
        else if ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) || (flags & kSCNetworkReachabilityFlagsConnectionOnDemand))
        {
            if (flags & kSCNetworkReachabilityFlagsInterventionRequired)
            {
                status |= (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? SPNetworkReachabilityStatusNotReachable : SPNetworkReachabilityStatusWiFi;
            }
            else
            {
                status |= SPNetworkReachabilityStatusWiFi;
            }
        }
        else
        {
            status |= (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? SPNetworkReachabilityStatusNotReachable : SPNetworkReachabilityStatusWiFi;
        }
        
#if TARGET_OS_IPHONE
        if (flags & kSCNetworkReachabilityFlagsIsWWAN)
        {
            status &= ~(SPNetworkReachabilityStatusWiFi | SPNetworkReachabilityStatusNotReachable);
            status |= SPNetworkReachabilityStatusWWAN;
        }
#endif
        
    }
    else
    {
        status |= SPNetworkReachabilityStatusNotReachable;
    }
    return status;
}

static void SPNetworkReachabilityGetCurrentStatus(void *context)
{
    struct SPNetworkReachabilityFlagContext *ctx = context;
    SCNetworkReachabilityFlags flags = (SCNetworkReachabilityFlags)0;
    static uint32_t currentStatus = SPNetworkReachabilityStatusNotReachable;
    
    if (!SCNetworkReachabilityGetFlags(ctx->target, &flags))
    {
        SPNRLog(@"SCNetworkReachabilityGetFlags() failed with error code: %s", SCErrorString(SCError()));
        ctx->value = &currentStatus;
        return;
    }
    
    currentStatus = SPNetworkReachabilityStatusForFlags(flags);
    ctx->value = &currentStatus;
}

- (SPNetworkReachabilityStatus)currentReachabilityStatus
{
    static uint32_t status;
    struct SPNetworkReachabilityFlagContext context = {
        
        self->_networkReachability,
        &status
    };
    dispatch_sync_f(SPNetworkReachabilityLockQueue(), &context, SPNetworkReachabilityGetCurrentStatus);
    return *context.value;
}

- (BOOL)isReachable
{
    return [self currentReachabilityStatus] != SPNetworkReachabilityStatusNotReachable;
}

- (BOOL)isReachableViaWiFi
{
    return [self currentReachabilityStatus] & SPNetworkReachabilityStatusWiFi;
}

#if TARGET_OS_IPHONE
- (BOOL)isReachableViaWWAN
{
    return [self currentReachabilityStatus] & SPNetworkReachabilityStatusWWAN;
}
#endif

static void SPNetworkReachabilityGetFlags(void *context)
{
    struct SPNetworkReachabilityFlagContext *ctx = context;
    
    if (!SCNetworkReachabilityGetFlags(ctx->target, ctx->value))
    {
        SPNRLog(@"SCNetworkReachabilityGetFlags() failed with error code: %s", SCErrorString(SCError()));
        static uint32_t zeroVal = 0;
        ctx->value = &zeroVal;
    }
}

- (SCNetworkReachabilityFlags)reachabilityFlags
{
    static uint32_t flags;
    struct SPNetworkReachabilityFlagContext context = {
        
        self->_networkReachability,
        &flags
    };
    dispatch_sync_f(SPNetworkReachabilityLockQueue(), &context, SPNetworkReachabilityGetFlags);
    return *context.value;
}


static const void * SPNetworkReachabilityRetainCallback(const void *info)
{
    void(^blk)(SPNetworkReachabilityStatus) = (__bridge void(^)(SPNetworkReachabilityStatus))info;
    return CFBridgingRetain(blk);
}

static void SPNetworkReachabilityReleaseCallback(const void *info)
{
    CFRelease(info);
}

static void SPNetworkReachabilityCallbackWithBlock(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info)
{
    SPNetworkReachabilityStatus status = SPNetworkReachabilityStatusForFlags(flags);
    void(^cb_blk)(SPNetworkReachabilityStatus) = (__bridge void(^)(SPNetworkReachabilityStatus))info;
    if (cb_blk) cb_blk(status);
    
    SPNetworkReachabilityPrintFlags(flags);
}

static void SPNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info)
{
    SPNetworkReachabilityStatus status = SPNetworkReachabilityStatusForFlags(flags);
    [[NSNotificationCenter defaultCenter] postNotificationName:kSPNetworkReachabilityDidChangeNotification
                                                        object:(__bridge SPNetworkReachability *)info
                                                      userInfo:@{kSPNetworkReachabilityStatusKey : @(status)}];
    
    SPNetworkReachabilityPrintFlags(flags);
}

- (void)startMonitoringNetworkReachabilityWithHandler:(void(^)(SPNetworkReachabilityStatus))block
{
    if (!block) return;
    
    self->_handler_blk = [block copy];
    
    SPNetworkReachability * __weak w_self = self;
    
    void(^cb_blk)(SPNetworkReachabilityStatus) = ^(SPNetworkReachabilityStatus status) {
        
        SPNetworkReachability *s_self = w_self;
        if (s_self) dispatch_async(dispatch_get_main_queue(), ^{s_self->_handler_blk(status);});
    };
    
    SCNetworkReachabilityContext context = {
        
        0,
        (__bridge void *)(cb_blk),
        SPNetworkReachabilityRetainCallback,
        SPNetworkReachabilityReleaseCallback,
        NULL
    };
    
    if (!SCNetworkReachabilitySetCallback(self->_networkReachability, SPNetworkReachabilityCallbackWithBlock, &context))
    {
        SPNRLog(@"SCNetworkReachabilitySetCallbackWithBlock() failed with error code: %s", SCErrorString(SCError()));
        return;
    }
    
    [self createReachabilityQueue];
}

- (void)startMonitoringNetworkReachabilityWithNotification
{
    SCNetworkReachabilityContext context = {
        
        0,
        (__bridge void *)(self),
        NULL,
        NULL,
        NULL
    };
    
    if (!SCNetworkReachabilitySetCallback(self->_networkReachability, SPNetworkReachabilityCallback, &context))
    {
        SPNRLog(@"SCNetworkReachabilitySetCallback() failed with error code: %s", SCErrorString(SCError()));
        return;
    }
    
    [self createReachabilityQueue];
}

- (void)stopMonitoringNetworkReachability
{
    if (self->_networkReachability) SCNetworkReachabilitySetCallback(self->_networkReachability, NULL, NULL);
    
    if (self->_handler_blk) self->_handler_blk = nil;
    
    [self releaseReachabilityQueue];
}


@end
