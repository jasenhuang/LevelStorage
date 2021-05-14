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

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

static inline int64_t convertFloat64ToInt64(Float64 v) {
	union { Float64 f; int64_t i; } u;
	u.f = v;
	return u.i;
}


static inline int32_t convertFloat32ToInt32(Float32 v) {
	union { Float32 f; int32_t i; } u;
	u.f = v;
	return u.i;
}


static inline Float64 convertInt64ToFloat64(int64_t v) {
	union { Float64 f; int64_t i; } u;
	u.i = v;
	return u.f;
}


static inline Float32 convertInt32ToFloat32(int32_t v) {
	union { Float32 f; int32_t i; } u;
	u.i = v;
	return u.f;
}


static inline uint64_t convertInt64ToUInt64(int64_t v) {
	union { int64_t i; uint64_t u; } u;
	u.i = v;
	return u.u;
}


static inline int64_t convertUInt64ToInt64(uint64_t v) {
	union { int64_t i; uint64_t u; } u;
	u.u = v;
	return u.i;
}

static inline uint32_t convertInt32ToUInt32(int32_t v) {
	union { int32_t i; uint32_t u; } u;
	u.i = v;
	return u.u;
}


static inline int64_t convertUInt32ToInt32(uint32_t v) {
	union { int32_t i; uint32_t u; } u;
	u.u = v;
	return u.i;
}


static inline int32_t logicalRightShift32(int32_t value, int32_t spaces) {
	return static_cast<int32_t>(convertUInt32ToInt32((convertInt32ToUInt32(value) >> spaces)));
}


static inline int64_t logicalRightShift64(int64_t value, int32_t spaces) {
	return convertUInt64ToInt64((convertInt64ToUInt64(value) >> spaces));
}

/**
 * Encode a ZigZag-encoded 32-bit value.  ZigZag encodes signed integers
 * into values that can be efficiently encoded with varint.  (Otherwise,
 * negative values must be sign-extended to 64 bits to be varint encoded,
 * thus always taking 10 bytes on the wire.)
 *
 * @param n A signed 32-bit integer.
 * @return An unsigned 32-bit integer, stored in a signed int.
 */
int32_t encodeZigZag32(int32_t n);

/**
 * Encode a ZigZag-encoded 64-bit value.  ZigZag encodes signed integers
 * into values that can be efficiently encoded with varint.  (Otherwise,
 * negative values must be sign-extended to 64 bits to be varint encoded,
 * thus always taking 10 bytes on the wire.)
 *
 * @param n A signed 64-bit integer.
 * @return An unsigned 64-bit integer, stored in a signed int.
 */
int64_t encodeZigZag64(int64_t n);

int32_t computeDoubleSize(int32_t fieldNumber, Float64 value);
int32_t computeFloatSize(int32_t fieldNumber, Float32 value);
int32_t computeUInt64Size(int32_t fieldNumber, int64_t value);
int32_t computeInt64Size(int32_t fieldNumber, int64_t value);
int32_t computeInt32Size(int32_t fieldNumber, int32_t value);
int32_t computeFixed64Size(int32_t fieldNumber, int64_t value);
int32_t computeFixed32Size(int32_t fieldNumber, int32_t value);
int32_t computeBoolSize(int32_t fieldNumber, BOOL value);
int32_t computeStringSize(int32_t fieldNumber, NSString* value);
int32_t computeDataSize(int32_t fieldNumber, NSData* value);
int32_t computeUInt32Size(int32_t fieldNumber, int32_t value);
int32_t computeSFixed32Size(int32_t fieldNumber, int32_t value);
int32_t computeSFixed64Size(int32_t fieldNumber, int64_t value);
int32_t computeSInt32Size(int32_t fieldNumber, int32_t value);
int32_t computeSInt64Size(int32_t fieldNumber, int64_t value);
int32_t computeTagSize(int32_t fieldNumber);

int32_t computeDoubleSizeNoTag(Float64 value);
int32_t computeFloatSizeNoTag(Float32 value);
int32_t computeUInt64SizeNoTag(int64_t value);
int32_t computeInt64SizeNoTag(int64_t value);
int32_t computeInt32SizeNoTag(int32_t value);
int32_t computeFixed64SizeNoTag(int64_t value);
int32_t computeFixed32SizeNoTag(int32_t value);
int32_t computeBoolSizeNoTag(BOOL value);
int32_t computeStringSizeNoTag(NSString* value);
int32_t computeDataSizeNoTag(NSData* value);
int32_t computeUInt32SizeNoTag(int32_t value);
int32_t computeEnumSizeNoTag(int32_t value);
int32_t computeSFixed32SizeNoTag(int32_t value);
int32_t computeSFixed64SizeNoTag(int64_t value);
int32_t computeSInt32SizeNoTag(int32_t value);
int32_t computeSInt64SizeNoTag(int64_t value);

/**
 * Compute the number of bytes that would be needed to encode a varint.
 * {@code value} is treated as unsigned, so it won't be sign-extended if
 * negative.
 */
int32_t computeRawVarint32Size(int32_t value);
int32_t computeRawVarint64Size(int64_t value);

int32_t computeRawStringSize(NSString* value);

/**
 * Compute the number of bytes that would be needed to encode an
 * unparsed MessageSet extension field to the stream.  For
 * historical reasons, the wire format differs from normal fields.
 */
int32_t computeRawMessageSetExtensionSize(int32_t fieldNumber, NSData* value);

/**
 * Compute the number of bytes that would be needed to encode an
 * enum field, including tag.  Caller is responsible for converting the
 * enum value to its numeric value.
 */
int32_t computeEnumSize(int32_t fieldNumber, int32_t value);

#ifdef __cplusplus
}
#endif

