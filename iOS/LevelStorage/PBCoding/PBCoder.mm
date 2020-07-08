//
//  PBCoder.mm
//  PBCoder
//
//  Created by Guo Ling on 4/14/13.
//  Copyright (c) 2013 Guo Ling. All rights reserved.
//
#include <sys/stat.h>
#import <vector>
#import "WireFormat.h"
#import "PBEncodeItem.h"
#import "CodedInputData.h"
#import "CodedOutputData.h"
#import "PBCoder+PropertyTable.h"

#if ! __has_feature(objc_arc)
#error PBCoding must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

// get setter of a property: setM_contact/setDelegate, etc
SEL genSetterSelector(NSString* property) {
    @autoreleasepool
    {
        unichar firstChar = [property characterAtIndex:0];
        firstChar = toupper(firstChar);
        
        NSString* subName = nil;
        if (property.length > 1) {
            subName = [property substringFromIndex:1];
        } else {
            subName = @"";
        }
        
        NSString* capName = [[NSString alloc] initWithFormat:@"set%c%@:", firstChar, subName];
        SEL retSel = NSSelectorFromString(capName);
        return retSel;
    }
}

static Class getClassOfClusterInstance(NSObject* obj) {
	static Class KnowClusterClasses[] = {
		[NSArray class], [NSMutableArray class],
		[NSDictionary class], [NSMutableDictionary class],
		[NSSet class], [NSMutableSet class],
		[NSString class], [NSMutableString class],
		[NSData class], [NSMutableData class],
		[NSDate class], [NSNumber class]
	};
	static int CountOfKnowClusterClasses = sizeof(KnowClusterClasses) / sizeof(KnowClusterClasses[0]);

	for (int i = 0; i < CountOfKnowClusterClasses; i++) {
		if ([obj isMemberOfClass:KnowClusterClasses[i]]) {
			return KnowClusterClasses[i];
		}
	}

	return NULL;
}

void _pbcoder_initPBTable(Class cls, NSMutableArray* arrWrap, std::map<size_t, size_t>& mapTagToIndex, bool& hasInit)
{
	if (!arrWrap) {
		return;
	}
	int propertyIndexOffset = 0;
	if (!hasInit) {
		hasInit = true;
		if (class_conformsToProtocol(class_getSuperclass(cls), @protocol(PBCoding))) {
			PBCoderPropertyType* superHolder = [[PBCoderPropertyType alloc] initWithClass:class_getSuperclass(cls) subClass:NULL index:0 getter:NULL setter:NULL blockGet:nil blockSet:nil];
			superHolder.m_isSuperPlaceHolder = YES;
			[arrWrap insertObject:superHolder atIndex:0];
			propertyIndexOffset = 1;
		}
	}
	for (size_t i = 0; i < arrWrap.count; i++) {
		PBCoderPropertyType* property = [arrWrap objectAtIndex:i];
		property.m_index += propertyIndexOffset;
		mapTagToIndex.insert(std::make_pair(property.m_index, i));
	}
}

template<typename T>
T blockGet(id target, id block) {
	T (^ oBlock)(id) = block;
	return oBlock(target);
};

template<typename T>
void blockSet(id target, id block, T value) {
	void (^oBlock)(id, T) = block;
	oBlock(target, value);
};


PBArrayAddHelper::PBArrayAddHelper(NSMutableArray* arr, PBCoderPropertyType* obj)
	: m_obj(obj)
{
#ifndef NDEBUG
	if (obj.m_subCls == NULL && obj.m_subCType == PBCoderCType_None &&
		(obj.m_cls == NSSet.class || obj.m_cls == NSMutableSet.class ||
		 obj.m_cls == NSArray.class || obj.m_cls == NSMutableArray.class ||
		 obj.m_cls == NSDictionary.class || obj.m_cls == NSMutableDictionary.class))
    {
        PBError(@"%@'s value type not set, use PBCODER_CONTAINER_PROPERTY() ?", NSStringFromClass(obj.m_cls));
        BOOL container_Has_No_ValueType = NO;
        assert(container_Has_No_ValueType);
    }
	else if (obj.m_subCls != NULL && obj.m_isContainerUnpacked)
	{
		if (obj.m_cls == NSDictionary.class || obj.m_cls == NSMutableDictionary.class)
		{
			NSLog(@"Error! %@ don't support unpacked", NSStringFromClass(obj.m_cls));
			BOOL container_cant_unpacked = NO;
			assert(container_cant_unpacked);
		}
	}
#endif
    [arr addObject:obj];
}

PBArrayAddHelper::~PBArrayAddHelper()
{
	m_obj = nil;
}

@implementation PBCoderPropertyType

-(id)initWithClass:(Class)cls subClass:(Class)subCls index:(uint32_t)index getter:(SEL)getter setter:(SEL)setter blockGet:(id)blockGet blockSet:(id)blockSet {
	if (self = [super init]) {
		_m_cls = cls;
		_m_subCls = subCls;
		_m_cType = PBCoderCType_None;
		_m_index = index;
		_m_getter = getter;
		_m_setter = setter;
		_m_blockGet = [blockGet copy];
		_m_blockSet = [blockSet copy];
		_m_isSuperPlaceHolder = NO;
		_m_isContainerUnpacked = NO;
	}
	return self;
}
-(id) initWithClass:(Class) cls subClass:(Class) subCls unpacked:(BOOL)unpacked index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet
{
	if (self = [super init]) {
		_m_cls = cls;
		_m_subCls = subCls;
		_m_cType = PBCoderCType_None;
		_m_index = index;
		_m_getter = getter;
		_m_setter = setter;
		_m_blockGet = [blockGet copy];
		_m_blockSet = [blockSet copy];
		_m_isSuperPlaceHolder = NO;
		_m_isContainerUnpacked = unpacked;
	}
	return self;
}
-(id) initWithClass:(Class) cls subCType:(PBCoderPropertyCType) subCType index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet
{
	if (self = [super init]) {
		_m_cls = cls;
		_m_subCType = subCType;
		_m_cType = PBCoderCType_None;
		_m_index = index;
		_m_getter = getter;
		_m_setter = setter;
		_m_blockGet = [blockGet copy];
		_m_blockSet = [blockSet copy];
		_m_isSuperPlaceHolder = NO;
		_m_isContainerUnpacked = NO;
	}
	return self;
}

-(id) initWithClass:(Class) cls subCType:(PBCoderPropertyCType) subCType unpacked:(BOOL)unpacked index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet
{
	if (self = [super init]) {
		_m_cls = cls;
		_m_subCType = subCType;
		_m_cType = PBCoderCType_None;
		_m_index = index;
		_m_getter = getter;
		_m_setter = setter;
		_m_blockGet = [blockGet copy];
		_m_blockSet = [blockSet copy];
		_m_isSuperPlaceHolder = NO;
		_m_isContainerUnpacked = unpacked;
	}
	return self;
}

-(id)initWithCType:(PBCoderPropertyCType)cType index:(uint32_t)index getter:(SEL)getter setter:(SEL)setter blockGet:(id)blockGet blockSet:(id)blockSet {
	if (self = [super init]) {
		_m_cls = NULL;
		_m_subCls = NULL;
		_m_cType = cType;
		_m_index = index;
		_m_getter = getter;
		_m_setter = setter;
		_m_blockGet = [blockGet copy];
		_m_blockSet = [blockSet copy];
		_m_isSuperPlaceHolder = NO;
		_m_isContainerUnpacked = NO;
	}
	return self;
}

@end

@implementation PBCoder {
	id<PBCoding> m_obj;
	
	BOOL m_isTopObject;
	NSData* m_inputData;
	CodedInputData* m_inputStream;
	NSNumberFormatter* m_numberFormatter;
	
	NSMutableData* m_outputData;
	CodedOutputData* m_outputStream;
	std::vector<PBEncodeItem>* m_encodeItems;
	
	void* m_formatBuffer;
	size_t m_formatBufferSize;
}

- (id)initForReadingWithData:(NSData *)data {
	if (self = [super init]) {
		m_isTopObject = YES;
        m_inputData = data;
		m_inputStream = new CodedInputData(data);
	}
	return self;
}

-(id)initForWritingWithTarget:(id<PBCoding>) obj {
	if (self = [super init]) {
        m_obj = obj;
	}
	return self;
}

