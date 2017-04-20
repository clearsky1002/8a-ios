//
//  SPAPIResponse.h
//  SPMessenger
//
//  Created by Kristoffer Yap on 1/4/16.
//  Copyright © 2016 HigherGround. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPAPIResponse : NSObject

@property (nonatomic) int responseCode;
@property (nonatomic, retain) id jsonObject;

@property (nonatomic) BOOL hasError;
@property (nonatomic, retain) NSString *errorMessage;


- (id)initFromJsonObject:(NSDictionary *)json;
- (id)initFromDataObject:(NSData *)json;

@end
