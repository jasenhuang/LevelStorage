//
//  LSUtility.mm
//  LSCoder
//
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "LSUtility.h"
#import "LSWireFormat.h"

#if ! __has_feature(objc_arc)
#error LSCoding must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static const int32_t LITTLE_ENDIAN_32_SIZE = 4;
static const int32_t LITTLE_ENDIAN_64_SIZE = 8;


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code double} field, including tag.
 */
int32_t computeDoubleSizeNoTag(Float64 value) {
	return LITTLE_ENDIAN_64_SIZE;
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code float} field, including tag.
 */
int32_t computeFloatSizeNoTag(Float32 value) {
	return LITTLE_ENDIAN_32_SIZE;
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code uint64} field, including tag.
 */
int32_t computeUInt64SizeNoTag(int64_t value) {
	return computeRawVarint64Size(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code int64} field, including tag.
 */
int32_t computeInt64SizeNoTag(int64_t value) {
	return computeRawVarint64Size(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code int32} field, including tag.
 */
int32_t computeInt32SizeNoTag(int32_t value) {
	if (value >= 0) {
		return computeRawVarint32Size(value);
	} else {
		// Must sign-extend.
		return 10;
	}
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code fixed64} field, including tag.
 */
int32_t computeFixed64SizeNoTag(int64_t value) {
	return LITTLE_ENDIAN_64_SIZE;
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code fixed32} field, including tag.
 */
int32_t computeFixed32SizeNoTag(int32_t value) {
	return LITTLE_ENDIAN_32_SIZE;
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code bool} field, including tag.
 */
int32_t computeBoolSizeNoTag(BOOL value) {
	return 1;
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code string} field, including tag.
 */
int32_t computeStringSizeNoTag(NSString* value) {
	//  NSData* data = [value dataUsingEncoding:NSUTF8StringEncoding);
	//  return computeRawVarint32Size(data.length) + data.length;
	int32_t numberOfBytes = static_cast<int32_t>([value lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	return computeRawVarint32Size(numberOfBytes) + numberOfBytes;
}

int32_t computeRawStringSize(NSString* value) {
	//  NSData* data = [value dataUsingEncoding:NSUTF8StringEncoding);
	//  return computeRawVarint32Size(data.length) + data.length;
	NSUInteger numberOfBytes = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	return static_cast<int32_t>(numberOfBytes);
}

/**
 * Compute the number of bytes that would be needed to encode a
 * {@code bytes} field, including tag.
 */
int32_t computeDataSizeNoTag(NSData* value) {
	int32_t numberOfBytes = static_cast<int32_t>(value.length);
	return computeRawVarint32Size(numberOfBytes) + numberOfBytes;
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code uint32} field, including tag.
 */
int32_t computeUInt32SizeNoTag(int32_t value) {
	return computeRawVarint32Size(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * enum field, including tag.  Caller is responsible for converting the
 * enum value to its numeric value.
 */
int32_t computeEnumSizeNoTag(int32_t value) {
	return computeRawVarint32Size(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sfixed32} field, including tag.
 */
int32_t computeSFixed32SizeNoTag(int32_t value) {
	return LITTLE_ENDIAN_32_SIZE;
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sfixed64} field, including tag.
 */
int32_t computeSFixed64SizeNoTag(int64_t value) {
	return LITTLE_ENDIAN_64_SIZE;
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sint32} field, including tag.
 */
int32_t computeSInt32SizeNoTag(int32_t value) {
	return computeRawVarint32Size(encodeZigZag32(value));
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sint64} field, including tag.
 */
int32_t computeSInt64SizeNoTag(int64_t value) {
	return computeRawVarint64Size(encodeZigZag64(value));
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code double} field, including tag.
 */
int32_t computeDoubleSize(int32_t fieldNumber, Float64 value) {
	return computeTagSize(fieldNumber) + computeDoubleSizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code float} field, including tag.
 */
int32_t computeFloatSize(int32_t fieldNumber, Float32 value) {
	return computeTagSize(fieldNumber) + computeFloatSizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code uint64} field, including tag.
 */
int32_t computeUInt64Size(int32_t fieldNumber, int64_t value) {
	return computeTagSize(fieldNumber) + computeUInt64SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code int64} field, including tag.
 */
int32_t computeInt64Size(int32_t fieldNumber, int64_t value) {
	return computeTagSize(fieldNumber) + computeInt64SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code int32} field, including tag.
 */
int32_t computeInt32Size(int32_t fieldNumber, int32_t value) {
	return computeTagSize(fieldNumber) + computeInt32SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code fixed64} field, including tag.
 */
int32_t computeFixed64Size(int32_t fieldNumber, int64_t value) {
	return computeTagSize(fieldNumber) + computeFixed64SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code fixed32} field, including tag.
 */
int32_t computeFixed32Size(int32_t fieldNumber, int32_t value) {
	return computeTagSize(fieldNumber) + computeFixed32SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code bool} field, including tag.
 */
int32_t computeBoolSize(int32_t fieldNumber, BOOL value) {
	return computeTagSize(fieldNumber) + computeBoolSizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code string} field, including tag.
 */
int32_t computeStringSize(int32_t fieldNumber, NSString* value) {
	return computeTagSize(fieldNumber) + computeStringSizeNoTag(value);
}

/**
 * Compute the number of bytes that would be needed to encode a
 * {@code bytes} field, including tag.
 */
int32_t computeDataSize(int32_t fieldNumber, NSData* value) {
	return computeTagSize(fieldNumber) + computeDataSizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode a
 * {@code uint32} field, including tag.
 */
int32_t computeUInt32Size(int32_t fieldNumber, int32_t value) {
	return computeTagSize(fieldNumber) + computeUInt32SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * enum field, including tag.  Caller is responsible for converting the
 * enum value to its numeric value.
 */
int32_t computeEnumSize(int32_t fieldNumber, int32_t value) {
	return computeTagSize(fieldNumber) + computeEnumSizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sfixed32} field, including tag.
 */
int32_t computeSFixed32Size(int32_t fieldNumber, int32_t value) {
	return computeTagSize(fieldNumber) + computeSFixed32SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sfixed64} field, including tag.
 */
int32_t computeSFixed64Size(int32_t fieldNumber, int64_t value) {
	return computeTagSize(fieldNumber) + computeSFixed64SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sint32} field, including tag.
 */
int32_t computeSInt32Size(int32_t fieldNumber, int32_t value) {
	return computeTagSize(fieldNumber) + computeSInt32SizeNoTag(value);
}


/**
 * Compute the number of bytes that would be needed to encode an
 * {@code sint64} field, including tag.
 */
int32_t computeSInt64Size(int32_t fieldNumber, int64_t value) {
	return computeTagSize(fieldNumber) +
	computeRawVarint64Size(encodeZigZag64(value));
}

/**
 * Compute the number of bytes that would be needed to encode an
 * unparsed MessageSet extension field to the stream.  For
 * historical reasons, the wire format differs from normal fields.
 */
int32_t computeRawMessageSetExtensionSize(int32_t fieldNumber, NSData* value) {
	return computeTagSize(PBWireFormatMessageSetItem) * 2 +
	computeUInt32Size(PBWireFormatMessageSetTypeId, fieldNumber) +
	computeDataSize(PBWireFormatMessageSetMessage, value);
}



/** Compute the number of bytes that would be needed to encode a tag. */
int32_t computeTagSize(int32_t fieldNumber) {
	return computeRawVarint32Size(PBWireFormatMakeTag(fieldNumber, 0));
}


/**
 * Compute the number of bytes that would be needed to encode a varint.
 * {@code value} is treated as unsigned, so it won't be sign-extended if
 * negative.
 */
int32_t computeRawVarint32Size(int32_t value) {
	if ((value & (0xffffffff <<  7)) == 0) return 1;
	if ((value & (0xffffffff << 14)) == 0) return 2;
	if ((value & (0xffffffff << 21)) == 0) return 3;
	if ((value & (0xffffffff << 28)) == 0) return 4;
	return 5;
}


/** Compute the number of bytes that would be needed to encode a varint. */
int32_t computeRawVarint64Size(int64_t value) {
	if ((value & (0xffffffffffffffffL <<  7)) == 0) return 1;
	if ((value & (0xffffffffffffffffL << 14)) == 0) return 2;
	if ((value & (0xffffffffffffffffL << 21)) == 0) return 3;
	if ((value & (0xffffffffffffffffL << 28)) == 0) return 4;
	if ((value & (0xffffffffffffffffL << 35)) == 0) return 5;
	if ((value & (0xffffffffffffffffL << 42)) == 0) return 6;
	if ((value & (0xffffffffffffffffL << 49)) == 0) return 7;
	if ((value & (0xffffffffffffffffL << 56)) == 0) return 8;
	if ((value & (0xffffffffffffffffL << 63)) == 0) return 9;
	return 10;
}


/**
 * Encode a ZigZag-encoded 32-bit value.  ZigZag encodes signed integers
 * into values that can be efficiently encoded with varint.  (Otherwise,
 * negative values must be sign-extended to 64 bits to be varint encoded,
 * thus always taking 10 bytes on the wire.)
 *
 * @param n A signed 32-bit integer.
 * @return An unsigned 32-bit integer, stored in a signed int
 */
int32_t encodeZigZag32(int32_t n) {
	// Note:  the right-shift must be arithmetic
	return (n << 1) ^ (n >> 31);
}


/**
 * Encode a ZigZag-encoded 64-bit value.  ZigZag encodes signed integers
 * into values that can be efficiently encoded with varint.  (Otherwise,
 * negative values must be sign-extended to 64 bits to be varint encoded,
 * thus always taking 10 bytes on the wire.)
 *
 * @param n A signed 64-bit integer.
 * @return An unsigned 64-bit integer, stored in a signed int
 */
int64_t encodeZigZag64(int64_t n) {
	// Note:  the right-shift must be arithmetic
	return (n << 1) ^ (n >> 63);
}