-(void) dealloc {
	if (m_encodeItems) {
		delete m_encodeItems;
		m_encodeItems = NULL;
	}
	m_inputData = nil;
	m_numberFormatter = nil;
	m_outputData = nil;
	m_obj = nil;
	
	if (m_inputStream) {
		delete m_inputStream;
		m_inputStream = NULL;
	}
	if (m_outputStream) {
		delete m_outputStream;
		m_outputStream = NULL;
	}
	
	if (m_formatBuffer) {
		free(m_formatBuffer);
		m_formatBuffer = NULL;
		m_formatBufferSize = 0;
	}
}

#pragma mark - encode

// write object using prepared m_encodeItems[]
-(void) writeRootObject {
	for (size_t index = 0, total = m_encodeItems->size(); index < total; index++) {
		PBEncodeItem* encodeItem = &(*m_encodeItems)[index];
		// a root object should not write tag or size
		// a packed container should not write tag, but size is needed
		if (index == 0 && encodeItem->hasTag == false && encodeItem->type == PBEncodeItemType_Object) {
			continue;
		}
		
		switch (encodeItem->type) {
			case PBEncodeItemType_Bool:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeBoolNoTag(encodeItem->value.boolValue);
				break;
			}
			case PBEncodeItemType_Enum:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeEnumNoTag(encodeItem->value.int32Value);
				break;
			}
			case PBEncodeItemType_Int32:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeInt32NoTag(encodeItem->value.int32Value);
				break;
			}
			case PBEncodeItemType_Int64:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeInt64NoTag(encodeItem->value.int64Value);
				break;
			}
			case PBEncodeItemType_UInt32:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeUInt32NoTag(encodeItem->value.uint32Value);
				break;
			}
			case PBEncodeItemType_UInt64:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeUInt64NoTag(encodeItem->value.uint64Value);
				break;
			}
			case PBEncodeItemType_Float:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeFloatNoTag(encodeItem->value.floatValue);
				break;
			}
			case PBEncodeItemType_Double:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeDoubleNoTag(encodeItem->value.doubleValue);
				break;
			}
			case PBEncodeItemType_Fixed32:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeFixed32NoTag(encodeItem->value.int32Value);
				break;
			}
			case PBEncodeItemType_Fixed64:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeFixed64NoTag(encodeItem->value.int64Value);
				break;
			}
			case PBEncodeItemType_SFixed32:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeSFixed32NoTag(encodeItem->value.int32Value);
				break;
			}
			case PBEncodeItemType_SFixed64:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeSFixed64NoTag(encodeItem->value.int64Value);
				break;
			}
			case PBEncodeItemType_Point:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeFloatNoTag(encodeItem->value.pointValue.x);
				m_outputStream->writeFloatNoTag(encodeItem->value.pointValue.y);
				break;
			}
			case PBEncodeItemType_Size:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeFloatNoTag(encodeItem->value.sizeValue.width);
				m_outputStream->writeFloatNoTag(encodeItem->value.sizeValue.height);
				break;
			}
			case PBEncodeItemType_Rect:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeFloatNoTag(encodeItem->value.rectValue.origin.x);
				m_outputStream->writeFloatNoTag(encodeItem->value.rectValue.origin.y);
				m_outputStream->writeFloatNoTag(encodeItem->value.rectValue.size.width);
				m_outputStream->writeFloatNoTag(encodeItem->value.rectValue.size.height);
				break;
			}
			case PBEncodeItemType_NSString:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeRawVarint32(encodeItem->valueSize);
				if (encodeItem->valueSize > 0 && encodeItem->value.tmpObjectValue != NULL) {
					m_outputStream->writeRawData((__bridge NSData*)encodeItem->value.tmpObjectValue);
				}
				break;
			}
			case PBEncodeItemType_NSData:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeRawVarint32(encodeItem->valueSize);
				if (encodeItem->valueSize > 0 && encodeItem->value.objectValue != NULL) {
					m_outputStream->writeRawData((__bridge  NSData*)encodeItem->value.objectValue);
				}
				break;
			}
			case PBEncodeItemType_NSDate:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				NSDate* oDate = (__bridge NSDate*)encodeItem->value.objectValue;
				m_outputStream->writeDoubleNoTag(oDate.timeIntervalSince1970);
				break;
			}
			case PBEncodeItemType_NSNumber:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeRawVarint32(encodeItem->valueSize);
				if (encodeItem->valueSize > 0 && encodeItem->value.tmpObjectValue != NULL) {
					m_outputStream->writeStringNoTag((__bridge NSString*)encodeItem->value.tmpObjectValue, encodeItem->valueSize);
				}
				break;
			}
			case PBEncodeItemType_NSContainer:
			case PBEncodeItemType_Object:
			{
				if (encodeItem->hasTag) {
					m_outputStream->writeRawVarint32(encodeItem->compiledTag);
				}
				m_outputStream->writeRawVarint32(encodeItem->valueSize);
				break;
			}
			case PBEncodeItemType_NSContainer_UNPACKED:
			{
				// unpacked container doesn't need size
				break;
			}
			case PBEncodeItemType_None:
			{
				PBError(@"%d", encodeItem->type);
				break;
			}
		}
	}
}

// prepare size, value and tag
-(size_t) prepareCPropertyForEndcode:(PBCoderPropertyType*)oPropertyType withTarget:(id)obj {
	m_encodeItems->push_back(PBEncodeItem());
	size_t index = m_encodeItems->size() - 1;
	PBEncodeItem* encodeItem = &m_encodeItems->back();
	encodeItem->hasTag = true;
	encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatVarint);
	
	switch (oPropertyType.m_cType) {
		case PBCoderCType_Bool:
		{
			encodeItem->type = PBEncodeItemType_Bool;
			encodeItem->value.boolValue = blockGet<bool>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeBoolSize(oPropertyType.m_index, encodeItem->value.boolValue);
			return index;
		}
		case PBCoderCType_Enum:
		{
			encodeItem->type = PBEncodeItemType_Enum;
			encodeItem->value.int32Value = blockGet<int32_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeEnumSize(oPropertyType.m_index, encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_Int32:
		{
			encodeItem->type = PBEncodeItemType_Int32;
			encodeItem->value.int32Value = blockGet<int32_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeInt32Size(oPropertyType.m_index, encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_Int64:
		{
			encodeItem->type = PBEncodeItemType_Int64;
			encodeItem->value.int64Value = blockGet<int64_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeInt64Size(oPropertyType.m_index, encodeItem->value.int64Value);
			return index;
		}
		case PBCoderCType_UInt32:
		{
			encodeItem->type = PBEncodeItemType_UInt32;
			encodeItem->value.uint32Value = blockGet<uint32_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeUInt32Size(oPropertyType.m_index, encodeItem->value.uint32Value);
			return index;
		}
		case PBCoderCType_UInt64:
		{
			encodeItem->type = PBEncodeItemType_UInt64;
			encodeItem->value.uint64Value = blockGet<uint64_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeUInt64Size(oPropertyType.m_index, encodeItem->value.uint64Value);
			return index;
		}
		case PBCoderCType_Float:
		{
			encodeItem->type = PBEncodeItemType_Float;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed32);
			encodeItem->value.floatValue = blockGet<float>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeFloatSize(oPropertyType.m_index, encodeItem->value.floatValue);
			return index;
		}
		case PBCoderCType_Double:
		{
			encodeItem->type = PBEncodeItemType_Double;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed64);
			encodeItem->value.doubleValue = blockGet<double>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeDoubleSize(oPropertyType.m_index, encodeItem->value.doubleValue);
			return index;
		}
		case PBCoderCType_Point:
		{
			encodeItem->type = PBEncodeItemType_Point;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed64);
			encodeItem->value.pointValue = blockGet<CGPoint>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeTagSize(oPropertyType.m_index) + computeFloatSizeNoTag(encodeItem->value.pointValue.x) + computeFloatSizeNoTag(encodeItem->value.pointValue.y);
			return index;
		}
		case PBCoderCType_Size:
		{
			encodeItem->type = PBEncodeItemType_Size;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed64);
			encodeItem->value.sizeValue = blockGet<CGSize>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeTagSize(oPropertyType.m_index) + computeFloatSizeNoTag(encodeItem->value.sizeValue.width) + computeFloatSizeNoTag(encodeItem->value.sizeValue.height);
			return index;
		}
		case PBCoderCType_Rect:
		{
			encodeItem->type = PBEncodeItemType_Rect;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed64);
			encodeItem->value.rectValue = blockGet<CGRect>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeTagSize(oPropertyType.m_index) + computeFloatSizeNoTag(encodeItem->value.rectValue.origin.x) + computeFloatSizeNoTag(encodeItem->value.rectValue.origin.y) + computeFloatSizeNoTag(encodeItem->value.rectValue.size.width) + computeFloatSizeNoTag(encodeItem->value.rectValue.size.height);
			return index;
		}
		case PBCoderCType_Fixed32:
		{
			encodeItem->type = PBEncodeItemType_Fixed32;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed32);
			encodeItem->value.int32Value = blockGet<int32_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeFixed32Size(oPropertyType.m_index, encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_Fixed64:
		{
			encodeItem->type = PBEncodeItemType_Fixed64;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed64);
			encodeItem->value.int64Value = blockGet<int64_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeFixed64Size(oPropertyType.m_index, encodeItem->value.int64Value);
			return index;
		}
		case PBCoderCType_SFixed32:
		{
			encodeItem->type = PBEncodeItemType_SFixed32;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed32);
			encodeItem->value.int32Value = blockGet<int32_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeSFixed32Size(oPropertyType.m_index, encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_SFixed64:
		{
			encodeItem->type = PBEncodeItemType_SFixed64;
			encodeItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatFixed64);
			encodeItem->value.int64Value = blockGet<int64_t>(obj, oPropertyType.m_blockGet);
			encodeItem->compiledSize = computeSFixed64Size(oPropertyType.m_index, encodeItem->value.int64Value);
			return index;
		}
		case PBCoderCType_None:
		{
			m_encodeItems->pop_back();
			assert(0);
			break;
		}
	}
	return m_encodeItems->size();
}

