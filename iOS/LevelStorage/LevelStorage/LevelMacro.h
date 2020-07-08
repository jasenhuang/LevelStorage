//
//  LevelMacro.h
//  LevelStorage
//
//  Created by jasenhuang on 2019/7/3.
//  Copyright © 2019 jasenhuang. All rights reserved.
//

#ifndef LevelMacro_h
#define LevelMacro_h

#if defined(__cplusplus)
#define LDB_EXTERN extern "C" __attribute__((visibility("default")))
#define LDB_EXTERN_C_BEGIN extern "C" {
#define LDB_EXTERN_C_END }
#else
#define LDB_EXTERN extern __attribute__((visibility("default")))
#define LDB_EXTERN_C_BEGIN
#define LDB_EXTERN_C_END
#endif

#define LSImplementation(TABLE) \
static NSArray* kLS ## TABLE ## Indices; \


#define LSPrimarySynthesize(TYPE, NAME) \
- (TYPE)primay {                        \
return self.NAME;                   \
}

#define LSIndexSynthesize(TYPE, NAME) \

#define LSPropertySynthesize(TYPE, NAME) \


#define LSAssert(condition, ...)                                            \
if (!(condition)) {                                                         \
    NSLog(@"%s|%s(%d)|%@", __FILE__, __FUNCTION__, __LINE__, __VA_ARGS__);  \
    NSAssert(condition, @"%@", __VA_ARGS__);                                \
}

#endif /* LevelMacro_h */
