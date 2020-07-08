//
//  WireFormat.h
//  PBCoder
//
//  Created by Guo Ling on 4/26/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//


#import "PBUtility.h"

typedef enum {
  PBWireFormatVarint = 0,
  PBWireFormatFixed64 = 1,
  PBWireFormatLengthDelimited = 2,
  PBWireFormatStartGroup = 3,
  PBWireFormatEndGroup = 4,
  PBWireFormatFixed32 = 5,

  PBWireFormatTagTypeBits = 3,
  PBWireFormatTagTypeMask = 7 /* = (1 << PBWireFormatTagTypeBits) - 1*/,

  PBWireFormatMessageSetItem = 1,
  PBWireFormatMessageSetTypeId = 2,
  PBWireFormatMessageSetMessage = 3
} PBWireFormat;

#ifdef __cplusplus
extern "C" {
#endif

static inline int32_t PBWireFormatMakeTag(int32_t fieldNumber, int32_t wireType) {
	return (fieldNumber << PBWireFormatTagTypeBits) | wireType;
}


static inline int32_t PBWireFormatGetTagWireType(int32_t tag) {
	return tag & PBWireFormatTagTypeMask;
}


static inline int32_t PBWireFormatGetTagFieldNumber(int32_t tag) {
	return logicalRightShift32(tag, PBWireFormatTagTypeBits);
}
	
	
#ifdef __cplusplus
}
#endif
