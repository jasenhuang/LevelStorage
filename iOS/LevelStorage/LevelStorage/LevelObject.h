//
//  WRLevelObject.h
//  WeRead
//
//  Created by jasenhuang on 2018/11/8.
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelMacro.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString* const kOperatorBy;
extern NSString* const kOperatorLT;
extern NSString* const kOperatorLTE;
extern NSString* const kOperatorGT;
extern NSString* const kOperatorGTE;
extern NSString* const kOperatorNE;
extern NSString* const kOperatorAND;
extern NSString* const kOperatorOR;
extern NSString* const kOperatorLIMIT;

@protocol LevelProtocol <NSObject>
@required
- (NSString*)primay;

@end

@interface LevelObject : NSObject<LevelProtocol>

@end

NS_ASSUME_NONNULL_END
