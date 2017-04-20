//
//  SPCommunicationManager.m
//  SPMessenger
//
//  Created by Kristoffer Yap on 1/4/16.
//  Copyright © 2016 HigherGround. All rights reserved.
//

#import "SPCommunicationManager.h"
#import "SPNetworkReachability.h"
#import "NSDictionary+Http.h"

@implementation SPCommunicationManager

+ (instancetype)sharedInstance {
    static SPCommunicationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

//MARK: Helpers
- (void)actionAndReturnDictionary:(NSString *)verb params:(NSDictionary *)params url:(NSString *)url actionComplete:(CompleteCallback)block {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = verb;
    
    //add the post parameters
    SBJson4Writer *sbJsonWriter = [[SBJson4Writer alloc] init];
    request.HTTPBody = [sbJsonWriter dataWithObject:params];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //    SPLog(@"action: %@, url: %@", verb, url);
    //    SPLog(@"params: %@", params);
    
    [self actionWithRequest:request actionCompleted: block];
}

- (void)actionFormRequestAndReturnDictionary:(NSString *)verb params:(NSData *)postData url:(NSString *)url actionComplete:(CompleteCallback)block {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = verb;
    
    //add the post parameters
    [request setHTTPBody:postData];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    [request addValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //    SPLog(@"action: %@, url: %@", verb, url);
    //    SPLog(@"PARAM DATA SIZE:%lu", (unsigned long)[postData length]);
    
    [self actionWithRequest:request actionCompleted: block];
}

- (void)actionFormRequestAndReturnData:(NSString *)verb params:(NSData *)postData url:(NSString *)url actionComplete:(CompleteCallback)block {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = verb;
    
    //add the post parameters
    [request setHTTPBody:postData];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    [request addValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [self actionWithRequestData:request actionCompleted: block];
}

- (void)actionAndReturnDictionary:(NSString *)verb params:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url actionComplete:(CompleteCallback)block {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = verb;
    NSError *err = nil;
    
    //add the post parameters
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:&err];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //    SPLog(@"action: %@, url: %@", verb, url);
    //    SPLog(@"params: %@", params);
    //    SPLog(@"headers: %@", headers);
    
    for (NSString *key in [headers allKeys]) {
        NSString *value = [headers objectForKey:key];
        [request addValue:value forHTTPHeaderField:key];
    }
    
    [self actionWithRequest:request actionCompleted: block];
}


- (void)actionWithRequest:(NSURLRequest *)request actionCompleted:(CompleteCallback)block {
    if([[SPNetworkReachability reachabilityForInternetConnection] isReachable]) {
        NSURLSession *session = [NSURLSession sharedSession];
        
        //create the task
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (response != nil) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                //get the status code
                int statusCode = (int)httpResponse.statusCode;
                
                BOOL success = statusCode >= 200 & statusCode < 300;
                if (success && data != nil) {
                    NSError *err = nil;
                    NSDictionary *json = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                    if (json != nil) {
                        json = [self nullFreeDictionaryWithDictionary:json];
                        SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:json];
                        apiResponse.responseCode = statusCode;
                        block(success, apiResponse);
                    }
                    else {
                        SPAPIResponse *apiResponse = [[SPAPIResponse alloc] init];
                        apiResponse.responseCode = statusCode;
                        block(success, apiResponse);
                    }
                }
                else {
                    SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:[self getHttpStatusError:statusCode]];
                    apiResponse.responseCode = statusCode;
                    
                    block(NO, apiResponse);
                }
                
            }
            else{
                SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:[self getNetworkError:error]];
                block(NO, apiResponse);
            }
        }];
        
        [task resume];
    }
    else {
        NSError *error = [NSError errorWithDomain:@"" code:NSURLErrorNotConnectedToInternet userInfo:nil];
        SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:[self getNetworkError:error]];
        block(NO, apiResponse);
    }
}

- (void)actionWithRequestData:(NSURLRequest *)request actionCompleted:(CompleteCallback)block {
    if([[SPNetworkReachability reachabilityForInternetConnection] isReachable]) {
        NSURLSession *session = [NSURLSession sharedSession];
        
        //create the task
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (response != nil) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                //get the status code
                int statusCode = (int)httpResponse.statusCode;
                if (statusCode == 200 && data != nil) {
                    SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromDataObject:data];
                    apiResponse.responseCode = statusCode;
                    block(statusCode==200, apiResponse);
                }
                else {
                    SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:[self getHttpStatusError:statusCode]];
                    apiResponse.responseCode = statusCode;
                    
                    block(NO, apiResponse);
                }
                
            }
            else{
                SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:[self getNetworkError:error]];
                block(NO, apiResponse);
            }
        }];
        
        [task resume];
    }
    else {
        NSError *error = [NSError errorWithDomain:@"" code:NSURLErrorNotConnectedToInternet userInfo:nil];
        SPAPIResponse *apiResponse = [[SPAPIResponse alloc] initFromJsonObject:[self getNetworkError:error]];
        block(NO, apiResponse);
    }
}

