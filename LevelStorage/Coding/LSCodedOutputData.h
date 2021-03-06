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

#pragma once

class LSCodedOutputData {
	uint8_t* bufferPointer;
	size_t bufferLength;
    int32_t position;
	
	void checkNoSpaceLeft();
	
public:
	LSCodedOutputData(void* ptr, size_t len);
	LSCodedOutputData(NSMutableData* odata);
	~LSCodedOutputData();
	
	int32_t spaceLeft();
	void seek(size_t addedSize);

	void writeRawByte(uint8_t value);
	
	void writeTag(int32_t fieldNumber, int32_t format);
	
	void writeRawLittleEndian32(int32_t value);
	void writeRawLittleEndian64(int64_t value);
	
	/**
	 * Encode and write a varint.  value is treated as
	 * unsigned, so it won't be sign-extended if negative.
	 */
	void writeRawVarint32(int32_t value);
	void writeRawVarint64(int64_t value);
	
	void writeRawData(NSData* data);
	void writeRawData(NSData* data, int32_t offset, int32_t length);
	
	void writeData(int32_t fieldNumber, NSData* value);
	
	void writeDouble(int32_t fieldNumber, Float64 value);
	void writeFloat(int32_t fieldNumber , Float32 value);
	void writeUInt64(int32_t fieldNumber , int64_t value);
	void writeInt64(int32_t fieldNumber , int64_t value);
	void writeInt32(int32_t fieldNumber , int32_t value);
	void writeFixed64(int32_t fieldNumber , int64_t value);
	void writeFixed32(int32_t fieldNumber , int32_t value);
	void writeBool(int32_t fieldNumber , BOOL value);
	void writeString(int32_t fieldNumber , NSString* value);
	void writeUInt32(int32_t fieldNumber , int32_t value);
	void writeSFixed32(int32_t fieldNumber , int32_t value);
	void writeSFixed64(int32_t fieldNumber , int64_t value);
	void writeSInt32(int32_t fieldNumber , int32_t value);
	void writeSInt64(int32_t fieldNumber , int64_t value);
	
	void writeDoubleNoTag(Float64 value);
	void writeFloatNoTag(Float32 value);
	void writeUInt64NoTag(int64_t value);
	void writeInt64NoTag(int64_t value);
	void writeInt32NoTag(int32_t value);
	void writeFixed64NoTag(int64_t value);
	void writeFixed32NoTag(int32_t value);
	void writeBoolNoTag(BOOL value);
	void writeStringNoTag(NSString* value);
	void writeStringNoTag(NSString* value, NSUInteger numberOfBytes);
	void writeDataNoTag(NSData* value);
	void writeUInt32NoTag(int32_t value);
	void writeEnumNoTag(int32_t value);
	void writeSFixed32NoTag(int32_t value);
	void writeSFixed64NoTag(int64_t value);
	void writeSInt32NoTag(int32_t value);
	void writeSInt64NoTag(int64_t value);


	/**
	 * Write an enum field, including tag, to the stream.  Caller is responsible
	 * for converting the enum value to its numeric value.
	 */
	void writeEnum(int32_t fieldNumber , int32_t value);
};

