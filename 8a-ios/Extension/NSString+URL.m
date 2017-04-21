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


-(NSString*) getNormalizedPhoneNumber
{
    NSString* prefix = @"";
    NSString* phoneString;
    phoneString = [[self componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    if(phoneString.length == 10)
    {
        prefix = @"+1";
    }
    else if(phoneString.length == 11)
    {
        prefix = @"+";
    }
    return [NSString stringWithFormat:@"%@%@", prefix, phoneString];
}

@end
