//
//  SPAPIResponse.m
//  SPMessenger
//
//  Created by Kristoffer Yap on 1/4/16.
//  Copyright © 2016 HigherGround. All rights reserved.
//

#import "SPAPIResponse.h"

@implementation SPAPIResponse

//initializer
- (id)init {
    self = [super init];
    
    return self;
}


- (id)initFromJsonObject:(NSDictionary *)json {
    self = [super init];
    
    self.jsonObject = json;
    
    return self;
}

- (id)initFromDataObject:(NSData *)json {
    self = [super init];
    
    self.jsonObject = json;
    
    return self;
}

@end
