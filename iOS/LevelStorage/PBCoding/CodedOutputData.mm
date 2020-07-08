//
//  CodedOutputData.mm
//  StorageProfile
//
//  Created by Ling Guo on 4/17/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "CodedOutputData.h"
#import "WireFormat.h"
#import "PBUtility.h"

#if ! __has_feature(objc_arc)
#error PBCoding must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

CodedOutputData::CodedOutputData(void* ptr, size_t len) {
	bufferPointer = (uint8_t*)ptr;
	bufferLength = len;
	position = 0;
}

CodedOutputData::CodedOutputData(NSMutableData* oData) {
	bufferPointer = (uint8_t*)oData.mutableBytes;
	bufferLength = oData.length;
	position = 0;
}

CodedOutputData::~CodedOutputData() {
	bufferPointer = NULL;
	bufferLength = 0;
	position = 0;
}

void CodedOutputData::writeDoubleNoTag(Float64 value) {
	this->writeRawLittleEndian64(convertFloat64ToInt64(value));
}


/** Write a {@code double} field, including tag, to the stream. */
void CodedOutputData::writeDouble(int32_t fieldNumber, Float64 value) {
	this->writeTag(fieldNumber, PBWireFormatFixed64);
	this->writeDoubleNoTag(value);
}


void CodedOutputData::writeFloatNoTag(Float32 value) {
	this->writeRawLittleEndian32(convertFloat32ToInt32(value));
}


/** Write a {@code float} field, including tag, to the stream. */
void CodedOutputData::writeFloat(int32_t fieldNumber, Float32 value) {
	this->writeTag(fieldNumber, PBWireFormatFixed32);
	this->writeFloatNoTag(value);
}


void CodedOutputData::writeUInt64NoTag(int64_t value) {
	this->writeRawVarint64(value);
}


/** Write a {@code uint64} field, including tag, to the stream. */
void CodedOutputData::writeUInt64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeUInt64NoTag(value);
}


void CodedOutputData::writeInt64NoTag(int64_t value) {
	this->writeRawVarint64(value);
}


/** Write an {@code int64} field, including tag, to the stream. */
void CodedOutputData::writeInt64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeInt64NoTag(value);
}


void CodedOutputData::writeInt32NoTag(int32_t value) {
	if (value >= 0) {
		this->writeRawVarint32(value);
	} else {
		// Must sign-extend
		this->writeRawVarint64(value);
	}
}


/** Write an {@code int32} field, including tag, to the stream. */
void CodedOutputData::writeInt32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeInt32NoTag(value);
}


void CodedOutputData::writeFixed64NoTag(int64_t value) {
	this->writeRawLittleEndian64(value);
}


/** Write a {@code fixed64} field, including tag, to the stream. */
void CodedOutputData::writeFixed64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed64);
	this->writeFixed64NoTag(value);
}


void CodedOutputData::writeFixed32NoTag(int32_t value) {
	this->writeRawLittleEndian32(value);
}


/** Write a {@code fixed32} field, including tag, to the stream. */
void CodedOutputData::writeFixed32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed32);
	this->writeFixed32NoTag(value);
}


void CodedOutputData::writeBoolNoTag(BOOL value) {
	this->writeRawByte(value ? 1 : 0);
}


/** Write a {@code bool} field, including tag, to the stream. */
void CodedOutputData::writeBool(int32_t fieldNumber, BOOL value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeBoolNoTag(value);
}


void CodedOutputData::writeStringNoTag(NSString* value) {
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

void CodedOutputData::writeStringNoTag(NSString* value, NSUInteger numberOfBytes) {
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
void CodedOutputData::writeString(int32_t fieldNumber, NSString* value) {
	// TODO(cyrusn): we could probably use:
	// NSString:getBytes:maxLength:usedLength:encoding:options:range:remainingRange:
	// to write directly into our buffer.
	this->writeTag(fieldNumber, PBWireFormatLengthDelimited);
	this->writeStringNoTag(value);
}

void CodedOutputData::writeDataNoTag(NSData* value) {
	this->writeRawVarint32(static_cast<int32_t>(value.length));
	this->writeRawData(value);
}


/** Write a {@code bytes} field, including tag, to the stream. */
void CodedOutputData::writeData(int32_t fieldNumber, NSData* value) {
	this->writeTag(fieldNumber, PBWireFormatLengthDelimited);
	this->writeDataNoTag(value);
}


void CodedOutputData::writeUInt32NoTag(int32_t value) {
	this->writeRawVarint32(value);
}


/** Write a {@code uint32} field, including tag, to the stream. */
void CodedOutputData::writeUInt32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeUInt32NoTag(value);
}


void CodedOutputData::writeEnumNoTag(int32_t value) {
	this->writeRawVarint32(value);
}


/**
 * Write an enum field, including tag, to the stream.  Caller is responsible
 * for converting the enum value to its numeric value.
 */
void CodedOutputData::writeEnum(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeEnumNoTag(value);
}


void CodedOutputData::writeSFixed32NoTag(int32_t value) {
	this->writeRawLittleEndian32(value);
}


/** Write an {@code sfixed32} field, including tag, to the stream. */
void CodedOutputData::writeSFixed32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed32);
	this->writeSFixed32NoTag(value);
}


