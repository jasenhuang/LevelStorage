### LevelStorage
LevelDB Wrapper with simple api

### Feature
1. PBCoding Serialization
2. Common Type Key-Value API
3. DBError Function LevelDBSetErrorFunction

### Usage
1. CocoaPods Embbed
`pod 'LevelStorage'

2. Project Config
```
// config error function
LevelDBSetErrorFunction(^(NSString* name, NSError* error){
    if (error.code == LevelDBOpenError) {
        NSString* kvPath = [LevelKV pathWithNameSpace:name];
        [[NSFileManager defaultManager] removeItemAtPath:kvPath error:nil];
    }else if (error.code == LevelDBSetError){

    }else if (error.code == LevelDBGetError){
        
    }else if (error.code == LevelDBDeleteError){
        
    }
});

// init 
LevelKV* kv = [LevelKV keyValueWithNameSpace:@"com.tencent.leveldb.weread"];

// api
[kv setInt32:123456 forKey:@"count"];
NSInteger count = [kv getInt32ForKey:@"count"];
```

### API

```
/**
 non-threadsafe set kv api
 */

- (BOOL)setObject:(id<LevelCoding>)obj forKey:(NSString*)key;

- (BOOL)setBool:(bool)value forKey:(NSString*)key;

- (BOOL)setInt32:(int32_t)value forKey:(NSString*)key;

- (BOOL)setString:(NSString*)value forKey:(NSString*)key;

- (BOOL)setData:(NSData*)value forKey:(NSString*)key;

- (BOOL)setJSONObject:(id)JSON forKey:(NSString *)key; //JSON

/**
 non-threadsafe get kv api
 */

- (id)getObjectOfClass:(Class)cls forKey:(NSString*)key;

- (bool)getBoolForKey:(NSString*)key;
- (bool)getBoolForKey:(NSString*)key defaultValue:(bool)defaultValue;

- (int32_t)getInt32ForKey:(NSString*)key;
- (int32_t)getInt32ForKey:(NSString*)key defaultValue:(int32_t)defaultValue;

- (NSString*)getStringForKey:(NSString*)key;
- (NSString*)getStringForKey:(NSString*)key defaultValue:(NSString*_Nullable)defaultValue;

- (NSData*)getDataForKey:(NSString*)key;
- (NSData*)getDataForKey:(NSString*)key defaultValue:(NSString*_Nullable)defaultValue;

- (id)getJSONObjectForKey:(NSString *)key; //JSON

#pragma mark - Removers

- (void)removeObjectForKey:(NSString*)key;
- (void)removeObjectsForKeys:(NSArray*)keys;

#pragma mark - Checker

- (BOOL)existsValueForKey:(NSString *)key;
```