- (void)postAndReturnDictionary:(NSDictionary *)params url:(NSString *)url postCompleted:(CompleteCallback)block {
    [self actionAndReturnDictionary:@"POST" params:params url:url actionComplete:block];
}

- (void)postFormUrlAndReturnDictionary:(NSData*)params url:(NSString *)url postCompleted:(CompleteCallback)block {
    [self actionFormRequestAndReturnDictionary:@"POST" params:params url:url actionComplete:block];
}

- (void)postFormUrlAndReturnData:(NSData*)params url:(NSString *)url postCompleted:(CompleteCallback)block {
    [self actionFormRequestAndReturnData:@"POST" params:params url:url actionComplete:block];
}

- (void)postAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url postCompleted:(CompleteCallback)block {
    [self actionAndReturnDictionary:@"POST" params:params headers:headers url:url actionComplete:block];
}

- (void)deleteAndReturnDictionary:(NSDictionary *)params url:(NSString *)url deleteCompleted:(CompleteCallback)block {
    [self actionAndReturnDictionary:@"DELETE" params:params url:url actionComplete:block];
}

- (void)deleteAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url deleteCompleted:(CompleteCallback)block {
    [self actionAndReturnDictionary:@"DELETE" params:params headers:headers url:url actionComplete:block];
}

- (void)putAndReturnDictionary:(NSDictionary *)params url:(NSString *)url putCompleted:(CompleteCallback)block {
    [self actionAndReturnDictionary:@"PUT" params:params url:url actionComplete:block];
}

- (void)putAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url putCompleted:(CompleteCallback)block {
    [self actionAndReturnDictionary:@"PUT" params:params headers:headers url:url actionComplete:block];
}

- (void)putFormUrlAndReturnDictionary:(NSData*)params url:(NSString *)url postCompleted:(CompleteCallback)block {
    [self actionFormRequestAndReturnDictionary:@"PUT" params:params url:url actionComplete:block];
}

- (void)getAndReturnDictionary:(NSDictionary *)params url:(NSString *)url getCompleted:(CompleteCallback)block {
    NSString *paramsString = [params stringFromHttpParameters];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url, paramsString]]];
    request.HTTPMethod = @"GET";
    
    [request addValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField: @"Accept"];
    
    //    SPLog(@"action: GET, url: %@", url);
    //    SPLog(@"params: %@", params);
    
    [self actionWithRequest:request actionCompleted: block];
}

- (void)getAndReturnDictionary:(NSDictionary *)params headers:(NSDictionary *)headers url:(NSString *)url getCompleted:(CompleteCallback)block {
    NSString *paramsString = [params stringFromHttpParameters];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url, paramsString]]];
    request.HTTPMethod = @"GET";
    
    [request addValue:@"application/json" forHTTPHeaderField: @"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField: @"Accept"];
    
    //    SPLog(@"action: GET, url: %@", url);
    //    SPLog(@"params: %@", params);
    //    SPLog(@"headers: %@", headers);
    
    for (NSString *key in [headers allKeys]) {
        NSString *value = [headers objectForKey:key];
        [request addValue:value forHTTPHeaderField:key];
    }
    
    [self actionWithRequest:request actionCompleted: block];
}

- (void)getAndReturnDictionaryWithoutParameters:(NSString *)url getCompleted:(CompleteCallback)block {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //    SPLog(@"action: GET, url: %@", url);
    
    [self actionWithRequest:request actionCompleted:block];
}

//MARK Get http common errors
- (NSDictionary *)getHttpStatusError:(int)code {
    NSString *errorMessage = @"";
    switch (code) {
        case 400:
            errorMessage = NSLocalizedString(@"Bad Request.", @"");
            break;
        case 401:
            errorMessage = NSLocalizedString(@"Unauthorized.", @"");
            break;
        case 403:
            errorMessage = NSLocalizedString(@"Forbidden.", @"");
            break;
        case 404:
            errorMessage = NSLocalizedString(@"Not Found.", @"");
            break;
        case 408:
            errorMessage = NSLocalizedString(@"Request Timeout.", @"");
            break;
        case 500:
            errorMessage = NSLocalizedString(@"Internal Server Error.", @"");
            break;
        case 502:
            errorMessage = NSLocalizedString(@"Bad Gateway.", @"");
            break;
        case 503:
            errorMessage = NSLocalizedString(@"Service Unavailable.", @"");
            break;
        default:
            errorMessage = NSLocalizedString(@"Something went wrong.", @"");
            break;
    }
    
    NSDictionary *errorResponse = @{@"e": errorMessage};
    return errorResponse;
}