-(size_t) prepareCValueForEndcode:(PBCoderPropertyCType)cType withValue:(NSNumber*)value withTag:(uint32_t)tag {
	m_encodeItems->push_back(PBEncodeItem());
	size_t index = m_encodeItems->size() - 1;
	PBEncodeItem* encodeItem = &m_encodeItems->back();
	if (tag == 0) {
		encodeItem->hasTag = false;
	} else {
		encodeItem->hasTag = true;
		encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatVarint);
	}
	
	switch (cType) {
		case PBCoderCType_Bool:
		{
			encodeItem->type = PBEncodeItemType_Bool;
			encodeItem->value.boolValue = value.boolValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeBoolSize(tag, encodeItem->value.boolValue): computeBoolSizeNoTag(encodeItem->value.boolValue);
			return index;
		}
		case PBCoderCType_Enum:
		{
			encodeItem->type = PBEncodeItemType_Enum;
			encodeItem->value.int32Value = value.intValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeEnumSize(tag, encodeItem->value.int32Value) : computeEnumSizeNoTag(encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_Int32:
		{
			encodeItem->type = PBEncodeItemType_Int32;
			encodeItem->value.int32Value = value.intValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeInt32Size(tag, encodeItem->value.int32Value) : computeInt32SizeNoTag(encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_Int64:
		{
			encodeItem->type = PBEncodeItemType_Int64;
			encodeItem->value.int64Value = value.longLongValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeInt64Size(tag, encodeItem->value.int64Value) : computeInt64SizeNoTag(encodeItem->value.int64Value);
			return index;
		}
		case PBCoderCType_UInt32:
		{
			encodeItem->type = PBEncodeItemType_UInt32;
			encodeItem->value.uint32Value = value.unsignedIntValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeUInt32Size(tag, encodeItem->value.uint32Value) : computeUInt32SizeNoTag(encodeItem->value.uint32Value);
			return index;
		}
		case PBCoderCType_UInt64:
		{
			encodeItem->type = PBEncodeItemType_UInt64;
			encodeItem->value.uint64Value = value.unsignedLongLongValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeUInt64Size(tag, encodeItem->value.uint64Value) : computeUInt64SizeNoTag(encodeItem->value.uint64Value);
			return index;
		}
		case PBCoderCType_Float:
		{
			encodeItem->type = PBEncodeItemType_Float;
			if (encodeItem->hasTag) {
				encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatFixed32);
			}
			encodeItem->value.floatValue = value.floatValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeFloatSize(tag, encodeItem->value.floatValue) : computeFloatSizeNoTag(encodeItem->value.floatValue);
			return index;
		}
		case PBCoderCType_Double:
		{
			encodeItem->type = PBEncodeItemType_Double;
			if (encodeItem->hasTag) {
				encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatFixed64);
			}
			encodeItem->value.doubleValue = value.doubleValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeDoubleSize(tag, encodeItem->value.doubleValue) : computeDoubleSizeNoTag(encodeItem->value.doubleValue);
			return index;
		}
		case PBCoderCType_Fixed32:
		{
			encodeItem->type = PBEncodeItemType_Fixed32;
			if (encodeItem->hasTag) {
				encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatFixed32);
			}
			encodeItem->value.int32Value = value.intValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeFixed32Size(tag, encodeItem->value.int32Value) : computeFixed32SizeNoTag(encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_Fixed64:
		{
			encodeItem->type = PBEncodeItemType_Fixed64;
			if (encodeItem->hasTag) {
				encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatFixed64);
			}
			encodeItem->value.int64Value = value.longLongValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeFixed64Size(tag, encodeItem->value.int64Value) : computeFixed64SizeNoTag(encodeItem->value.int64Value);
			return index;
		}
		case PBCoderCType_SFixed32:
		{
			encodeItem->type = PBEncodeItemType_SFixed32;
			if (encodeItem->hasTag) {
				encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatFixed32);
			}
			encodeItem->value.int32Value = value.intValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeSFixed32Size(tag, encodeItem->value.int32Value) : computeSFixed32SizeNoTag(encodeItem->value.int32Value);
			return index;
		}
		case PBCoderCType_SFixed64:
		{
			encodeItem->type = PBEncodeItemType_SFixed64;
			if (encodeItem->hasTag) {
				encodeItem->compiledTag = PBWireFormatMakeTag(tag, PBWireFormatFixed64);
			}
			encodeItem->value.int64Value = value.longLongValue;
			encodeItem->compiledSize = encodeItem->hasTag ? computeSFixed64Size(tag, encodeItem->value.int64Value) : computeSFixed64SizeNoTag(encodeItem->value.int64Value);
			return index;
		}
		case PBCoderCType_Point:
		case PBCoderCType_Size:
		case PBCoderCType_Rect:
		case PBCoderCType_None:
		{
			m_encodeItems->pop_back();
			assert(0);
			break;
		}
	}
	return m_encodeItems->size();
}

