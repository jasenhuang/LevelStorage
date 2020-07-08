//
//  LevelKV.m
//  WeRead
//
//  Created by jasenhuang on 2018/11/26.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LevelKV.h"
#import "LevelDB.h"
#import "LSCoder.h"
#import "LSUtility.h"
#import "LSCodedInputData.h"
#import "LSCodedOutputData.h"

NSString* const kLevelDBErrorDomain = @"com.tencent.weread.leveldb";

static LevelDBErrorFunction LDBErrorFunction;
void LevelDBSetErrorFunction(LevelDBErrorFunction errorFunction) {
    LDBErrorFunction = errorFunction;
}

@interface LevelKV()
@property(nonatomic, readwrite) LevelDB* db;
@property(nonatomic, readwrite) NSString* name;
@property(nonatomic, readwrite) NSCache* cache;
@end

@implementation LevelKV

+ (NSString*)pathWithNameSpace:(nonnull NSString *)ns {
    return [LevelDB databasePathWithNameSpace:ns];
}

+ (nonnull LevelKV*)defaultKV {
    return [LevelKV keyValueWithNameSpace:@"default"];
}
static NSMutableDictionary* _instances;
+ (nonnull LevelKV*)keyValueWithNameSpace:(nonnull NSString *)ns {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [NSMutableDictionary dictionary];
    });
    @synchronized (_instances) {
        LevelKV* _kv = _instances[ns];
        if (!_kv){
            _kv = [[LevelKV alloc] initWithNameSpace:ns];
        }
        if (_kv) {
            [_instances setObject:_kv forKey:ns];
        }else{
            NSError* error =
            [NSError errorWithDomain:kLevelDBErrorDomain
                                code:-1
                            userInfo:@{
                                @"namespace":ns,
                                @"msg":@"Database Corruption"
                            }];
            if (LDBErrorFunction){
                LDBErrorFunction(ns, _kv, error);
            }
        }
        return _kv;
    }
}

- (nonnull instancetype)init {
    return [self initWithNameSpace:@"default"];
}

- (nonnull instancetype)initWithNameSpace:(nonnull NSString *)ns {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [self initWithNameSpace:ns directory:paths[0]];
}

- (nonnull instancetype)initWithNameSpace:(nonnull NSString *)ns
                                directory:(NSString *)directory {
    if ((self = [super init])) {
        _name = ns;
        _db = [LevelDB databaseWithNameSpace:ns directory:directory];
        _db.encoder = ^NSData *(LevelDBKey * _Nonnull key, id  _Nonnull object) {
            if (![object isKindOfClass:[NSData class]]){
                NSLog(@"%@", @"encode object error");
                return nil;
            }
            return object;
        };
        _db.decoder = ^id(LevelDBKey * _Nonnull key, id  _Nonnull data) {
            return data;
        };
        _cache = [[NSCache alloc] init];
        _cache.totalCostLimit = 50 * 1024 * 1024;
        
        if (!_db){
            NSLog(@"%@", @"Problem creating LevelKV");
            return nil;
        }
    }
    return self;
}

- (void)close {
    @synchronized (_instances) {
        [_cache removeAllObjects];
        [_instances removeObjectForKey:_name];
        [_db close];_db = NULL;
    }
}

#pragma mark - Setters
- (BOOL)setObject:(id<LevelCoding>)obj forKey:(NSString*)key {
    if (!key.length || _db.closed) return false;
    [_cache setObject:obj forKey:key];
    NSData* raw = [obj serialize];
    return [self setData:raw forKey:key];
}

#define SETTER(Name, Type)\
- (BOOL) set##Name:(Type)value forKey:(NSString*)key {\
    if (!key.length || _db.closed) return false;\
    size_t size = compute##Name##SizeNoTag(value);\
    NSMutableData* data = [NSMutableData dataWithLength:size];\
    LSCodedOutputData output(data);\
    output.write##Name##NoTag(value);\
    /*double begin = CACurrentMediaTime();*/\
    BOOL ret = [_db setObject:data forKey:key];\
    /*KVLog_LevelDBStatis(LR_SetTime, (CACurrentMediaTime() - begin) * 1000.0);*/\
    return ret;\
}

SETTER(Bool, bool)

SETTER(Int32, int32_t)

SETTER(UInt32, uint32_t)

SETTER(Int64, int64_t)

SETTER(UInt64, uint64_t)

SETTER(Float, float)

SETTER(Double, double)

SETTER(String, NSString*)

