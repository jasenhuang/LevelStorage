//
//  WRBook.h
//  LevelStorage
//
//  Created by jasenhuang on 2019/7/3.
//  Copyright © 2019 jasenhuang. All rights reserved.
//

#import "LevelObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface WRBook : LevelObject
@property(nonatomic) NSString* bookId;
@property(nonatomic) NSString* title;
@property(nonatomic) NSInteger price;
@property(nonatomic) NSArray* author;
@property(nonatomic) NSDictionary* relative;
@end

NS_ASSUME_NONNULL_END