// prepare size and value, not tag
// a basic object's tag is to be juded by caller, so no tag by now
-(size_t) prepareBasicObjectForEncode:(id<PBCoding>)obj withPropertyType:(PBCoderPropertyType*)oPropertyType {
	m_encodeItems->push_back(PBEncodeItem());
	PBEncodeItem* encodeItem = &(m_encodeItems->back());
	size_t index = m_encodeItems->size() - 1;
    
	if ([obj isKindOfClass:[NSString class]])
	{
		NSString* str = (NSString*) obj;
		encodeItem->type = PBEncodeItemType_NSString;
		size_t maxSize = MAX(1, [str maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
		if (m_formatBufferSize < maxSize)
		{
			m_formatBufferSize = maxSize;
			if (m_formatBuffer)
			{
				free(m_formatBuffer);
			}
			m_formatBuffer = malloc(m_formatBufferSize);
		}
		NSUInteger realSize = 0;
		[str getBytes:m_formatBuffer maxLength:maxSize usedLength:&realSize encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, str.length) remainingRange:NULL];
		NSData* buffer = [NSData dataWithBytes:m_formatBuffer length:realSize];
		encodeItem->value.tmpObjectValue = (void*)CFBridgingRetain(buffer);
		encodeItem->valueSize = static_cast<int32_t>(buffer.length);
	}
	else if ([obj isKindOfClass:[NSDate class]])
	{
		NSDate* oDate = (NSDate*)obj;
		encodeItem->type = PBEncodeItemType_NSDate;
		encodeItem->value.objectValue = (__bridge void*)oDate;
		encodeItem->valueSize = computeDoubleSizeNoTag(oDate.timeIntervalSince1970);
		encodeItem->compiledSize = encodeItem->valueSize;
		return index;	// double has fixed compilesize
	}
	else if ([obj isKindOfClass:[NSNumber class]])
	{
		NSNumber* number = (NSNumber*) obj;
		encodeItem->type = PBEncodeItemType_NSNumber;
        encodeItem->value.tmpObjectValue = (void*)CFBridgingRetain(number.stringValue);
		encodeItem->valueSize = computeRawStringSize((__bridge NSString*)encodeItem->value.tmpObjectValue);
	}
	else if ([obj isKindOfClass:[NSData class]])
	{
		NSData* oData = (NSData*)obj;
		encodeItem->type = PBEncodeItemType_NSData;
		encodeItem->value.objectValue = (__bridge void*)oData;
		encodeItem->valueSize = static_cast<int32_t>(oData.length);
	}
	else if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]])
	{
		encodeItem->type = PBEncodeItemType_NSContainer;
		encodeItem->value.objectValue = NULL;
        
		for (id subObj in (NSArray*)obj) {
			size_t itemIndex = 0;
			if (oPropertyType.m_subCType != PBCoderCType_None) {
				// packed property has no tag
				itemIndex = [self prepareCValueForEndcode:oPropertyType.m_subCType withValue:subObj withTag:0];
			} else {
				itemIndex = [self prepareObjectForEncode:subObj withPropertyType:oPropertyType];
			}
			if (itemIndex < m_encodeItems->size()) {
				(*m_encodeItems)[index].valueSize += (*m_encodeItems)[itemIndex].compiledSize;
			}
		}
		encodeItem = &(*m_encodeItems)[index];
	}
	else if ([obj isKindOfClass:[NSDictionary class]])
	{
		encodeItem->type = PBEncodeItemType_NSContainer;
		encodeItem->value.objectValue = NULL;
		
		[(NSDictionary*)obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
			NSString* nsKey = (NSString*)key;	// assume key is NSString
			if (nsKey.length <= 0 || value == nil) {
				return;
			}
#ifdef DEBUG
			if (![nsKey isKindOfClass:NSString.class]) {
				PBError(@"NSDictionary has key[%@], only NSString is allowed!", NSStringFromClass(nsKey.class));
			}
#endif
            
			size_t keyIndex = [self prepareBasicObjectForEncode:key withPropertyType:nil];
			if (keyIndex < m_encodeItems->size())
			{
				size_t valueIndex = 0;
				if (oPropertyType.m_subCType != PBCoderCType_None) {
					// packed property has no tag
					valueIndex = [self prepareCValueForEndcode:oPropertyType.m_subCType withValue:value withTag:0];
				} else {
					valueIndex = [self prepareObjectForEncode:value withPropertyType:oPropertyType];
				}
				if (valueIndex < m_encodeItems->size()) {
					(*m_encodeItems)[index].valueSize += (*m_encodeItems)[keyIndex].compiledSize;
					(*m_encodeItems)[index].valueSize += (*m_encodeItems)[valueIndex].compiledSize;
				} else {
					m_encodeItems->pop_back();	// pop key
				}
			}
		}];
		
		encodeItem = &(*m_encodeItems)[index];
	}
	else
	{
		m_encodeItems->pop_back();
		PBError(@"%@ not recognized as container", NSStringFromClass(obj.class));
		return m_encodeItems->size();
	}
	encodeItem->compiledSize = computeRawVarint32Size(encodeItem->valueSize) + encodeItem->valueSize;
    
	return index;
}

-(size_t) prepareUnPackedContainerForEncode:(id<PBCoding>)obj withPropertyIndex:(int32_t)propertyIndex withSubCType:(PBCoderPropertyCType)cType
{
	m_encodeItems->push_back(PBEncodeItem());
	PBEncodeItem* encodeItem = &(m_encodeItems->back());
	size_t index = m_encodeItems->size() - 1;
	encodeItem->type = PBEncodeItemType_NSContainer_UNPACKED;
	encodeItem->value.objectValue = NULL;
	
	for (id subObj in (NSArray*)obj) {
		size_t itemIndex = 0;
		if (cType != PBCoderCType_None) {
			itemIndex = [self prepareCValueForEndcode:cType withValue:subObj withTag:propertyIndex];
		} else {
			itemIndex = [self prepareObjectForEncode:subObj withPropertyType:nil];
		}
		if (itemIndex < m_encodeItems->size()) {
			PBEncodeItem* subObjItem = &(*m_encodeItems)[itemIndex];
			if (cType != PBCoderCType_None) {
				// add to my size
				(*m_encodeItems)[index].valueSize += subObjItem->compiledSize;
			} else {
				subObjItem->hasTag = true;
				subObjItem->compiledTag = PBWireFormatMakeTag(propertyIndex, PBWireFormatLengthDelimited);
				
				// add to my size
				(*m_encodeItems)[index].valueSize += subObjItem->compiledSize + computeTagSize(propertyIndex);
			}
		}
	}
	
	encodeItem = &(*m_encodeItems)[index];
	encodeItem->compiledSize = encodeItem->valueSize;
	
	return index;
}

// prepare size and value, not tag
// an object's tag is to be juded by caller, so no tag by now
-(size_t) preparePBObjectForEncode:(id)obj withPropertyTable:(NSArray*)arrProperty {
	m_encodeItems->push_back(PBEncodeItem());
	PBEncodeItem* encodeItem = &(m_encodeItems->back());
	encodeItem->type = PBEncodeItemType_Object;
	size_t cur_index = m_encodeItems->size() - 1;	// encodeItem may be invalid
	
	if (arrProperty.count <= 0) {
		return cur_index;
	}
	for (size_t index = 0, total = arrProperty.count; index < total; index++) {
		PBCoderPropertyType* oPropertyType = [arrProperty objectAtIndex:index];
		if (oPropertyType.m_cType == PBCoderCType_None) {
			// encode super
			if (oPropertyType.m_isSuperPlaceHolder) {
				IMP imp = class_getMethodImplementation(oPropertyType.m_cls, @selector(getValueTypeTable));
				NSArray* arrSuperProperty = ((id(*)(id, SEL))imp)(obj, @selector(getValueTypeTable));
				size_t itemIndex = [self preparePBObjectForEncode:obj withPropertyTable:arrSuperProperty];
				if (itemIndex < m_encodeItems->size()) {
					// a super has a tag
					PBEncodeItem* oItem = &(*m_encodeItems)[itemIndex];
					oItem->hasTag = true;
					oItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatLengthDelimited);
					
					// add super size to my size
					(*m_encodeItems)[cur_index].valueSize += oItem->compiledSize + computeTagSize(oPropertyType.m_index);
				}
			} else {
				id oPropObj = [obj performSelector:oPropertyType.m_getter];
				if (oPropObj) {
					// encode unpacked property (repeated field without packed=true)
					if (oPropertyType.m_isContainerUnpacked &&
						([oPropObj isKindOfClass:NSArray.class] || [oPropObj isKindOfClass:NSSet.class])) {
						size_t itemIndex = [self prepareUnPackedContainerForEncode:oPropObj withPropertyIndex:oPropertyType.m_index withSubCType:oPropertyType.m_subCType];
						if (itemIndex < m_encodeItems->size()) {
							// a unpacked container itself doesn't have a tag
							PBEncodeItem* oItem = &(*m_encodeItems)[itemIndex];
							oItem->hasTag = false;
							
							// add unpacked container size to my size
							(*m_encodeItems)[cur_index].valueSize += oItem->compiledSize;
						}
					} else {
						size_t itemIndex = [self prepareObjectForEncode:oPropObj withPropertyType:oPropertyType];
						if (itemIndex < m_encodeItems->size()) {
							// a property has a tag
							PBEncodeItem* oItem = &(*m_encodeItems)[itemIndex];
							oItem->hasTag = true;
							oItem->compiledTag = PBWireFormatMakeTag(oPropertyType.m_index, PBWireFormatLengthDelimited);
							
							// add property size to my size
							(*m_encodeItems)[cur_index].valueSize += oItem->compiledSize + computeTagSize(oPropertyType.m_index);
						}
					}
				}
			}
		} else {
			// a property has a tag
			size_t itemIndex = [self prepareCPropertyForEndcode:oPropertyType withTarget:obj];
			if (itemIndex < m_encodeItems->size()) {
				// add property size to my size, note: tag size already compiled
				(*m_encodeItems)[cur_index].valueSize += (*m_encodeItems)[itemIndex].compiledSize;
			}
		}
	}
	encodeItem = &(*m_encodeItems)[cur_index];
	encodeItem->compiledSize = computeRawVarint32Size(encodeItem->valueSize) + encodeItem->valueSize;
    
	return cur_index;
}

