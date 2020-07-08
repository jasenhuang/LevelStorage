//
//  WRLevelDB.m
//  WeRead
//
//  Created by jasenhuang on 2018/11/8.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LevelDB.h"
#import <leveldb/db.h>
#import <leveldb/options.h>
#import <leveldb/cache.h>
#import <leveldb/filter_policy.h>
#import <leveldb/write_batch.h>
#import "LSCoder.h"
#import "LSUtility.h"
#import "LSCodedInputData.h"
#import "LSCodedOutputData.h"

NSString * const kLevelDBChangeType         = @"changeType";
NSString * const kLevelDBChangeTypePut      = @"put";
NSString * const kLevelDBChangeTypeDelete   = @"del";
NSString * const kLevelDBChangeValue        = @"value";
NSString * const kLevelDBChangeKey          = @"key";
NSString * const kLevelDBErrorDomain        = @"com.tencent.levelstorage";

static LevelDBErrorFunction LDBErrorFunction;
void LevelDBSetErrorFunction(LevelDBErrorFunction errorFunction) {
    LDBErrorFunction = errorFunction;
}

LevelDBOptions MakeLevelDBOptions() {
    return (LevelDBOptions) {true, true, false, false, true, 4, 50 * 1048576};
}

#define AssertKeyType(_key_)\
NSParameterAssert([_key_ isKindOfClass:[NSString class]] || [_key_ isKindOfClass:[NSData class]])

#define SliceFromString(_string_)           leveldb::Slice((char *)[_string_ UTF8String], [_string_ lengthOfBytesUsingEncoding:NSUTF8StringEncoding])
#define StringFromSlice(_slice_)            [[NSString alloc] initWithBytes:_slice_.data() length:_slice_.size() encoding:NSUTF8StringEncoding]

#define SliceFromData(_data_)               leveldb::Slice((char *)[_data_ bytes], [_data_ length])
#define DataFromSlice(_slice_)              [NSData dataWithBytes:_slice_.data() length:_slice_.size()]

#define KeyFromStringOrData(_key_)          ([_key_ isKindOfClass:[NSString class]]) ? SliceFromString(_key_) \
: SliceFromData(_key_)

#define GenericKeyFromSlice(_slice_)        (LevelDBKey) { .data = _slice_.data(), .length = _slice_.size() }

#define DecodeFromSlice(_slice_, _key_, _d) _d(_key_, DataFromSlice(_slice_))
#define EncodeToSlice(_object_, _key_, _e)  SliceFromData(_e(_key_, _object_))

#define AssertDBExists(_db_) \
NSAssert(_db_ != NULL, @"Database reference is not existent (it has probably been closed)");

@interface LevelDB() {
    dispatch_queue_t _queue;
    NSString* _name;
    NSString* _path;
    leveldb::DB* _db;
    leveldb::ReadOptions _readOptions;
    leveldb::WriteOptions _writeOptions;
    const leveldb::Cache * _cache;
    const leveldb::FilterPolicy * _filterPolicy;
}
@end

@implementation LevelDB

+ (NSString*)databasePathWithNameSpace:(nonnull NSString *)ns {
    NSString *fullNamespace = [@"com.tencent.leveldb." stringByAppendingString:ns];
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

+ (LevelDB*)defaultDatabase {
    return [LevelDB databaseWithNameSpace:@"default"];
}

+ (LevelDB*)databaseWithNameSpace:(nonnull NSString *)ns {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [LevelDB databaseWithNameSpace:ns directory:paths[0]];
}

static NSMutableDictionary* _instances;
+ (LevelDB*)databaseWithNameSpace:(nonnull NSString *)ns directory:(nonnull  NSString *)directory {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [NSMutableDictionary dictionary];
    });
    @synchronized (_instances) {
        LevelDB* db = _instances[ns];
        if (!db){
            db = [[LevelDB alloc] initWithNameSpace:ns directory:directory];
        }
        if (db) {
            [_instances setObject:db forKey:ns];
        }
        return db;
    }
}

