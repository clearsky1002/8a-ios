//
//  SPCommunicationManager.h
//  SPMessenger
//
//  Created by Kristoffer Yap on 1/4/16.
//  Copyright © 2016 HigherGround. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPAPIResponse.h"

typedef void (^CompleteCallback)(BOOL success, SPAPIResponse *response);
typedef void (^CompleteCallbackWithError)(BOOL success, NSString* error, SPAPIResponse *response);
typedef void (^ProgressCallback)(int progress);
typedef void (^ProgressFloatCallback)(float progress);

@interface SPCommunicationManager : NSObject

+ (instancetype)sharedInstance;

- (void)postAndReturnDictionary:(NSDictionary *)params url:(NSString *)url postCompleted:(CompleteCallback)block;
- (void)postAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url postCompleted:(CompleteCallback)block;
- (void)postFormUrlAndReturnDictionary:(NSData *)params url:(NSString *)url postCompleted:(CompleteCallback)block ;
- (void)postFormUrlAndReturnData:(NSData*)params url:(NSString *)url postCompleted:(CompleteCallback)block;

- (void)deleteAndReturnDictionary:(NSDictionary *)params url:(NSString *)url deleteCompleted:(CompleteCallback)block;

- (void)deleteAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url deleteCompleted:(CompleteCallback)block;

- (void)putAndReturnDictionary:(NSDictionary *)params url:(NSString *)url putCompleted:(CompleteCallback)block;
- (void)putAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url putCompleted:(CompleteCallback)block;
- (void)putFormUrlAndReturnDictionary:(NSData*)params url:(NSString *)url postCompleted:(CompleteCallback)block;

- (void)getAndReturnDictionary:(NSDictionary *)params url:(NSString *)url getCompleted:(CompleteCallback)block;
- (void)getAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url getCompleted:(CompleteCallback)block;

- (void)getAndReturnDictionaryWithoutParameters:(NSString *)url getCompleted:(CompleteCallback)block;

- (void)actionWithRequest:(NSURLRequest *)request actionCompleted:(CompleteCallback)block;

@end
