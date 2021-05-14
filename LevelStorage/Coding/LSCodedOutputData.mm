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

#import "LSCodedOutputData.h"
#import "LSWireFormat.h"
#import "LSUtility.h"

#if ! __has_feature(objc_arc)
#error LSCoding must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

LSCodedOutputData::LSCodedOutputData(void* ptr, size_t len) {
	bufferPointer = (uint8_t*)ptr;
	bufferLength = len;
	position = 0;
}

LSCodedOutputData::LSCodedOutputData(NSMutableData* oData) {
	bufferPointer = (uint8_t*)oData.mutableBytes;
	bufferLength = oData.length;
	position = 0;
}

LSCodedOutputData::~LSCodedOutputData() {
	bufferPointer = NULL;
	bufferLength = 0;
	position = 0;
}

void LSCodedOutputData::writeDoubleNoTag(Float64 value) {
	this->writeRawLittleEndian64(convertFloat64ToInt64(value));
}


/** Write a {@code double} field, including tag, to the stream. */
void LSCodedOutputData::writeDouble(int32_t fieldNumber, Float64 value) {
	this->writeTag(fieldNumber, PBWireFormatFixed64);
	this->writeDoubleNoTag(value);
}


void LSCodedOutputData::writeFloatNoTag(Float32 value) {
	this->writeRawLittleEndian32(convertFloat32ToInt32(value));
}


/** Write a {@code float} field, including tag, to the stream. */
void LSCodedOutputData::writeFloat(int32_t fieldNumber, Float32 value) {
	this->writeTag(fieldNumber, PBWireFormatFixed32);
	this->writeFloatNoTag(value);
}


void LSCodedOutputData::writeUInt64NoTag(int64_t value) {
	this->writeRawVarint64(value);
}


/** Write a {@code uint64} field, including tag, to the stream. */
void LSCodedOutputData::writeUInt64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeUInt64NoTag(value);
}


void LSCodedOutputData::writeInt64NoTag(int64_t value) {
	this->writeRawVarint64(value);
}


/** Write an {@code int64} field, including tag, to the stream. */
void LSCodedOutputData::writeInt64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeInt64NoTag(value);
}


void LSCodedOutputData::writeInt32NoTag(int32_t value) {
	if (value >= 0) {
		this->writeRawVarint32(value);
	} else {
		// Must sign-extend
		this->writeRawVarint64(value);
	}
}


/** Write an {@code int32} field, including tag, to the stream. */
void LSCodedOutputData::writeInt32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeInt32NoTag(value);
}


void LSCodedOutputData::writeFixed64NoTag(int64_t value) {
	this->writeRawLittleEndian64(value);
}


/** Write a {@code fixed64} field, including tag, to the stream. */
void LSCodedOutputData::writeFixed64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed64);
	this->writeFixed64NoTag(value);
}


void LSCodedOutputData::writeFixed32NoTag(int32_t value) {
	this->writeRawLittleEndian32(value);
}


/** Write a {@code fixed32} field, including tag, to the stream. */
void LSCodedOutputData::writeFixed32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed32);
	this->writeFixed32NoTag(value);
}


void LSCodedOutputData::writeBoolNoTag(BOOL value) {
	this->writeRawByte(value ? 1 : 0);
}


/** Write a {@code bool} field, including tag, to the stream. */
void LSCodedOutputData::writeBool(int32_t fieldNumber, BOOL value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeBoolNoTag(value);
}


void LSCodedOutputData::writeStringNoTag(NSString* value) {
	int32_t numberOfBytes = static_cast<int32_t>([value lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	this->writeRawVarint32(numberOfBytes);
	//	memcpy(bufferPointer + position, ((uint8_t*)value.bytes), numberOfBytes);
	[value getBytes:bufferPointer + position
		  maxLength:numberOfBytes
		 usedLength:0
		   encoding:NSUTF8StringEncoding
			options:0
			  range:NSMakeRange(0, value.length)
	 remainingRange:NULL];
	position += numberOfBytes;
}

void LSCodedOutputData::writeStringNoTag(NSString* value, NSUInteger numberOfBytes) {
	[value getBytes:bufferPointer + position
		  maxLength:numberOfBytes
		 usedLength:0
		   encoding:NSUTF8StringEncoding
			options:0
			  range:NSMakeRange(0, value.length)
	 remainingRange:NULL];
	position += numberOfBytes;
}


/** Write a {@code string} field, including tag, to the stream. */
void LSCodedOutputData::writeString(int32_t fieldNumber, NSString* value) {
	// TODO(cyrusn): we could probably use:
	// NSString:getBytes:maxLength:usedLength:encoding:options:range:remainingRange:
	// to write directly into our buffer.
	this->writeTag(fieldNumber, PBWireFormatLengthDelimited);
	this->writeStringNoTag(value);
}

void LSCodedOutputData::writeDataNoTag(NSData* value) {
	this->writeRawVarint32(static_cast<int32_t>(value.length));
	this->writeRawData(value);
}


/** Write a {@code bytes} field, including tag, to the stream. */
void LSCodedOutputData::writeData(int32_t fieldNumber, NSData* value) {
	this->writeTag(fieldNumber, PBWireFormatLengthDelimited);
	this->writeDataNoTag(value);
}


void LSCodedOutputData::writeUInt32NoTag(int32_t value) {
	this->writeRawVarint32(value);
}


/** Write a {@code uint32} field, including tag, to the stream. */
void LSCodedOutputData::writeUInt32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeUInt32NoTag(value);
}


void LSCodedOutputData::writeEnumNoTag(int32_t value) {
	this->writeRawVarint32(value);
}


/**
 * Write an enum field, including tag, to the stream.  Caller is responsible
 * for converting the enum value to its numeric value.
 */
void LSCodedOutputData::writeEnum(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeEnumNoTag(value);
}


void LSCodedOutputData::writeSFixed32NoTag(int32_t value) {
	this->writeRawLittleEndian32(value);
}


/** Write an {@code sfixed32} field, including tag, to the stream. */
void LSCodedOutputData::writeSFixed32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed32);
	this->writeSFixed32NoTag(value);
}