//MARK Get network errors
- (NSDictionary *)getNetworkError:(NSError *)error {
    NSString *errorMessage = @"";
    switch (error.code) {
        case NSURLErrorUnknown:
            errorMessage = NSLocalizedString(@"An unknown error occurred.", @"");
            break;
        case NSURLErrorCancelled:
            errorMessage = NSLocalizedString(@"The connection was cancelled.", @"");
            break;
        case NSURLErrorBadURL:
            errorMessage = NSLocalizedString(@"The connection failed due to a malformed URL.", @"");
            break;
        case NSURLErrorTimedOut:
            errorMessage = NSLocalizedString(@"The connection timed out.", @"");
            break;
        case NSURLErrorUnsupportedURL:
            errorMessage = NSLocalizedString(@"The connection failed due to an unsupported URL scheme.", @"");
            break;
        case NSURLErrorCannotFindHost:
            errorMessage = NSLocalizedString(@"The connection failed because the host could not be found.", @"");
            break;
        case NSURLErrorCannotConnectToHost:
            errorMessage = NSLocalizedString(@"The connection failed because a connection cannot be made to the host.", @"");
            break;
        case NSURLErrorNetworkConnectionLost:
            errorMessage = NSLocalizedString(@"The connection failed because the network connection was lost.", @"");
            break;
        case NSURLErrorDNSLookupFailed:
            errorMessage = NSLocalizedString(@"The connection failed because the DNS lookup failed.", @"");
            break;
        case NSURLErrorHTTPTooManyRedirects:
            errorMessage = NSLocalizedString(@"The HTTP connection failed due to too many redirects.", @"");
            break;
        case NSURLErrorResourceUnavailable:
            errorMessage = NSLocalizedString(@"The connection’s resource is unavailable.", @"");
            break;
        case NSURLErrorNotConnectedToInternet:
            errorMessage = NSLocalizedString(@"Device is not connected to the internet.", @"");
            break;
        case NSURLErrorRedirectToNonExistentLocation:
            errorMessage = NSLocalizedString(@"The connection was redirected to a nonexistent location.", @"");
            break;
        case NSURLErrorBadServerResponse:
            errorMessage = NSLocalizedString(@"The connection received an invalid server response.", @"");
            break;
        case NSURLErrorUserCancelledAuthentication:
            errorMessage = NSLocalizedString(@"The connection failed because the user cancelled required authentication.", @"");
            break;
        case NSURLErrorUserAuthenticationRequired:
            errorMessage = NSLocalizedString(@"The connection failed because authentication is required.", @"");
            break;
        case NSURLErrorZeroByteResource:
            errorMessage = NSLocalizedString(@"The resource retrieved by the connection is zero bytes.", @"");
            break;
        case NSURLErrorCannotDecodeContentData:
            errorMessage = NSLocalizedString(@"The connection cannot decode data encoded with a known content encoding.", @"");
            break;
            //case NSURLErrorCannotDecodeContentData:
            //    errorMessage = NSLocalizedString(@"The connection cannot decode data encoded with an unknown content encoding.", @"");
            //    break;
        case NSURLErrorCannotParseResponse:
            errorMessage = NSLocalizedString(@"The connection cannot parse the server’s response.", @"");
            break;
        case NSURLErrorInternationalRoamingOff:
            errorMessage = NSLocalizedString(@"The connection failed because international roaming is disabled on the device.", @"");
            break;
        case NSURLErrorCallIsActive:
            errorMessage = NSLocalizedString(@"The connection failed because a call is active.", @"");
            break;
        case NSURLErrorDataNotAllowed:
        errorMessage = NSLocalizedString(@"The connection failed because data use is currently not allowed on the device.", @"");
            break;
        case NSURLErrorRequestBodyStreamExhausted:
            errorMessage = NSLocalizedString(@"The connection failed because its request’s body stream was exhausted.", @"");
            break;
        default:
            errorMessage = NSLocalizedString(@"Something went wrong.", @"");
            break;
    }
    
    NSDictionary *errorResponse = @{@"e": errorMessage};
    return errorResponse;
}

- (NSDictionary *)nullFreeDictionaryWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *replaced = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    // Iterate through each key-object pair.
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        // If object is a dictionary, recursively remove NSNull from dictionary.
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSDictionary *innerDict = object;
            replaced[key] = [self nullFreeDictionaryWithDictionary:innerDict];
        }
        // If object is an array, enumerate through array.
        else if ([object isKindOfClass:[NSArray class]]) {
            NSMutableArray *nullFreeRecords = [NSMutableArray array];
            for (id record in object) {
                // If object is a dictionary, recursively remove NSNull from dictionary.
                if ([record isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *nullFreeRecord = [self nullFreeDictionaryWithDictionary:record];
                    [nullFreeRecords addObject:nullFreeRecord];
                }
                else {
                    if (object == [NSNull null]) {
                        [nullFreeRecords addObject:@""];
                    }
                    else {
                        [nullFreeRecords addObject:record];
                    }
                }
            }
            replaced[key] = nullFreeRecords;
        }
        else {
            // Replace [NSNull null] with nil string "" to avoid having to perform null comparisons while parsing.
            if (object == [NSNull null]) {
                replaced[key] = @"";
            }
        }
    }];
    
    return [NSDictionary dictionaryWithDictionary:replaced];
}

@end
