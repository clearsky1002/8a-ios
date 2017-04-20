//
//  UserContext.m
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import "UserContext.h"
#import "SPServerManager.h"

#define HTTP_SERVER_ADDR    @"http_server_addr"

@implementation UserContext

static UserContext *sharedInstance = nil;

+ (id)sharedInstance {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[UserContext alloc] init];
        }
        return sharedInstance;
    }
}

+ (void)resetSharedInstance {
    @synchronized(self) {
        sharedInstance = nil;
    }
}

- (id)init {
    self = [super init];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSObject *obj = [userDefaults objectForKey:HTTP_SERVER_ADDR];
    if(obj != nil) {
        _httpServerAddress = (NSString *)obj;
    } else {
        _httpServerAddress = kDevServerUrl;
    }
    
    return self;
}

-(void)setHttpServerAddress:(NSString *)httpServerAddress {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _httpServerAddress = httpServerAddress;
    [userDefaults setObject:httpServerAddress forKey:HTTP_SERVER_ADDR];
    [userDefaults synchronize];
}

@end
