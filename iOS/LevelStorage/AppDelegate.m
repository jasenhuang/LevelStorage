//
//  AppDelegate.m
//  LevelStorage
//
//  Created by jasenhuang on 2019/4/3.
//  Copyright © 2019 jasenhuang. All rights reserved.
//

#import "AppDelegate.h"
#import "LevelKV.h"

#define MAX_TEST_COUNT 10000
#define letters @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
@interface AppDelegate ()
@property(nonatomic) LevelKV* kv;
@end

@implementation AppDelegate


- (NSString *)randomStringWithLength:(NSInteger)len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (NSInteger i = 0; i < len ; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform([letters length])]];
    }
    
    return randomString;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.kv = [LevelKV keyValueWithNameSpace:@"default"];
    
    for (NSInteger i = 0; i < MAX_TEST_COUNT; ++i) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.kv setString:[self randomStringWithLength:10] forKey:[NSString stringWithFormat:@"%@", @(arc4random() % MAX_TEST_COUNT)]];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.kv getInt64ForKey:[NSString stringWithFormat:@"%@", @(arc4random() % MAX_TEST_COUNT)]];
        });
    }
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