// prepare size and value, not tag
// an object's tag is to be juded by caller, so no tag by now
-(size_t) prepareObjectForEncode:(id)obj withPropertyType:(PBCoderPropertyType*)oPropertyType {
	if (!obj) {
		return m_encodeItems->size();
	}
	
	if ([obj respondsToSelector:@selector(getValueTypeTable)]) {
		NSArray* arrProperty = [obj getValueTypeTable];
		size_t index = [self preparePBObjectForEncode:obj withPropertyTable:arrProperty];
		return index;
	} else {
		// a basic object's tag is to be juded by caller, so no tag by now
		return [self prepareBasicObjectForEncode:obj withPropertyType:oPropertyType];
	}
    
	return m_encodeItems->size();
}

-(NSData*) getEncodeDataWithForceWriteSize:(bool)forceWriteSize {
	if (m_outputData != nil) {
		return m_outputData;
	}
    
	m_encodeItems = new std::vector<PBEncodeItem>();
	size_t index = [self prepareObjectForEncode:m_obj withPropertyType:nil];
	PBEncodeItem* oItem = (index < m_encodeItems->size()) ? &(*m_encodeItems)[index] : NULL;
	if (oItem && oItem->compiledSize > 0) {
		if (!forceWriteSize && (oItem->type == PBEncodeItemType_Object)) {
            m_outputData = [NSMutableData dataWithLength:oItem->valueSize];
		} else {
			// non-protobuf object(NSString/NSArray, etc) need to to write SIZE as well as DATA,
			// so compiledSize is used,
            m_outputData = [NSMutableData dataWithLength:oItem->compiledSize];
		}
		m_outputStream = new CodedOutputData(m_outputData);

		// force write value size, for append mode
		if (forceWriteSize && (oItem->type == PBEncodeItemType_Object)) {
			m_outputStream->writeRawVarint32(oItem->valueSize);
		}
		[self writeRootObject];
		
		return m_outputData;
	}
    
	return nil;
}

-(NSData*) getEncodeDataWithPropertyTable:(NSArray*)arrProperty  {
	if (m_outputData != nil) {
		return m_outputData;
	}
	
	m_encodeItems = new std::vector<PBEncodeItem>();
	size_t index = [self preparePBObjectForEncode:m_obj withPropertyTable:arrProperty];
	PBEncodeItem* oItem = (index < m_encodeItems->size()) ? &(*m_encodeItems)[index] : NULL;
	if (oItem && oItem->compiledSize > 0) {
		if (oItem->type == PBEncodeItemType_Object) {
			m_outputData = [NSMutableData dataWithLength:oItem->valueSize];
		} else {
			m_outputData = [NSMutableData dataWithLength:oItem->compiledSize];
		}
		m_outputStream = new CodedOutputData(m_outputData);
		
		[self writeRootObject];
		
		return m_outputData;
	}
	
	return nil;
}

+(NSData*) encodeDataWithObject:(id/*<PBCoding>*/)obj {
	if (obj) {
		@try {
			PBCoder* oCoder = [[PBCoder alloc] initForWritingWithTarget:obj];
            NSData* oData = [oCoder getEncodeDataWithForceWriteSize:false];
			
			return oData;
        } @catch(NSException *exception) {
			PBError(@"%@", exception);
			return nil;
		}
	}
	return nil;
}

+(NSData*) encodeDataWithSizeForObject:(id/*<PBCoding>*/)obj{
	if (obj) {
		@try {
			PBCoder* oCoder = [[PBCoder alloc] initForWritingWithTarget:obj];
            NSData* oData = [oCoder getEncodeDataWithForceWriteSize:true];
			
			return oData;
		} @catch(NSException *exception) {
			PBError(@"%@", exception);
			return nil;
		}
	}
	return nil;
}

+(bool) encodeObject:(id/*<PBCoding>*/)obj toFile:(NSString*)nsPath {
	if (!obj || nsPath.length <= 0) {
		return NO;
	}
    
	@try {
		NSData* oData = [PBCoder encodeDataWithObject:obj];
		if (oData) {
			return [oData writeToFile:nsPath atomically:YES];
		}
	} @catch(NSException *exception) {
		PBError(@"%@", exception);
		return false;
	}
	return false;
}


#pragma mark - decode

-(id/*<PBCoding>*/) decodeOneValueOfCType:(PBCoderPropertyCType)cType {
	NSNumber* result = nil;
	switch (cType) {
		case PBCoderCType_Bool:
		{
			result = [NSNumber numberWithBool:m_inputStream->readBool()];
			break;
		}
		case PBCoderCType_Enum:
		{
			result = [NSNumber numberWithInt:m_inputStream->readEnum()];
			break;
		}
		case PBCoderCType_Int32:
		{
			result = [NSNumber numberWithInt:m_inputStream->readInt32()];
			break;
		}
		case PBCoderCType_Int64:
		{
			result = [NSNumber numberWithLongLong:m_inputStream->readInt64()];
			break;
		}
		case PBCoderCType_UInt32:
		{
			result = [NSNumber numberWithUnsignedInt:m_inputStream->readUInt32()];
			break;
		}
		case PBCoderCType_UInt64:
		{
			result = [NSNumber numberWithUnsignedLongLong:m_inputStream->readUInt64()];
			break;
		}
		case PBCoderCType_Float:
		{
			result = [NSNumber numberWithFloat:m_inputStream->readFloat()];
			break;
		}
		case PBCoderCType_Double:
		{
			result = [NSNumber numberWithDouble:m_inputStream->readDouble()];
			break;
		}
		case PBCoderCType_Fixed32:
		{
			result = [NSNumber numberWithInt:m_inputStream->readFixed32()];
			break;
		}
		case PBCoderCType_Fixed64:
		{
			result = [NSNumber numberWithLongLong:m_inputStream->readFixed64()];
			break;
		}
		case PBCoderCType_SFixed32:
		{
			result = [NSNumber numberWithInt:m_inputStream->readSFixed32()];
			break;
		}
		case PBCoderCType_SFixed64:
		{
			result = [NSNumber numberWithLongLong:m_inputStream->readSFixed64()];
			break;
		}
		case PBCoderCType_Point:
		case PBCoderCType_Size:
		case PBCoderCType_Rect:
		case PBCoderCType_None:
			PBError(@"not supported");
			break;
	}
	return result;
}

-(NSMutableArray*) decodeOneArrayOfValueClass:(Class)cls orValueCType:(PBCoderPropertyCType)cType ignoreSize:(bool)ignoreSize{
	m_isTopObject = NO;
	if (cls == NULL && cType == PBCoderCType_None) {
		return nil;
	}
	
	NSMutableArray* arr = [NSMutableArray array];
    
	int32_t length = m_inputStream->readRawVarint32();
	int32_t	limit = 0;
	if (ignoreSize) {
		limit = m_inputStream->pushLimit(static_cast<int32_t>(m_inputData.length) - computeRawVarint32Size(length));
	} else {
		limit = m_inputStream->pushLimit(length);
	}
    
	while ((ignoreSize && !m_inputStream->isAtEnd()) ||
		   (!ignoreSize && m_inputStream->bytesUntilLimit() > 0))
	{
		id value = nil;
		if (cType != PBCoderCType_None) {
			value = [self decodeOneValueOfCType:cType];
		} else {
			value = [self decodeOneObject:nil ofClass:cls];
		}
		if (value) {
			[arr addObject:value];
		}
	}
    
	m_inputStream->popLimit(limit);
	
	return arr;
}

