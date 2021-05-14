/**
 * Copyright (c) 2021 JasenHuang
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