SETTER(Data, NSData*)

- (BOOL)setRawData:(NSData *)rawData forKey:(NSString *)key {
    if (!key.length || _db.closed) return NO;
    BOOL ret = [_db setObject:rawData forKey:key];
    return ret;
}

#pragma mark - Getters
- (id)getObjectOfClass:(Class)cls forKey:(NSString*)key {
    id obj = [_cache objectForKey:key];
    if (!obj){
        NSData* raw = [self getDataForKey:key];
        if (raw){
            obj = [[cls alloc] init];
            [obj deserialize:raw];
            [_cache setObject:obj forKey:key];
        }
    }
    return obj;
}

#define GETTER(Name, Type)\
- (Type)get##Name##ForKey:(NSString*)key defaultValue:(Type)defaultValue {\
    if (!key.length || _db.closed) return defaultValue;\
    /*double begin = CACurrentMediaTime();*/\
    NSData* data = [_db objectForKey:key];\
    if (data.length > 0) {\
        @try {\
            LSCodedInputData input(data);\
            Type obj = input.read##Name();\
            /*KVLog_LevelDBStatis(LR_GetTime, (CACurrentMediaTime() - begin) * 1000.0);*/\
            return obj;\
        } @catch(NSException *exception) {\
            NSLog(@"%@", exception);\
        }\
    }\
    return defaultValue;\
}
#define GETTER_DEFAULT(Name, Type, Value)\
- (Type)get##Name##ForKey:(NSString*)key {\
    return [self get##Name##ForKey:key defaultValue:Value];\
}

GETTER(Bool, bool)
GETTER_DEFAULT(Bool, bool, false)

GETTER(Int32, int32_t)
GETTER_DEFAULT(Int32, int32_t, 0)

GETTER(UInt32, uint32_t)
GETTER_DEFAULT(UInt32, uint32_t, 0)

GETTER(Int64, int64_t)
GETTER_DEFAULT(Int64, int64_t, 0)

GETTER(UInt64, uint64_t)
GETTER_DEFAULT(UInt64, uint64_t, 0)

GETTER(Float, float)
GETTER_DEFAULT(Float, float, 0.0)

GETTER(Double, double)
GETTER_DEFAULT(Double, double, 0.0)

GETTER(String, NSString*)
GETTER_DEFAULT(String, NSString*, nil)

GETTER(Data, NSData*)
GETTER_DEFAULT(Data, NSData*, nil)

- (NSData *)getRawDataForKey:(NSString *)key {
    if (!key.length || _db.closed) return nil;
    NSData * rawData = [_db objectForKey:key];
    return rawData;
}

#pragma mark - Removers
- (void)removeObjectForKey:(NSString*)key {
    if (!key.length || _db.closed) return ;
    [_cache removeObjectForKey:key];
    [_db removeObjectForKey:key];
}


- (void)removeObjectsForKeys:(NSArray*)keys {
    if (!keys.count || _db.closed) return ;
    [keys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [_cache removeObjectForKey:key];
    }];
    [_db removeObjectsForKeys:keys];
}

- (void)enumerateKeysUsingBlock:(void (NS_NOESCAPE ^)(NSString *key, BOOL *stop))block {
    if (!block || _db.closed) return;
    [_db enumerateKeysUsingBlock:block];
}

#pragma mark - Checker

- (BOOL)existsValueForKey:(NSString *)key {
    return !![_db objectForKey:key];
}

#pragma mark - Export

- (NSDictionary *)exportToDictionaryWithKyes:(NSArray <NSString *>*)keys {
    NSMutableString *pattern = [NSMutableString string];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        key = [key stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
        NSString *prefix = pattern.length > 0 ? @"|" : @"";
        [pattern appendFormat:@"%@\\b%@\\b", prefix, key];
    }];
    
    NSMutableDictionary *exportedDict = [NSMutableDictionary dictionary];
    [self enumerateKeysUsingBlock:^(NSString * _Nonnull key, BOOL * _Nonnull stop) {
        BOOL isExportedKey = [key rangeOfString:pattern options:NSRegularExpressionSearch | NSCaseInsensitiveSearch].location != NSNotFound;
          if (isExportedKey) {
              NSData *data = [self getRawDataForKey:key];
              exportedDict[key] = data;
          }
    }];
    return exportedDict.copy;
}

- (void)importFromDictionary:(NSDictionary *)dict {
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull data, BOOL * _Nonnull stop) {
        [self setRawData:data forKey:key];
    }];
}

@end
