//
//  LevelKV+JSON.m
//  WeRead
//
//  Created by jasenhuang on 2018/11/23.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LevelKV+JSON.h"

@implementation LevelKV (JSON)

- (BOOL)setJSONObject:(id)JSON forKey:(NSString *)key
{
    if (!JSON) return NO;
    
    NSError *error;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSON options:0 error:&error];
    
    if (error) return NO;

    [self.cache setObject:JSON forKey:key cost:JSONData.length];
    return [self setData:JSONData forKey:key];
}

- (id)getJSONObjectForKey:(NSString *)key
{
    id JSON = [self.cache objectForKey:key];
    if (!JSON){
        NSData *JSONData = [self getDataForKey:key];
        if (JSONData) {
            JSON = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
            [self.cache setObject:JSON forKey:key cost:JSONData.length];
        }
    }
    return JSON;
}
@end
