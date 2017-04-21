//
//  NSString+URL.h
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URL)

- (NSString *)stringByAddingPercentEncodingForURLQueryValue;
- (NSString*) getNormalizedPhoneNumber;

@end