- (instancetype)init {
    return [self initWithNameSpace:@"default"];
}

- (instancetype)initWithNameSpace:(nonnull NSString *)ns {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [self initWithNameSpace:ns directory:paths[0]];
}

- (instancetype)initWithNameSpace:(nonnull NSString *)ns
                        directory:(nonnull NSString *)directory {
    return [self initWithNameSpace:ns
                         directory:directory
                           options:MakeLevelDBOptions()];
}

- (instancetype)initWithNameSpace:(nonnull NSString *)ns
                        directory:(nonnull NSString *)directory
                          options:(LevelDBOptions)opts {

    if ((self = [super init])) {
        NSString *fullNamespace = [@"com.tencent.leveldb." stringByAppendingString:ns];
        _queue = dispatch_queue_create("com.tencent.leveldb", NULL);
        _name = ns;
        if (directory.length) {
            _path = [directory stringByAppendingPathComponent:fullNamespace];
        } else {
            NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            _path = [paths[0] stringByAppendingPathComponent:fullNamespace];
        }
        leveldb::Options options;
        
        options.create_if_missing = opts.createIfMissing;
        options.paranoid_checks = opts.paranoidCheck;
        options.error_if_exists = opts.errorIfExists;
        
        if (!opts.compression)
            options.compression = leveldb::kNoCompression;
        
        if (opts.cacheSize > 0) {
            options.block_cache = leveldb::NewLRUCache(opts.cacheSize);
            _cache = options.block_cache;
        } else {
            _readOptions.fill_cache = false;
        }
        if (opts.filterPolicy > 0) {
            _filterPolicy = leveldb::NewBloomFilterPolicy(opts.filterPolicy);;
            options.filter_policy = _filterPolicy;
        }
        if (opts.createIntermediateDirectories && directory.length) {
            NSError *error;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:directory
                         withIntermediateDirectories:true
                                          attributes:nil
                                     error:&error]){
                NSLog(@"Problem creating parent directory: %@", error);
                return nil;
            }
        }
        
        leveldb::Status status = leveldb::DB::Open(options, [_path UTF8String], &_db);
        
        if(!status.ok()) {
            NSString* errmsg =
            [NSString stringWithFormat:@"Problem creating LevelDB database: %s",
             status.ToString().c_str()];
            
            [self onLDBErrorFunction:LevelDBOpenError msg:errmsg];
            return nil;
        }
    }
    return self;
}

#pragma mark - error handling
- (void)onLDBErrorFunction:(LevelDBErrorCode)code msg:(NSString*)msg {
    NSLog(@"%@", msg);
    NSError* error =
    [NSError errorWithDomain:kLevelDBErrorDomain
                        code:code
                    userInfo:@{
                        @"namespace":_name,
                        @"msg":msg
                    }];
    if (LDBErrorFunction){
        LDBErrorFunction(_name, error);
    }
}

#pragma mark - operation
- (void) close {
    @synchronized(_instances) {
        [_instances removeObjectForKey:_name];
        if (_db) delete _db; _db = NULL;
        if (_cache) delete _cache; _cache = NULL;
        if (_filterPolicy) delete _filterPolicy; _filterPolicy = NULL;
    }
}

- (BOOL) closed {
    return _db == NULL;
}

#pragma mark - configuration
- (void) setSync:(BOOL)sync {
    _writeOptions.sync = sync;
}

- (BOOL) sync {
    return _writeOptions.sync;
}

- (void) setUseCache:(BOOL)useCache {
    _readOptions.fill_cache = useCache;
}

- (BOOL) useCache {
    return _readOptions.fill_cache;
}

#pragma mark - serilization
- (LevelDBEncoderBlock)encoder {
    if (!_encoder){
        _encoder = ^ NSData *(LevelDBKey *key, id object) {
            return [NSKeyedArchiver archivedDataWithRootObject:object];
        };
    }
    return _encoder;
}