void LSCodedOutputData::writeSFixed64NoTag(int64_t value) {
	this->writeRawLittleEndian64(value);
}


/** Write an {@code sfixed64} field, including tag, to the stream. */
void LSCodedOutputData::writeSFixed64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed64);
	this->writeSFixed64NoTag(value);
}


void LSCodedOutputData::writeSInt32NoTag(int32_t value) {
	this->writeRawVarint32(encodeZigZag32(value));
}


/** Write an {@code sint32} field, including tag, to the stream. */
void LSCodedOutputData::writeSInt32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeSInt32NoTag(value);
}


void LSCodedOutputData::writeSInt64NoTag(int64_t value) {
	this->writeRawVarint64(encodeZigZag64(value));
}


/** Write an {@code sint64} field, including tag, to the stream. */
void LSCodedOutputData::writeSInt64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeSInt64NoTag(value);
}


/**
 * If writing to a flat array, return the space left in the array.
 * Otherwise, throws {@code UnsupportedOperationException}.
 */
int32_t LSCodedOutputData::spaceLeft() {
	return static_cast<int32_t>(bufferLength) - position;
}

void LSCodedOutputData::seek(size_t addedSize) {
	position += addedSize;
	
	if (position > bufferLength) {
		@throw [NSException exceptionWithName:@"OutOfSpace" reason:@"" userInfo:nil];
	}
}

/**
 * Verifies that {@link #spaceLeft()} returns zero.  It's common to create
 * a byte array that is exactly big enough to hold a message, then write to
 * it with a {@code WXPBCodedOutputStream}.  Calling {@code checkNoSpaceLeft()}
 * after writing verifies that the message was actually as big as expected,
 * which can help catch bugs.
 */
void LSCodedOutputData::checkNoSpaceLeft() {
	if (this->spaceLeft() != 0) {
		//NSLog(@"IllegalState-Did not write as much data as expected.");
		@throw [NSException exceptionWithName:@"IllegalState" reason:@"Did not write as much data as expected." userInfo:nil];
	}
}


/** Write a single byte. */
void LSCodedOutputData::writeRawByte(uint8_t value) {
	if (position == bufferLength) {
		@throw [NSException exceptionWithName:@"OutOfSpace" reason:@"" userInfo:nil];
	}
	
	bufferPointer[position++] = value;
}


/** Write an array of bytes. */
void LSCodedOutputData::writeRawData(NSData* data) {
	this->writeRawData(data, 0, static_cast<int32_t>(data.length));
}


void LSCodedOutputData::writeRawData(NSData* value, int32_t offset, int32_t length) {
	if (bufferLength - position >= length) {
		// We have room in the current buffer.
		memcpy(bufferPointer + position, ((uint8_t*)value.bytes) + offset, length);
		position += length;
	} else {
		[NSException exceptionWithName:@"Space" reason:@"too much data than calc" userInfo:nil];
	}
}


/** Encode and write a tag. */
void LSCodedOutputData::writeTag(int32_t fieldNumber, int32_t format) {
	this->writeRawVarint32(PBWireFormatMakeTag(fieldNumber, format));
}


/**
 * Encode and write a varint.  {@code value} is treated as
 * unsigned, so it won't be sign-extended if negative.
 */
void LSCodedOutputData::writeRawVarint32(int32_t value) {
	while (YES) {
		if ((value & ~0x7F) == 0) {
			this->writeRawByte(value);
			return;
		} else {
			this->writeRawByte((value & 0x7F) | 0x80);
			value = logicalRightShift32(value, 7);
		}
	}
}


/** Encode and write a varint. */
void LSCodedOutputData::writeRawVarint64(int64_t value) {
	while (YES) {
		if ((value & ~0x7FL) == 0) {
			this->writeRawByte((int32_t) value);
			return;
		} else {
			this->writeRawByte(((int32_t) value & 0x7F) | 0x80);
			value = logicalRightShift64(value, 7);
		}
	}
}


/** Write a little-endian 32-bit integer. */
void LSCodedOutputData::writeRawLittleEndian32(int32_t value) {
	this->writeRawByte((value      ) & 0xFF);
	this->writeRawByte((value >>  8) & 0xFF);
	this->writeRawByte((value >> 16) & 0xFF);
	this->writeRawByte((value >> 24) & 0xFF);
}


/** Write a little-endian 64-bit integer. */
void LSCodedOutputData::writeRawLittleEndian64(int64_t value) {
	this->writeRawByte((int32_t)(value      ) & 0xFF);
	this->writeRawByte((int32_t)(value >>  8) & 0xFF);
	this->writeRawByte((int32_t)(value >> 16) & 0xFF);
	this->writeRawByte((int32_t)(value >> 24) & 0xFF);
	this->writeRawByte((int32_t)(value >> 32) & 0xFF);
	this->writeRawByte((int32_t)(value >> 40) & 0xFF);
	this->writeRawByte((int32_t)(value >> 48) & 0xFF);
	this->writeRawByte((int32_t)(value >> 56) & 0xFF);
}
