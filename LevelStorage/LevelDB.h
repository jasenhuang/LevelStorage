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
