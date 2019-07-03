//
//  WRLevelObject.m
//  WeRead
//
//  Created by jasenhuang on 2018/11/8.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LevelObject.h"

NSString* const kOperatorBy = @"by";
NSString* const kOperatorLT = @"lt";
NSString* const kOperatorLTE = @"lte";
NSString* const kOperatorGT = @"gt";
NSString* const kOperatorGTE = @"gte";
NSString* const kOperatorNE = @"ne";
NSString* const kOperatorAND = @"and";
NSString* const kOperatorOR = @"or";
NSString* const kOperatorLIMIT = @"limit";

@interface LevelObject()
@property(nonatomic) NSDictionary* json;
@end

@implementation LevelObject
- (NSString*)primay {
    LSAssert(NO, @"primay not implement");
    return nil;
}

@end