- (LevelDBDecoderBlock)decoder {
    if (!_decoder) {
        _decoder = ^ id (LevelDBKey *key, NSData *data) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:data];
        };
    }
    return _decoder;
}

#pragma mark - Setters
- (BOOL) setObject:(id)value forKey:(id)key {
    AssertDBExists(_db);
    AssertKeyType(key);
    NSParameterAssert(value != nil);
    
    leveldb::Slice k = KeyFromStringOrData(key);
    LevelDBKey lkey = GenericKeyFromSlice(k);
    
    leveldb::Slice v = EncodeToSlice(value, &lkey, self.encoder);
    leveldb::Status status = _db->Put(_writeOptions, k, v);
    
    if(!status.ok()) {
        NSString* errmsg =
        [NSString stringWithFormat:@"Problem storing key/value pair in database: %s",
         status.ToString().c_str()];
        
        [self onLDBErrorFunction:LevelDBSetError msg:errmsg];
        return false;
    }
    return true;
}

- (BOOL) setObject:(id)value forKeyedSubscript:(id)key {
    return [self setObject:value forKey:key];
}

- (BOOL) addEntriesFromDictionary:(NSDictionary *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setObject:obj forKey:key];
    }];
    return true;
}

#pragma mark - Getters
- (id) objectForKey:(id)key {
    AssertDBExists(_db);
    AssertKeyType(key);
    std::string v_string;
    leveldb::Slice k = KeyFromStringOrData(key);
    leveldb::Status status = _db->Get(_readOptions, k, &v_string);
    
    if(!status.ok()) {
        if(!status.IsNotFound()){
            NSString* errmsg =
            [NSString stringWithFormat:@"Problem retrieving value for key '%@' from database: %s",
             key, status.ToString().c_str()];
            
            [self onLDBErrorFunction:LevelDBGetError msg:errmsg];
        }
        return nil;
    }
    
    LevelDBKey lkey = GenericKeyFromSlice(k);
    return DecodeFromSlice(v_string, &lkey, self.decoder);
}

- (id) objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (BOOL) objectExistsForKey:(id)key {
    AssertDBExists(_db);
    AssertKeyType(key);
    std::string v_string;
    leveldb::Slice k = KeyFromStringOrData(key);
    leveldb::Status status = _db->Get(_readOptions, k, &v_string);
    
    if (!status.ok()) {
        if (status.IsNotFound())
            return false;
        else {
            NSString* errmsg =
            [NSString stringWithFormat:@"Problem retrieving value for key '%@' from database: %s",
             key, status.ToString().c_str()];
            
            [self onLDBErrorFunction:LevelDBGetError msg:errmsg];
            return false;
        }
    } else
        return true;
}

#pragma mark - Removers
- (void) removeObjectForKey:(id)key {
    AssertDBExists(_db);
    AssertKeyType(key);
    
    leveldb::Slice k = KeyFromStringOrData(key);
    leveldb::Status status = _db->Delete(_writeOptions, k);
    
    if(!status.ok()) {
        NSString* errmsg =
        [NSString stringWithFormat:@"Problem deleting key/value pair in database: %s",
         status.ToString().c_str()];
        
        [self onLDBErrorFunction:LevelDBDeleteError msg:errmsg];
    }
}

- (void) removeObjectsForKeys:(NSArray *)keyArray {
    [keyArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self removeObjectForKey:obj];
    }];
}

- (void)enumerateKeysUsingBlock:(void (NS_NOESCAPE ^)(NSString *key, BOOL *stop))block {
    if (!block) return;
    leveldb::Iterator* it = _db->NewIterator(_readOptions);
    BOOL stop = NO;
    for (it->SeekToFirst(); it->Valid() && !stop; it->Next()) {
        NSString *key = [NSString stringWithUTF8String:it->key().ToString().c_str()];
        block(key, &stop);
    }
    assert(it->status().ok());
    delete it;
}

@end
