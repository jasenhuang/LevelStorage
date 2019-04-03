//
//  LevelKV.m
//  WeRead
//
//  Created by jasenhuang on 2018/11/26.
//  Copyright © 2018 tencent. All rights reserved.
//

#import "LevelKV.h"
#import "LevelDB.h"
#import "PBCoder.h"
#import "PBUtility.h"
#import "CodedInputData.h"
#import "CodedOutputData.h"

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
                NSLog(@"encode object error");
                return nil;
            }
            return object;
        };
        _db.decoder = ^id(LevelDBKey * _Nonnull key, id  _Nonnull data) {
            return data;
        };
        _cache = [[NSCache alloc] init];
        _cache.totalCostLimit = 50 * 1024 * 1024;
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
    NSData* raw = [obj serialize];
    [_cache setObject:obj forKey:key cost:raw.length];
    return [self setData:raw forKey:key];
}

#define SETTER(Name, Type)\
- (BOOL) set##Name:(Type)value forKey:(NSString*)key {\
    if (!key.length || _db.closed) return false;\
    size_t size = compute##Name##SizeNoTag(value);\
    NSMutableData* data = [NSMutableData dataWithLength:size];\
    CodedOutputData output(data);\
    output.write##Name##NoTag(value);\
    /*double begin = CACurrentMediaTime();*/\
    BOOL ret = [_db setObject:data forKey:key];\
    /*NSLog(@"%@", @((CACurrentMediaTime() - begin) * 1000.0));*/\
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

#pragma mark - Getters
- (id)getObjectOfClass:(Class)cls forKey:(NSString*)key {
    id obj = [_cache objectForKey:key];
    if (!obj){
        NSData* raw = [self getDataForKey:key];
        if (raw){
            obj = [[cls alloc] init];
            [obj deserialize:raw];
            [_cache setObject:obj forKey:key cost:raw.length];
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
            CodedInputData input(data);\
            Type obj = input.read##Name();\
            /*NSLog(@"%@", @((CACurrentMediaTime() - begin) * 1000.0);*/\
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

@end
