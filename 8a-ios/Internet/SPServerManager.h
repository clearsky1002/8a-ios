//
//  SPServerManager.h
//  SPMessenger
//
//  Created by Kristoffer Yap on 1/4/16.
//  Copyright © 2016 HigherGround. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPCommunicationManager.h"

#define kDevServerUrl               @"http://dev-api.wwl.tv/api/v1"

#define kGetSms                     @"/login/request-code"
#define kLogin                      @"/login"
#define kLogout                     @"/logout"

@interface SPServerManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL) isLoggedIn;
- (void)getSmsCode:(NSString *)phoneNumber complete:(CompleteCallback)completeBlock;
- (void)login:(NSString*)phoneNumber code:(NSString*) code complete:(CompleteCallback) completeBlock;
- (void)logout:(CompleteCallback) completeBlock;

@end
