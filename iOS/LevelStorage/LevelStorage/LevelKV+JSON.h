//
//  LevelKV+JSON.h
//  WeRead
//
//  Created by jasenhuang on 2018/11/23.
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelKV.h"

NS_ASSUME_NONNULL_BEGIN

@interface LevelKV (JSON)

- (BOOL)setJSONObject:(id)JSON forKey:(NSString *)key;

- (id)getJSONObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
