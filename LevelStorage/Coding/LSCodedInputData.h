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

class LSCodedInputData {
	uint8_t* bufferPointer;
	int32_t bufferSize;
	int32_t bufferSizeAfterLimit;
	int32_t bufferPos;
	int32_t lastTag;
	
	/** The absolute position of the end of the current message. */
	int32_t currentLimit;
	
	/** See setRecursionLimit() */
	int32_t recursionDepth;
	int32_t recursionLimit;
	
	/** See setSizeLimit() */
	int32_t sizeLimit;

public:
	LSCodedInputData(NSData* oData);
	~LSCodedInputData();
	
	bool isAtEnd() { return bufferPos == bufferSize; };
	void checkLastTagWas(int32_t value);
	
	int32_t readTag();
	BOOL readBool();
	Float64 readDouble();
	Float32 readFloat();
	int64_t readUInt64();
	int32_t readUInt32();
	int64_t readInt64();
	int32_t readInt32();
	int64_t readFixed64();
	int32_t readFixed32();
	int32_t readEnum();
	int32_t readSFixed32();
	int64_t readSFixed64();
	int32_t readSInt32();
	int64_t readSInt64();
	
	NSString* readString();
	NSData* readData();
	
	/**
	 * Read one byte from the input.
	 *
	 * @throws InvalidProtocolBuffer The end of the stream or the current
	 *                                        limit was reached.
	 */
	int8_t readRawByte();
	
	/**
	 * Read a raw Varint from the stream.  If larger than 32 bits, discard the
	 * upper bits.
	 */
	int32_t readRawVarint32();
	int64_t readRawVarint64();
	int32_t readRawLittleEndian32();
	int64_t readRawLittleEndian64();
	
	/**
	 * Read a fixed size of bytes from the input.
	 *
	 * @throws InvalidProtocolBuffer The end of the stream or the current
	 *                                        limit was reached.
	 */
	NSData* readRawData(int32_t size);
	
	BOOL skipField(int32_t tag);
	
	int32_t decodeZigZag32(int32_t n);
	int64_t decodeZigZag64(int64_t n);
	
	int32_t setSizeLimit(int32_t limit);
	int32_t pushLimit(int32_t byteLimit);
	void recomputeBufferSizeAfterLimit();
	void popLimit(int32_t oldLimit);
	int32_t bytesUntilLimit();
	
	int8_t readRawByte(int8_t* bufferPointer, int32_t* bufferPos, int32_t bufferSize);
	void skipRawData(int32_t size);
};
