//
//  LSEncodeItem.h
//  LSCoder
//
//  Created by jasenhuang on 2018/11/8.
//  Copyright © 2018 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum LSEncodeItemType {
	LSEncodeItemType_None,
	LSEncodeItemType_Bool,
	LSEncodeItemType_Enum,
	LSEncodeItemType_Int32,
	LSEncodeItemType_Int64,
	LSEncodeItemType_UInt32,
	LSEncodeItemType_UInt64,
	LSEncodeItemType_Float,
	LSEncodeItemType_Double,

	LSEncodeItemType_Fixed32,
	LSEncodeItemType_Fixed64,
	LSEncodeItemType_SFixed32,
	LSEncodeItemType_SFixed64,

	LSEncodeItemType_Point,
	LSEncodeItemType_Size,
	LSEncodeItemType_Rect,

	LSEncodeItemType_NSString,
	LSEncodeItemType_NSData,
	LSEncodeItemType_NSDate,
	LSEncodeItemType_NSNumber,
	LSEncodeItemType_NSContainer,
	LSEncodeItemType_NSContainer_UNPACKED,
	
	LSEncodeItemType_Object,
};

struct LSEncodeItem
{
	LSEncodeItemType type;
	bool hasTag;
	int32_t compiledTag;
	int32_t compiledSize;
	int32_t valueSize;
	union {
		bool boolValue;
		int32_t int32Value;
		int64_t int64Value;
		uint32_t uint32Value;
		uint64_t uint64Value;
		float floatValue;
		double doubleValue;
		CGPoint pointValue;
		CGSize sizeValue;
		CGRect rectValue;
		void* objectValue;
		void* tmpObjectValue;	// this object should release on dealloc
	} value;
	
	LSEncodeItem()
		:type(LSEncodeItemType_None), hasTag(false), compiledTag(0), compiledSize(0), valueSize(0)
	{
		memset(&value, 0, sizeof(value));
	}
	
	LSEncodeItem(const LSEncodeItem& other)
		:type(other.type), hasTag(other.hasTag), compiledTag(other.compiledTag), compiledSize(other.compiledSize), valueSize(other.valueSize), value(other.value)
	{
		if (type == LSEncodeItemType_NSNumber || type == LSEncodeItemType_NSString) {
			if (value.tmpObjectValue != NULL) {
				CFRetain(value.tmpObjectValue);
			}
		}
	}
	
	LSEncodeItem& operator = (const LSEncodeItem& other)
	{
		type = other.type;
		hasTag = other.hasTag;
		compiledTag = other.compiledTag;
		compiledSize = other.compiledSize;
		valueSize = other.valueSize;
		value = other.value;

		if (type == LSEncodeItemType_NSNumber || type == LSEncodeItemType_NSString) {
			if (value.tmpObjectValue != NULL) {
				CFRetain(value.tmpObjectValue);
			}
		}

		return *this;
	}
	
	~LSEncodeItem()
	{
		// release tmpObjectValue, currently only NSNumber/NSString will generate it
		if (type == LSEncodeItemType_NSNumber || type == LSEncodeItemType_NSString) {
			if (value.tmpObjectValue != NULL) {
				CFRelease(value.tmpObjectValue);
				value.tmpObjectValue = NULL;
			}
		}
	}
};
