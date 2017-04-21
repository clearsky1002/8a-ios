//
//  SPServerManager.m
//  SPMessenger
//
//  Created by Kristoffer Yap on 1/4/16.
//  Copyright © 2016 HigherGround. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "SPServerManager.h"
#import "SPCommunicationManager.h"
#import "UserContext.h"
#import "NSString+URL.h"

@interface SPServerManager()

@property (nonatomic, retain) NSString *access_token;

@end

@implementation SPServerManager

+ (instancetype)sharedInstance {
    static SPServerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    
    // initialize access token
    self.access_token = @"";
    
    return self;
}

- (NSString *)hostUrl {
    UserContext* context = [UserContext sharedInstance];
    return context.httpServerAddress;
}

- (BOOL) isLoggedIn {
    if([self.access_token length]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)getSmsCode:(NSString *)phoneNumber complete:(CompleteCallback)completeBlock {
    NSString* formattedNumber = [phoneNumber getNormalizedPhoneNumber];
    
    NSDictionary* postData = [NSDictionary dictionaryWithObjectsAndKeys:formattedNumber, @"phoneNumber", nil];
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", self.hostUrl, kGetSms];
    [[SPCommunicationManager sharedInstance] postAndReturnDictionary:postData url:requestUrl postCompleted:completeBlock];
}

- (void)login:(NSString*)phoneNumber code:(NSString*) code complete:(CompleteCallback) completeBlock {
    NSString* formattedNumber = [phoneNumber getNormalizedPhoneNumber];
    NSDictionary* postData = [NSDictionary dictionaryWithObjectsAndKeys:formattedNumber, @"phoneNumber",
                              code, @"confirmationCode", nil];
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", self.hostUrl, kLogin];
    [[SPCommunicationManager sharedInstance] postAndReturnDictionary:postData url:requestUrl postCompleted:^(BOOL success, SPAPIResponse *response) {
        if(success) {
            self.access_token = [response.jsonObject objectForKey:@"token"];
        }
        completeBlock(success, response);
    }];
}

- (void)logout:(CompleteCallback) completeBlock {
    NSDictionary* postData = [NSDictionary dictionaryWithObjectsAndKeys:self.access_token, @"Authroization", nil];
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", self.hostUrl, kLogout];
    [[SPCommunicationManager sharedInstance] postAndReturnDictionary:postData url:requestUrl postCompleted:^(BOOL success, SPAPIResponse *response) {
        self.access_token = nil;
        completeBlock(success, response);
    }];
}

@end
