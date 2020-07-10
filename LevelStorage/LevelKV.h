//
//  LevelKV.h
//  WeRead
//
//  Created by jasenhuang on 2018/11/26.
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelMacro.h"

NS_ASSUME_NONNULL_BEGIN

@class LevelDB;
@class LevelKV;

@protocol LevelCoding

@required
- (NSData *)serialize;
- (void)deserialize:(NSData *)data;

@end

@interface LevelKV : NSObject

@property(nonatomic, readonly) LevelDB *db;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSCache *cache;

+ (NSString*)pathWithNameSpace:(nonnull NSString *)ns;

+ (nonnull LevelKV*)defaultKV;
+ (nonnull LevelKV*)keyValueWithNameSpace:(nonnull NSString *)ns;


- (nonnull instancetype)initWithNameSpace:(nonnull NSString *)ns;
- (nonnull instancetype)initWithNameSpace:(nonnull NSString *)ns
                                directory:(nonnull NSString *)directory;

- (void)close;

#pragma mark - Setters

/**
 non-threadsafe set kv api
 */

- (BOOL)setObject:(id<LevelCoding>)obj forKey:(NSString*)key;

- (BOOL)setBool:(bool)value forKey:(NSString*)key;

- (BOOL)setInt32:(int32_t)value forKey:(NSString*)key;

- (BOOL)setUInt32:(uint32_t)value forKey:(NSString*)key;

- (BOOL)setInt64:(int64_t)value forKey:(NSString*)key;

- (BOOL)setUInt64:(uint64_t)value forKey:(NSString*)key;

- (BOOL)setFloat:(float)value forKey:(NSString*)key;

- (BOOL)setDouble:(double)value forKey:(NSString*)key;

- (BOOL)setString:(NSString*)value forKey:(NSString*)key;

- (BOOL)setData:(NSData*)value forKey:(NSString*)key;

#pragma mark - Getters

/**
 non-threadsafe get kv api
 */

- (id)getObjectOfClass:(Class)cls forKey:(NSString*)key;

- (bool)getBoolForKey:(NSString*)key;
- (bool)getBoolForKey:(NSString*)key defaultValue:(bool)defaultValue;

- (int32_t)getInt32ForKey:(NSString*)key;
- (int32_t)getInt32ForKey:(NSString*)key defaultValue:(int32_t)defaultValue;

- (uint32_t)getUInt32ForKey:(NSString*)key;
- (uint32_t)getUInt32ForKey:(NSString*)key defaultValue:(uint32_t)defaultValue;

- (int64_t)getInt64ForKey:(NSString*)key;
- (int64_t)getInt64ForKey:(NSString*)key defaultValue:(int64_t)defaultValue;

- (uint64_t)getUInt64ForKey:(NSString*)key;
- (uint64_t)getUInt64ForKey:(NSString*)key defaultValue:(uint64_t)defaultValue;

- (float)getFloatForKey:(NSString*)key;
- (float)getFloatForKey:(NSString*)key defaultValue:(float)defaultValue;

- (double)getDoubleForKey:(NSString*)key;
- (double)getDoubleForKey:(NSString*)key defaultValue:(double)defaultValue;

- (NSString*)getStringForKey:(NSString*)key;
- (NSString*)getStringForKey:(NSString*)key defaultValue:(NSString*_Nullable)defaultValue;

- (NSData*)getDataForKey:(NSString*)key;
- (NSData*)getDataForKey:(NSString*)key defaultValue:(NSString*_Nullable)defaultValue;

#pragma mark - Removers

- (void)removeObjectForKey:(NSString*)key;
- (void)removeObjectsForKeys:(NSArray*)keys;

#pragma mark - Checker

- (BOOL)existsValueForKey:(NSString *)key;

#pragma mark - Enumerator

- (void)enumerateKeysUsingBlock:(void (NS_NOESCAPE ^)(NSString *key, BOOL *stop))block;

#pragma mark - Export

// key 支持通配符 *
- (NSDictionary *)exportToDictionaryWithKyes:(NSArray <NSString *>*)keys;

- (void)importFromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
