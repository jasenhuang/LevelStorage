/**
 * Copyright (c) 2021 JasenHuang
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "LSUtility.h"

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
