//
//  PBEncodeItem.h
//  PBCoder
//
//  Created by Guo Ling on 4/19/13.
//  Copyright (c) 2013 Guo Ling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum PBEncodeItemType {
	PBEncodeItemType_None,
	PBEncodeItemType_Bool,
	PBEncodeItemType_Enum,
	PBEncodeItemType_Int32,
	PBEncodeItemType_Int64,
	PBEncodeItemType_UInt32,
	PBEncodeItemType_UInt64,
	PBEncodeItemType_Float,
	PBEncodeItemType_Double,

	PBEncodeItemType_Fixed32,
	PBEncodeItemType_Fixed64,
	PBEncodeItemType_SFixed32,
	PBEncodeItemType_SFixed64,

	PBEncodeItemType_Point,
	PBEncodeItemType_Size,
	PBEncodeItemType_Rect,

	PBEncodeItemType_NSString,
	PBEncodeItemType_NSData,
	PBEncodeItemType_NSDate,
	PBEncodeItemType_NSNumber,
	PBEncodeItemType_NSContainer,
	PBEncodeItemType_NSContainer_UNPACKED,
	
	PBEncodeItemType_Object,
};

struct PBEncodeItem
{
	PBEncodeItemType type;
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
	
	PBEncodeItem()
		:type(PBEncodeItemType_None), hasTag(false), compiledTag(0), compiledSize(0), valueSize(0)
	{
		memset(&value, 0, sizeof(value));
	}
	
	PBEncodeItem(const PBEncodeItem& other)
		:type(other.type), hasTag(other.hasTag), compiledTag(other.compiledTag), compiledSize(other.compiledSize), valueSize(other.valueSize), value(other.value)
	{
		if (type == PBEncodeItemType_NSNumber || type == PBEncodeItemType_NSString) {
			if (value.tmpObjectValue != NULL) {
				CFRetain(value.tmpObjectValue);
			}
		}
	}
	
	PBEncodeItem& operator = (const PBEncodeItem& other)
	{
		type = other.type;
		hasTag = other.hasTag;
		compiledTag = other.compiledTag;
		compiledSize = other.compiledSize;
		valueSize = other.valueSize;
		value = other.value;

		if (type == PBEncodeItemType_NSNumber || type == PBEncodeItemType_NSString) {
			if (value.tmpObjectValue != NULL) {
				CFRetain(value.tmpObjectValue);
			}
		}

		return *this;
	}
	
	~PBEncodeItem()
	{
		// release tmpObjectValue, currently only NSNumber/NSString will generate it
		if (type == PBEncodeItemType_NSNumber || type == PBEncodeItemType_NSString) {
			if (value.tmpObjectValue != NULL) {
				CFRelease(value.tmpObjectValue);
				value.tmpObjectValue = NULL;
			}
		}
	}
};
