//
//  LSCoder+PropertyTable.h
//  WeChatForMac
//
//  Created by Ling Guo on 1/3/14.
//  Copyright (c) 2014 Tencet. All rights reserved.
//

#import "LSCoder.h"

// encode/decode using alternative property table

@interface LSCoder (PropertyTable)

+(NSData*) encodeObject:(id)obj
      withPropertyTable:(NSArray*)arrProperty;

+(bool) encodeObject:(id)obj
   withPropertyTable:(NSArray*)arrProperty
              toFile:(NSString*)nsPath;

+(bool) decodeObject:(id)obj
            fromData:(NSData *)oData
        withProperty:(NSArray*)arrPropertyTypeWrap
      andTagIndexMap:(const std::map<size_t, size_t>*)mapTagToIndex;

@end