-(NSMutableSet*) decodeOneSetOfValueClass:(Class)cls orValueCType:(PBCoderPropertyCType)cType ignoreSize:(bool)ignoreSize {
	m_isTopObject = NO;
	if (cls == NULL && cType == PBCoderCType_None) {
		return nil;
	}
	
	NSMutableSet* set = [NSMutableSet set];
	
	int32_t length = m_inputStream->readRawVarint32();
	int32_t	limit = 0;
	if (ignoreSize) {
		limit = m_inputStream->pushLimit(static_cast<int32_t>(m_inputData.length) - computeRawVarint32Size(length));
	} else {
		limit = m_inputStream->pushLimit(length);
	}
	
	while ((ignoreSize && !m_inputStream->isAtEnd()) ||
		   (!ignoreSize && m_inputStream->bytesUntilLimit() > 0))
	{
		id value = nil;
		if (cType != PBCoderCType_None) {
			value = [self decodeOneValueOfCType:cType];
		} else {
			value = [self decodeOneObject:nil ofClass:cls];
		}
		if (value) {
			[set addObject:value];
		}
	}
	m_inputStream->popLimit(limit);
	
	return set;
}

-(NSMutableDictionary*) decodeOneDictionaryOfValueClass:(Class)cls orValueCType:(PBCoderPropertyCType)cType ignoreSize:(bool)ignoreSize {
	m_isTopObject = NO;
	if (cls == NULL && cType == PBCoderCType_None) {
		return nil;
	}
	
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	
	int32_t length = m_inputStream->readRawVarint32();
	int32_t	limit = 0;
	if (ignoreSize) {
		limit = m_inputStream->pushLimit(static_cast<int32_t>(m_inputData.length) - computeRawVarint32Size(length));
	} else {
		limit = m_inputStream->pushLimit(length);
	}
	
	while ((ignoreSize && !m_inputStream->isAtEnd()) ||
		   (!ignoreSize && m_inputStream->bytesUntilLimit() > 0))
	{
		NSString* nsKey = m_inputStream->readString();
		if (nsKey) {
			id value = nil;
			if (cType != PBCoderCType_None) {
				value = [self decodeOneValueOfCType:cType];
			} else {
				value = [self decodeOneObject:nil ofClass:cls];
			}
			[dic setObject:value forKey:nsKey];
		}
	}
	m_inputStream->popLimit(limit);
	
	return dic;
}

-(void) decodeOne_C_Property:(PBCoderPropertyType*)oPropertyType ofObject:(id)obj {
	switch (oPropertyType.m_cType) {
		case PBCoderCType_Bool:
		{
			blockSet<bool>(obj, oPropertyType.m_blockSet, m_inputStream->readBool());
			break;
		}
		case PBCoderCType_Enum:
		{
			blockSet<int32_t>(obj, oPropertyType.m_blockSet, m_inputStream->readEnum());
			break;
		}
		case PBCoderCType_Int32:
		{
			blockSet<int32_t>(obj, oPropertyType.m_blockSet, m_inputStream->readInt32());
			break;
		}
		case PBCoderCType_Int64:
		{
			blockSet<int64_t>(obj, oPropertyType.m_blockSet, m_inputStream->readInt64());
			break;
		}
		case PBCoderCType_UInt32:
		{
			blockSet<uint32_t>(obj, oPropertyType.m_blockSet, m_inputStream->readUInt32());
			break;
		}
		case PBCoderCType_UInt64:
		{
			blockSet<uint64_t>(obj, oPropertyType.m_blockSet, m_inputStream->readUInt64());
			break;
		}
		case PBCoderCType_Float:
		{
			blockSet<float>(obj, oPropertyType.m_blockSet, m_inputStream->readFloat());
			break;
		}
		case PBCoderCType_Double:
		{
			blockSet<double>(obj, oPropertyType.m_blockSet, m_inputStream->readDouble());
			break;
		}
		case PBCoderCType_Point:
		{
			CGPoint point;
			point.x = m_inputStream->readFloat();
			point.y = m_inputStream->readFloat();
			blockSet<CGPoint>(obj, oPropertyType.m_blockSet, point);
			break;
		}
		case PBCoderCType_Size:
		{
			CGSize size;
			size.width = m_inputStream->readFloat();
			size.height = m_inputStream->readFloat();
			blockSet<CGSize>(obj, oPropertyType.m_blockSet, size);
			break;
		}
		case PBCoderCType_Rect:
		{
			CGRect rect;
			rect.origin.x = m_inputStream->readFloat();
			rect.origin.y = m_inputStream->readFloat();
			rect.size.width = m_inputStream->readFloat();
			rect.size.height = m_inputStream->readFloat();
			blockSet<CGRect>(obj, oPropertyType.m_blockSet, rect);
			break;
		}
		case PBCoderCType_Fixed32:
		{
			blockSet<int32_t>(obj, oPropertyType.m_blockSet, m_inputStream->readFixed32());
			break;
		}
		case PBCoderCType_Fixed64:
		{
			blockSet<int64_t>(obj, oPropertyType.m_blockSet, m_inputStream->readFixed64());
			break;
		}
		case PBCoderCType_SFixed32:
		{
			blockSet<int32_t>(obj, oPropertyType.m_blockSet, m_inputStream->readSFixed32());
			break;
		}
		case PBCoderCType_SFixed64:
		{
			blockSet<int64_t>(obj, oPropertyType.m_blockSet, m_inputStream->readSFixed64());
			break;
		}
		case PBCoderCType_None:
		{
			PBError(@"never happen");
			break;
		}
	}
}

-(void) decodeOneProperty:(PBCoderPropertyType*)oPropertyType ofObject:(id)target {
	// objc objects
	if (oPropertyType.m_cType == PBCoderCType_None)
	{
		if (oPropertyType.m_cls == [NSString class])
		{
			[target performSelector:oPropertyType.m_setter withObject:m_inputStream->readString()];
		}
		else if (oPropertyType.m_cls == [NSMutableString class])
		{
			[target performSelector:oPropertyType.m_setter withObject:[NSMutableString stringWithString:m_inputStream->readString()]];
		}
		else if (oPropertyType.m_cls == [NSDate class])
		{
			[target performSelector:oPropertyType.m_setter withObject:[NSDate dateWithTimeIntervalSince1970:m_inputStream->readDouble()]];
		}
		else if (oPropertyType.m_cls == [NSNumber class])
		{
			if (m_numberFormatter == nil) {
				m_numberFormatter = [[NSNumberFormatter alloc] init];
			}
			[target performSelector:oPropertyType.m_setter withObject:[m_numberFormatter numberFromString:m_inputStream->readString()]];
		}
		else if (oPropertyType.m_cls == [NSData class])
		{
			[target performSelector:oPropertyType.m_setter withObject:m_inputStream->readData()];
		}
		else if (oPropertyType.m_cls == [NSMutableData class])
		{
			[target performSelector:oPropertyType.m_setter withObject:[NSMutableData dataWithData:m_inputStream->readData()]];
		}
		else if (oPropertyType.m_cls == [NSArray class] || oPropertyType.m_cls == [NSMutableArray class])
		{
			if (oPropertyType.m_isContainerUnpacked) {
				id value = nil;
				if (oPropertyType.m_subCType != PBCoderCType_None) {
					value = [self decodeOneValueOfCType:oPropertyType.m_subCType];
				} else {
					value = [self decodeOneObject:nil ofClass:oPropertyType.m_subCls];
				}
				if (value != nil) {
					NSMutableArray* arr = [target performSelector:oPropertyType.m_getter];
					if (arr == nil) {
						arr = [NSMutableArray array];
						[target performSelector:oPropertyType.m_setter withObject:arr];
					}
					[arr addObject:value];
				}
			} else {
				NSArray* arr = [self decodeOneArrayOfValueClass:oPropertyType.m_subCls orValueCType:oPropertyType.m_subCType ignoreSize:false];
				[target performSelector:oPropertyType.m_setter withObject:arr];
			}
		}
		else if (oPropertyType.m_cls == [NSSet class] || oPropertyType.m_cls == [NSMutableSet class])
		{
			if (oPropertyType.m_isContainerUnpacked) {
				id value = nil;
				if (oPropertyType.m_subCType != PBCoderCType_None) {
					value = [self decodeOneValueOfCType:oPropertyType.m_subCType];
				} else {
					value = [self decodeOneObject:nil ofClass:oPropertyType.m_subCls];
				}
				if (value != nil) {
					NSMutableSet* oSet = [target performSelector:oPropertyType.m_getter];
					if (oSet == nil) {
						oSet = [NSMutableSet set];
						[target performSelector:oPropertyType.m_setter withObject:oSet];
					}
					[oSet addObject:value];
				}
			} else {
				NSSet* oSet = [self decodeOneSetOfValueClass:oPropertyType.m_subCls orValueCType:oPropertyType.m_subCType ignoreSize:false];
				[target performSelector:oPropertyType.m_setter withObject:oSet];
			}
		}
		else if (oPropertyType.m_cls == [NSDictionary class] || oPropertyType.m_cls == [NSMutableDictionary class])
		{
			NSDictionary* dic = [self decodeOneDictionaryOfValueClass:oPropertyType.m_subCls orValueCType:oPropertyType.m_subCType ignoreSize:false];
			[target performSelector:oPropertyType.m_setter withObject:dic];
		}
		else
		{
			[target performSelector:oPropertyType.m_setter withObject:[self decodeOneObject:nil ofClass:oPropertyType.m_cls]];
		}
	} else {
		[self decodeOne_C_Property:oPropertyType ofObject:target];
	}
}

