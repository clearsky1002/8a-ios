//
//  NSString+URL.m
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import "NSString+URL.h"

@implementation NSString (URL)

- (NSString *)stringByAddingPercentEncodingForURLQueryValue {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
