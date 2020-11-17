//
//  WRLevelDB.h
//  WeRead
//
//  Created by jasenhuang on 2018/11/8.
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelMacro.h"

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

typedef enum {
    LevelDBSuccess          = 0,
    LevelDBOpenError        = -1,
    LevelDBSetError         = -2,
    LevelDBGetError         = -3,
    LevelDBDeleteError      = -4,
} LevelDBErrorCode;

typedef struct {
    const char * data;
    NSUInteger   length;
} LevelDBKey;

typedef void (^LevelDBErrorFunction)(NSString* name, NSError* _Nullable error);

LDB_EXTERN NSString * const kLevelDBErrorDomain;
LDB_EXTERN void LevelDBSetErrorFunction(LevelDBErrorFunction errorFunction);

LDB_EXTERN_C_BEGIN

typedef NSData * _Nonnull (^LevelDBEncoderBlock) (LevelDBKey * key, id object);
typedef id _Nonnull       (^LevelDBDecoderBlock) (LevelDBKey * key, id data);
    
LDB_EXTERN_C_END
@interface LevelDB : NSObject

@property (readonly) BOOL closed; // whether levelDB is closed

@property (nonatomic, copy) LevelDBEncoderBlock encoder;

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


#pragma mark - Operations
- (void) close;

#pragma mark - Setters

- (BOOL) setObject:(id)value forKey:(id)key;
- (BOOL) setObject:(id)value forKeyedSubscript:(id)key;

- (BOOL) addEntriesFromDictionary:(NSDictionary *)dictionary;

#pragma mark - get operation function

- (id) objectForKey:(id)key;
- (id) objectForKeyedSubscript:(id)key;

- (BOOL) objectExistsForKey:(id)key;

#pragma mark - remove operation function

- (void) removeObjectForKey:(id)key;
- (void) removeObjectsForKeys:(NSArray *)keyArray;

#pragma mark - enumerate operation function

- (void) enumerateKeysUsingBlock:(void (NS_NOESCAPE ^)(NSString *key, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
