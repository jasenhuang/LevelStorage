//
//  LevelStorage.m
//  WeRead
//
//  Created by jasenhuang on 2018/11/28.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LevelStorage.h"
#import "LevelDB.h"
#import "LevelObject.h"

@interface LevelStorage()
{
    
}
@end

@implementation LevelStorage
+ (LevelStorage*)shareStorage {
    static dispatch_once_t onceToken;
    static LevelStorage* _instance;
    dispatch_once(&onceToken, ^{
        _instance = [LevelStorage new];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


@end
