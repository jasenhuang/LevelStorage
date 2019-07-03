//
//  LevelMacro.h
//  LevelStorage
//
//  Created by jasenhuang on 2019/7/3.
//  Copyright © 2019 jasenhuang. All rights reserved.
//

#ifndef LevelMacro_h
#define LevelMacro_h

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
