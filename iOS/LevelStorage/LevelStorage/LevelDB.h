//
//  WRLevelDB.h
//  WeRead
//
//  Created by jasenhuang on 2018/11/8.
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct LevelDBOptions {
    BOOL createIfMissing ;                      // true
    BOOL createIntermediateDirectories;         // true
    BOOL errorIfExists   ;                      // false
    BOOL paranoidCheck   ;                      // false
    BOOL compression     ;                      // false
    int  filterPolicy    ;                      // 4 bit
    size_t cacheSize;                           // 50m
} LevelDBOptions;

typedef struct {
    const char * data;
    NSUInteger   length;
} LevelDBKey;

extern NSString * const kLevelDBChangeType;
extern NSString * const kLevelDBChangeTypePut;
extern NSString * const kLevelDBChangeTypeDelete;
extern NSString * const kLevelDBChangeValue;
extern NSString * const kLevelDBChangeKey;

typedef NSData * _Nonnull (^LevelDBEncoderBlock) (LevelDBKey * key, id object);
typedef id _Nonnull       (^LevelDBDecoderBlock) (LevelDBKey * key, id data);

#ifdef __cplusplus
extern "C" {
#endif
    
    NSString * NSStringFromLevelDBKey(LevelDBKey * key);
    NSData   * NSDataFromLevelDBKey  (LevelDBKey * key);
    
#ifdef __cplusplus
}
#endif

@interface LevelDB : NSObject
/**
 A boolean value indicating whether write operations should be synchronous (flush to disk before returning).
 */
@property (nonatomic) BOOL sync;

/**
 A boolean value indicating whether read operations should try to use the configured cache (defaults to true).
 */
@property (nonatomic) BOOL useCache;

/**
 A boolean readonly value indicating whether the database is closed or not.
 */
@property (readonly) BOOL closed;

/**
 The data encoding block.
 */
@property (nonatomic, copy) LevelDBEncoderBlock encoder;

/**
 The data decoding block.
 */
@property (nonatomic, copy) LevelDBDecoderBlock decoder;

/**
 database path with namespace
 */
+ (NSString*)databasePathWithNameSpace:(nonnull NSString *)ns;

/**
 static instance with namespace
 */
+ (LevelDB*)defaultDatabase;
+ (LevelDB*)databaseWithNameSpace:(nonnull NSString *)ns;
+ (LevelDB*)databaseWithNameSpace:(nonnull NSString *)ns
                        directory:(nonnull NSString *)directory;

/**
 init instance with namespace, directory and options
 */
- (instancetype)initWithNameSpace:(nonnull NSString *)ns;
- (instancetype)initWithNameSpace:(nonnull NSString *)ns
                        directory:(nonnull NSString *)directory;
- (instancetype)initWithNameSpace:(nonnull NSString *)ns
                        directory:(nonnull NSString *)directory
                          options:(LevelDBOptions)opts;


/**
 Close the database.
 
 @warning The instance cannot be used to perform any query after it has been closed.
 */
- (void) close;

#pragma mark - Setters

/**
 Set the value associated with a key in the database
 
 The instance's encoder block will be used to produce a NSData instance from the provided value.
 
 @param value The value to put in the database
 @param key The key at which the value can be found
 */
- (BOOL) setObject:(id)value forKey:(id)key;

/**
 Same as `[self setObject:forKey:]`
 */
- (BOOL) setObject:(id)value forKeyedSubscript:(id)key;


/**
 Take all key-value pairs in the provided dictionary and insert them in the database
 
 @param dictionary A dictionary from which key-value pairs will be inserted
 */
- (BOOL) addEntriesFromDictionary:(NSDictionary *)dictionary;

#pragma mark - Getters

/**
 Return the value associated with a key
 
 @param key The key to retrieve from the database
 */
- (id) objectForKey:(id)key;

/**
 Same as `[self objectForKey:]`
 */
- (id) objectForKeyedSubscript:(id)key;

/**
 Return a boolean value indicating whether or not the key exists in the database
 
 @param key The key to check for existence
 */
- (BOOL) objectExistsForKey:(id)key;

#pragma mark - Removers

/**
 Remove a key (and its associated value) from the database
 
 @param key The key to remove from the database
 */
- (void) removeObjectForKey:(id)key;

/**
 Remove a set of keys (and their associated values) from the database
 
 @param keyArray An array of keys to remove from the database
 */
- (void) removeObjectsForKeys:(NSArray *)keyArray;

- (void) enumerateKeysUsingBlock:(void (NS_NOESCAPE ^)(NSString *key, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