-(void) decodeObject:(id)obj withProperty:(NSArray*)arrPropertyTypeWrap andTagIndexMap:(const std::map<size_t, size_t>*)mapTagToIndex
{
	if (arrPropertyTypeWrap.count > 0 && mapTagToIndex != NULL)
	{
		for (int32_t tag = m_inputStream->readTag(); tag != 0; tag = m_inputStream->readTag())
		{
			int32_t field = PBWireFormatGetTagFieldNumber(tag);
			std::map<size_t, size_t>::const_iterator itr = mapTagToIndex->find(field);
			if (itr != mapTagToIndex->end())
			{
				PBCoderPropertyType* oPropertyType = [arrPropertyTypeWrap objectAtIndex:itr->second];
                
				// decode super
				if (oPropertyType.m_isSuperPlaceHolder) {
					int32_t length = m_inputStream->readRawVarint32();
					int32_t oldLimit = m_inputStream->pushLimit(length);
					
					IMP imp = class_getMethodImplementation(oPropertyType.m_cls, @selector(getValueTypeTable));
					NSArray* arrSuperPropertyTypeWrap = ((id(*)(id, SEL))imp)(obj, @selector(getValueTypeTable));
					
					imp = class_getMethodImplementation(oPropertyType.m_cls, @selector(getValueTagIndexMap));
					const std::map<size_t, size_t>* mapSuperTagToIndex = ((const std::map<size_t, size_t>*(*)(id, SEL))imp)(obj, @selector(getValueTagIndexMap));
					[self decodeObject:obj withProperty:arrSuperPropertyTypeWrap andTagIndexMap:mapSuperTagToIndex];
                    
					m_inputStream->checkLastTagWas(0);
					m_inputStream->popLimit(oldLimit);
				} else {
					[self decodeOneProperty:oPropertyType ofObject:obj];
				}
			}
			else
			{
				NSObject* tmp = (NSObject*)obj;
				PBWarning(@"skip field:%d on class:%@", field, NSStringFromClass(tmp.class));
				m_inputStream->skipField(tag);
			}
		}
	}
}

-(id/*<PBCoding>*/) decodeOneObject:(id)obj ofClass:(Class)cls {
	if (!cls && !obj) {
		return nil;
	}
	if (!cls) {
		cls = [(NSObject*)obj class];
	}
    
	if (class_respondsToSelector(cls, @selector(getValueTypeTable))) {
		id<PBCoding> pbObj = nil;
		if (obj) {
			pbObj = (id<PBCoding>)obj;
		} else {
            pbObj = [[cls alloc] init];
		}
		
		// a root object has no tag or size
		BOOL isTopObject = NO;
		int32_t length = 0, oldLimit = 0;
		if (m_isTopObject) {
			m_isTopObject = NO;
			isTopObject = YES;
		} else {
			length = m_inputStream->readRawVarint32();
			oldLimit = m_inputStream->pushLimit(length);
		}
        
		NSArray* arrPropertyTypeWrap = [pbObj getValueTypeTable];
		const std::map<size_t, size_t>* mapTagToIndex = [pbObj getValueTagIndexMap];
		[self decodeObject:pbObj withProperty:arrPropertyTypeWrap andTagIndexMap:mapTagToIndex];
		
		m_inputStream->checkLastTagWas(0);
        
		if (isTopObject == NO) {
			m_inputStream->popLimit(oldLimit);
		}
        
		return pbObj;
	} else {
		m_isTopObject = NO;
        
		if (cls == [NSString class]) {
			return m_inputStream->readString();
		} else if (cls == [NSMutableString class]) {
			return [NSMutableString stringWithString:m_inputStream->readString()];
		} else if (cls == [NSData class]) {
			return m_inputStream->readData();
		} else if (cls == [NSMutableData class]) {
			return [NSMutableData dataWithData:m_inputStream->readData()];
		} else if (cls == [NSDate class]) {
			return [NSDate dateWithTimeIntervalSince1970:m_inputStream->readDouble()];
		} else if (cls == [NSNumber class]) {
			if (m_numberFormatter == nil) {
				m_numberFormatter = [[NSNumberFormatter alloc] init];
			}
			return [m_numberFormatter numberFromString:m_inputStream->readString()];
		} else {
			PBError(@"%@ does not respond -[getValueTypeTable] and no basic type, can't handle", NSStringFromClass(cls));
		}
	}
	
	return nil;
}

-(id/*<PBCoding>*/) decodeOneObject:(id)obj withProperty:(NSArray*)arrPropertyTypeWrap andTagIndexMap:(const std::map<size_t, size_t>*)mapTagToIndex
{
	if (!obj) {
		return nil;
	}
	id<PBCoding> pbObj = (id<PBCoding>)obj;
	
	// a root object has no tag or size
	if (m_isTopObject) {
		m_isTopObject = NO;
	}
	
	[self decodeObject:pbObj withProperty:arrPropertyTypeWrap andTagIndexMap:mapTagToIndex];
	
	m_inputStream->checkLastTagWas(0);
	
	return pbObj;
}

+(id/*<PBCoding>*/)	decodeObjectOfClass:(Class)cls fromFile:(NSString*)nsPath {
	if (nsPath.length <= 0) {
		return nil;
	}
    
	NSData* oData = [NSData dataWithContentsOfFile:nsPath];
	if (oData) {
		return [PBCoder decodeObjectOfClass:cls fromData:oData];
	}
	return nil;
}

+(id/*<PBCoding>*/)	decodeObjectOfClass:(Class)cls fromData:(NSData*)oData {
	if (!cls || oData.length <= 0) {
		return nil;
	}
    
	id obj = nil;
	@try {
		PBCoder* oCoder = [[PBCoder alloc] initForReadingWithData:oData];
		obj = [oCoder decodeOneObject:nil ofClass:cls];
	} @catch(NSException *exception) {
		PBError(@"%@", exception);
	}
	return obj;
}

+(bool) decodeObject:(id)obj fromFile:(NSString*)nsPath {
	if (!obj) {
		return false;
	}
	NSData* oData = [NSData dataWithContentsOfFile:nsPath];
	if (oData) {
		return [PBCoder decodeObject:obj fromData:oData];
	}
	return false;
}

+(bool) decodeObject:(id)obj fromData:(NSData*)oData {
	if (!obj || oData.length <= 0) {
		return false;
	}
	@try {
		PBCoder* oCoder = [[PBCoder alloc] initForReadingWithData:oData];
		[oCoder decodeOneObject:obj ofClass:getClassOfClusterInstance(obj)];
		return true;
	} @catch(NSException *exception) {
		PBError(@"%@", exception);
	}
	return false;
}

+(id/*<PBCoding>*/)	decodeContainerOfClass:(Class)cls withValueClass:(Class)valueClass fromFile:(NSString*)nsPath {
	NSData* oData = [NSData dataWithContentsOfFile:nsPath];
	if (oData) {
		return [PBCoder decodeContainerOfClass:cls withValueClass:valueClass fromData:oData];
	}
	return nil;
}