void CodedOutputData::writeSFixed64NoTag(int64_t value) {
	this->writeRawLittleEndian64(value);
}


/** Write an {@code sfixed64} field, including tag, to the stream. */
void CodedOutputData::writeSFixed64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatFixed64);
	this->writeSFixed64NoTag(value);
}


void CodedOutputData::writeSInt32NoTag(int32_t value) {
	this->writeRawVarint32(encodeZigZag32(value));
}


/** Write an {@code sint32} field, including tag, to the stream. */
void CodedOutputData::writeSInt32(int32_t fieldNumber, int32_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeSInt32NoTag(value);
}


void CodedOutputData::writeSInt64NoTag(int64_t value) {
	this->writeRawVarint64(encodeZigZag64(value));
}


/** Write an {@code sint64} field, including tag, to the stream. */
void CodedOutputData::writeSInt64(int32_t fieldNumber, int64_t value) {
	this->writeTag(fieldNumber, PBWireFormatVarint);
	this->writeSInt64NoTag(value);
}


/**
 * If writing to a flat array, return the space left in the array.
 * Otherwise, throws {@code UnsupportedOperationException}.
 */
int32_t CodedOutputData::spaceLeft() {
	return static_cast<int32_t>(bufferLength) - position;
}

void CodedOutputData::seek(size_t addedSize) {
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
void CodedOutputData::checkNoSpaceLeft() {
	if (this->spaceLeft() != 0) {
		//NSLog(@"IllegalState-Did not write as much data as expected.");
		@throw [NSException exceptionWithName:@"IllegalState" reason:@"Did not write as much data as expected." userInfo:nil];
	}
}


/** Write a single byte. */
void CodedOutputData::writeRawByte(uint8_t value) {
	if (position == bufferLength) {
		@throw [NSException exceptionWithName:@"OutOfSpace" reason:@"" userInfo:nil];
	}
	
	bufferPointer[position++] = value;
}


/** Write an array of bytes. */
void CodedOutputData::writeRawData(NSData* data) {
	this->writeRawData(data, 0, static_cast<int32_t>(data.length));
}


void CodedOutputData::writeRawData(NSData* value, int32_t offset, int32_t length) {
	if (bufferLength - position >= length) {
		// We have room in the current buffer.
		memcpy(bufferPointer + position, ((uint8_t*)value.bytes) + offset, length);
		position += length;
	} else {
		[NSException exceptionWithName:@"Space" reason:@"too much data than calc" userInfo:nil];
	}
}


/** Encode and write a tag. */
void CodedOutputData::writeTag(int32_t fieldNumber, int32_t format) {
	this->writeRawVarint32(PBWireFormatMakeTag(fieldNumber, format));
}


/**
 * Encode and write a varint.  {@code value} is treated as
 * unsigned, so it won't be sign-extended if negative.
 */
void CodedOutputData::writeRawVarint32(int32_t value) {
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
void CodedOutputData::writeRawVarint64(int64_t value) {
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
void CodedOutputData::writeRawLittleEndian32(int32_t value) {
	this->writeRawByte((value      ) & 0xFF);
	this->writeRawByte((value >>  8) & 0xFF);
	this->writeRawByte((value >> 16) & 0xFF);
	this->writeRawByte((value >> 24) & 0xFF);
}


/** Write a little-endian 64-bit integer. */
void CodedOutputData::writeRawLittleEndian64(int64_t value) {
	this->writeRawByte((int32_t)(value      ) & 0xFF);
	this->writeRawByte((int32_t)(value >>  8) & 0xFF);
	this->writeRawByte((int32_t)(value >> 16) & 0xFF);
	this->writeRawByte((int32_t)(value >> 24) & 0xFF);
	this->writeRawByte((int32_t)(value >> 32) & 0xFF);
	this->writeRawByte((int32_t)(value >> 40) & 0xFF);
	this->writeRawByte((int32_t)(value >> 48) & 0xFF);
	this->writeRawByte((int32_t)(value >> 56) & 0xFF);
}