+(id/*<PBCoding>*/)	decodeContainerOfClass:(Class)cls withValueClass:(Class)valueClass fromData:(NSData*)oData {
	if (!cls || !valueClass || oData.length <= 0) {
		return nil;
	}
    
	id obj = nil;
	@try {
		PBCoder* oCoder = [[PBCoder alloc] initForReadingWithData:oData];
		if (cls == [NSArray class] || cls == [NSMutableArray class]) {
			obj = [oCoder decodeOneArrayOfValueClass:valueClass orValueCType:PBCoderCType_None ignoreSize:true];
		} else if (cls == [NSSet class] || cls == [NSMutableSet class]) {
			obj = [oCoder decodeOneSetOfValueClass:valueClass orValueCType:PBCoderCType_None ignoreSize:true];
		} else if (cls == [NSDictionary class] || cls == [NSMutableDictionary class]) {
			obj = [oCoder decodeOneDictionaryOfValueClass:valueClass orValueCType:PBCoderCType_None ignoreSize:true];
		} else {
			PBError(@"%@ not recognized as container", NSStringFromClass(cls));
		}
	} @catch(NSException *exception) {
		PBError(@"%@", exception);
	}
	return obj;
	
}

+(bool) appendData:(NSData*)oData toPath:(NSString*)nsPath {
	ssize_t bytesWrited = 0;
	int fd = open(nsPath.UTF8String, O_WRONLY | O_CREAT | O_APPEND | O_SYNC, S_IRWXU);
	if (fd > 0) {
		bytesWrited = write(fd, oData.bytes, oData.length);
	}
	close(fd);
	
	return fd > 0 && bytesWrited == oData.length;
}

+ (long long) getFiLeSize:(NSString *) path
{
    struct stat temp;
    if(lstat(path.UTF8String, &temp)==0)
    {
        return temp.st_size;
    }
    return -1;
}

+(bool) appendOneArrayValue:(id)obj toFile:(NSString*)nsPath {
	if (obj == nil || nsPath.length <= 0) {
		return false;
	}
	if ([PBCoder getFiLeSize:nsPath] <= 0) {
		return [PBCoder encodeObject:[NSArray arrayWithObject:obj] toFile:nsPath];
	} else {
		NSData* oData = [PBCoder encodeDataWithSizeForObject:obj];
		if (oData.length <= 0) {
			return false;
		}
		return [PBCoder appendData:oData toPath:nsPath];
	}
}

+(bool) appendOneSetValue:(id)obj toFile:(NSString*)nsPath {
	return [PBCoder appendOneArrayValue:obj toFile:nsPath];
}

+(bool) appendOneDictionaryValue:(id)obj forKey:(NSString*)nsKey toFile:(NSString*)nsPath {
	if (obj == nil || nsPath.length <= 0 || nsKey.length <= 0) {
		return false;
	}
	return [PBCoder appendOneArrayValue:nsKey toFile:nsPath] && [PBCoder appendOneArrayValue:obj toFile:nsPath];
}

+(bool) appendArray:(NSArray*)oArray toFile:(NSString*)nsPath {
	if (oArray.count <= 0 || nsPath.length <= 0) {
		return false;
	}
	NSData* oData = [PBCoder encodeDataWithObject:oArray];
    
	if ([PBCoder getFiLeSize:nsPath] <= 0) {
		return [oData writeToFile:nsPath atomically:YES];
	} else {
		// don't write size of the Array
		CodedInputData input(oData);
		int32_t valueSize = input.readRawVarint32();
		int32_t sizeOfValueSize = computeRawVarint32Size(valueSize);
		if (oData.length == valueSize + sizeOfValueSize) {
			int8_t* bytes = (int8_t*)[oData bytes];
			NSData* oValueData = [NSData dataWithBytesNoCopy:bytes+sizeOfValueSize length:valueSize freeWhenDone:NO];
			
			return [PBCoder appendData:oValueData toPath:nsPath];
		}
	}
	
	return false;
}

+(bool) appendSet:(NSSet*)oSet toFile:(NSString*)nsPath {
	if (oSet.count <= 0| nsPath.length <= 0) {
		return false;
	}
	return [PBCoder appendArray:(NSArray*)oSet toFile:nsPath];
}

+(bool) appendDictionary:(NSDictionary*)oDictionary toFile:(NSString*)nsPath {
	if (oDictionary.count <= 0 || nsPath.length <= 0) {
		return false;
	}
	return [PBCoder appendArray:(NSArray*)oDictionary toFile:nsPath];
}

+(bool) appendOneArrayValue:(id)obj toData:(NSMutableData*)oData {
	if (obj == nil || oData == nil) {
		return false;
	}

	NSData* oNewData = nil;
	if (oData.length <= 0) {
		oNewData = [PBCoder encodeDataWithObject:[NSArray arrayWithObject:obj]];
	} else {
		oNewData = [PBCoder encodeDataWithSizeForObject:obj];
	}
	if (oNewData) {
		[oData appendData:oNewData];
		return true;
	}
	return false;
}

+(bool) appendOneSetValue:(id)obj toData:(NSMutableData*)oData {
	return [PBCoder appendOneArrayValue:obj toData:oData];
}

+(bool) appendOneDictionaryValue:(id)obj forKey:(NSString*)nsKey toData:(NSMutableData*)oData {
	if (obj == nil || nsKey.length <= 0 || oData == nil) {
		return false;
	}
	return [PBCoder appendOneArrayValue:nsKey toData:oData] && [PBCoder appendOneArrayValue:obj toData:oData];
}

+(bool) appendArray:(NSArray*)oArray toData:(NSMutableData*)oOut {
	if (oArray.count <= 0 || oOut == nil) {
		return false;
	}
	NSData* oData = [PBCoder encodeDataWithObject:oArray];
    
	if (oData.length <= 0) {
		[oOut appendData:oData];
		return true;
	} else {
		// don't write size of the Array
		CodedInputData input(oData);
		int32_t valueSize = input.readRawVarint32();
		int32_t sizeOfValueSize = computeRawVarint32Size(valueSize);
		if (oData.length == valueSize + sizeOfValueSize) {
			int8_t* bytes = (int8_t*)[oData bytes];
			[oOut appendBytes:bytes+sizeOfValueSize length:valueSize];
			return true;
		}
	}
	
	return false;
}

+(bool) appendSet:(NSSet*)oSet toData:(NSMutableData*)oData {
	if (oSet.count <= 0 || oData == nil) {
		return false;
	}
	return [PBCoder appendArray:(NSArray*)oSet toData:oData];
}

+(bool) appendDictionary:(NSDictionary*)oDictionary toData:(NSMutableData*)oData {
	if (oDictionary.count <= 0 || oData == nil) {
		return false;
	}
	return [PBCoder appendArray:(NSArray*)oDictionary toData:oData];
}

@end


// encode/decode using alternative property table

@implementation PBCoder (PropertyTable)

+(NSData*) encodeObject:(id)obj withPropertyTable:(NSArray*)arrProperty {
	if (obj && arrProperty.count > 0) {
        NSData* oData = nil;
        PBCoder* oCoder = nil;
		@try {
			oCoder = [[PBCoder alloc] initForWritingWithTarget:obj];
			oData = [oCoder getEncodeDataWithPropertyTable:arrProperty];
		} @catch(NSException *exception) {
			PBError(@"%@", exception);
            oData = nil;
		}
        oCoder = nil;
        
        return oData;
	}
	return nil;
}

+(bool) encodeObject:(id/*<PBCoding>*/)obj withPropertyTable:(NSArray*)arrProperty toFile:(NSString*)nsPath {
	if (!obj || nsPath.length <= 0 || arrProperty.count <= 0) {
		return NO;
	}
	
	@try {
		NSData* oData = [PBCoder encodeObject:obj withPropertyTable:arrProperty];
		if (oData) {
            return [oData writeToFile:nsPath atomically:YES];
		}
	} @catch(NSException *exception) {
		PBError(@"%@", exception);
		return false;
	}
	return false;
}

+(bool) decodeObject:(id)obj fromData:(NSData *)oData withProperty:(NSArray*)arrPropertyTypeWrap andTagIndexMap:(const std::map<size_t, size_t>*)mapTagToIndex
{
	if (obj == nil || oData.length <= 0 || arrPropertyTypeWrap.count <= 0 || mapTagToIndex == NULL || mapTagToIndex->size() <= 0) {
		return false;
	}
    
    bool ret = false;
    PBCoder* oCoder = nil;
	@try {
		oCoder = [[PBCoder alloc] initForReadingWithData:oData];
		[oCoder decodeOneObject:obj withProperty:arrPropertyTypeWrap andTagIndexMap:mapTagToIndex];
		ret = true;
	} @catch(NSException *exception) {
		PBError(@"%@", exception);
	}
    oCoder = nil;
    
	return ret;
}

@end


#pragma clang diagnostic pop


