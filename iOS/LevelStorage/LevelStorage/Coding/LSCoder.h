//
//  LSCoder.h
//  LSCoder
//
//  Copyright (c) 2013 Guo Ling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <map>
#import <objc/runtime.h>
#import "LSCoderTypeTrait.h"

@protocol LSCoding <NSObject>

-(NSArray*) getValueTypeTable;
-(const std::map<size_t, size_t>*) getValueTagIndexMap;

@end


@interface LSCoder : NSObject

+(bool) encodeObject:(id)obj toFile:(NSString*)nsPath;
+(NSData*) encodeDataWithObject:(id)obj;

+(id) decodeObjectOfClass:(Class)cls fromFile:(NSString*)nsPath;
+(id) decodeObjectOfClass:(Class)cls fromData:(NSData*)oData;

+(bool) decodeObject:(id)obj fromFile:(NSString*)nsPath;
+(bool) decodeObject:(id)obj fromData:(NSData*)oData;

// for NSArray/NSDictionary, etc
// 注意：Dictionary 的 key 必须是 NSString 类型
+(id) decodeContainerOfClass:(Class)cls withValueClass:(Class)valueClass fromFile:(NSString*)nsPath;
+(id) decodeContainerOfClass:(Class)cls withValueClass:(Class)valueClass fromData:(NSData*)oData;

// append快速添加到文件末尾
+(bool) appendOneArrayValue:(id)obj toFile:(NSString*)nsPath;
+(bool) appendOneSetValue:(id)obj toFile:(NSString*)nsPath;
+(bool) appendOneDictionaryValue:(id)obj forKey:(NSString*)nsKey toFile:(NSString*)nsPath;

+(bool) appendArray:(NSArray*)oArray toFile:(NSString*)nsPath;
+(bool) appendSet:(NSSet*)oSet toFile:(NSString*)nsPath;
+(bool) appendDictionary:(NSDictionary*)oDictionary toFile:(NSString*)nsPath;

// append快速添加到buffer末尾
+(bool) appendOneArrayValue:(id)obj toData:(NSMutableData*)oData;
+(bool) appendOneSetValue:(id)obj toData:(NSMutableData*)oData;
+(bool) appendOneDictionaryValue:(id)obj forKey:(NSString*)nsKey toData:(NSMutableData*)oData;

+(bool) appendArray:(NSArray*)oArray toData:(NSMutableData*)oData;
+(bool) appendSet:(NSSet*)oSet toData:(NSMutableData*)oData;
+(bool) appendDictionary:(NSDictionary*)oDictionary toData:(NSMutableData*)oData;

@end


@interface LSCoderPropertyType : NSObject

@property (nonatomic, assign) uint32_t m_index;
@property (nonatomic, readonly) LSCoderPropertyCType m_cType;
@property (nonatomic, readonly) Class m_cls;
@property (nonatomic, readonly) Class m_subCls;
@property (nonatomic, readonly) LSCoderPropertyCType m_subCType;
@property (nonatomic, readonly) SEL m_getter;
@property (nonatomic, readonly) SEL m_setter;
@property (nonatomic, strong) id m_blockGet;
@property (nonatomic, strong) id m_blockSet;
@property (nonatomic, assign) BOOL m_isSuperPlaceHolder;
@property (nonatomic, assign) BOOL m_isContainerUnpacked;

-(id) initWithClass:(Class) cls subClass:(Class) subCls index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet;
-(id) initWithClass:(Class) cls subClass:(Class) subCls unpacked:(BOOL)unpacked index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet;
-(id) initWithClass:(Class) cls subCType:(LSCoderPropertyCType) subCType index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet;
-(id) initWithClass:(Class) cls subCType:(LSCoderPropertyCType) subCType unpacked:(BOOL)unpacked index:(uint32_t) index getter:( SEL) getter setter:( SEL) setter blockGet:(id)blockGet blockSet:(id)blockSet;

-(id) initWithCType:(LSCoderPropertyCType)cType index:(uint32_t)index getter:(SEL)getter setter:(SEL)setter blockGet:(id)blockGet blockSet:(id)blockSet;

@end

// get setter of a property: setM_contact/setDelegate, etc
SEL genSetterSelector(NSString* property);

// helper to add object in global code, C/C++/ObjC forbid writing code in global space, sucks
struct PBArrayAddHelper
{
	LSCoderPropertyType* m_obj;
	
	PBArrayAddHelper(NSMutableArray* arr, LSCoderPropertyType* obj);
	~PBArrayAddHelper();
};


#define PBCODER_PP_IIF_0(t, f) f
#define PBCODER_PP_IIF_1(t, f) t

#define PBCODER_PP_IIF_I(bit, t, f) PBCODER_PP_IIF_ ## bit(t, f)

#define PBCODER_PP_IF(cond, t, f) PBCODER_PP_IIF_I(cond, t, f)

void _pbcoder_initPBTable(Class cls, NSMutableArray* arrWrap, std::map<size_t, size_t>& mapTagToIndex, bool& hasInit);

// begin property table
#define PBCODER_TABLE_BEGIN(PBStruct) \
	static NSMutableArray* g_s_arrayWrapOf##PBStruct = [[NSMutableArray alloc] init]; \
	static std::map<size_t, size_t> mapTagToIndexOf##PBStruct; \
	static bool hasInitPBTableOf##PBStruct = false;

// end property table
#define PBCODER_TABLE_END_INIT(PBStruct, hasInit) \
    PBCODER_PP_IF(hasInit, PBCODER_TABLE_END_INIT_HAS(PBStruct), PBCODER_TABLE_END_INIT_EMPTY) \
    \
	-(NSMutableArray*) getValueTypeTable { \
		if (g_s_arrayWrapOf##PBStruct.count != mapTagToIndexOf##PBStruct.size()) { \
			_pbcoder_initPBTable(PBStruct.class, g_s_arrayWrapOf##PBStruct, mapTagToIndexOf##PBStruct, hasInitPBTableOf##PBStruct); \
		} \
		return g_s_arrayWrapOf##PBStruct;\
	} \
	-(const std::map<size_t, size_t>*) getValueTagIndexMap { \
		if (g_s_arrayWrapOf##PBStruct.count != mapTagToIndexOf##PBStruct.size()) { \
			_pbcoder_initPBTable(PBStruct.class, g_s_arrayWrapOf##PBStruct, mapTagToIndexOf##PBStruct, hasInitPBTableOf##PBStruct); \
		} \
		return &mapTagToIndexOf##PBStruct; \
	}

#define PBCODER_TABLE_END_INIT_HAS(PBStruct) \
    +(void)initialize { \
        if (self != PBStruct.class) { \
            return; \
        } \
		_pbcoder_initPBTable(PBStruct.class, g_s_arrayWrapOf##PBStruct, mapTagToIndexOf##PBStruct, hasInitPBTableOf##PBStruct); \
    }

#define PBCODER_TABLE_END_INIT_EMPTY

#define PBCODER_TABLE_END(PBStruct) PBCODER_TABLE_END_INIT(PBStruct, 1)

// properties
#define PBCODER_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	typedef typeof(((PBStruct*) NULL).name) __typeOf##name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = std::is_fundamental<__typeOf##name>::value ? \
		PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
			[[LSCoderPropertyType alloc] initWithCType:LSCoderTypeTrait<__typeOf##name>::cType index:uIndex getter:nil setter:nil blockGet:^__typeOf##name(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, __typeOf##name value){ obj.name = value; } ]) \
	: \
		PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
			[[LSCoderPropertyType alloc] initWithClass:__PBCoderGetClass<std::is_fundamental<__typeOf##name>::value, __typeOf##name>()() subClass:NULL index:uIndex getter:NSSelectorFromString(@""#name) setter:genSetterSelector(@""#name) blockGet:nil blockSet:nil ]);

// 注意：Dictionary 的 key 必须是 NSString 类型
#define PBCODER_CONTAINER_PROPERTY(PBStruct, name, type, valueType, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithClass:[type class] subClass:[valueType class] index:uIndex getter:NSSelectorFromString(@""#name) setter:genSetterSelector(@""#name) blockGet:nil blockSet:nil ]);

#define PBCODER_CONTAINER_C_PROPERTY(PBStruct, name, type, cValueType, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithClass:[type class] subCType:cValueType index:uIndex getter:NSSelectorFromString(@""#name) setter:genSetterSelector(@""#name) blockGet:nil blockSet:nil ]);

#define PBCODER_UNPACKED_CONTAINER_PROPERTY(PBStruct, name, type, valueType, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithClass:[type class] subClass:[valueType class] unpacked:YES index:uIndex getter:NSSelectorFromString(@""#name) setter:genSetterSelector(@""#name) blockGet:nil blockSet:nil ]);

#define PBCODER_UNPACKED_CONTAINER_C_PROPERTY(PBStruct, name, type, cValueType, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithClass:[type class] subCType:cValueType unpacked:YES index:uIndex getter:NSSelectorFromString(@""#name) setter:genSetterSelector(@""#name) blockGet:nil blockSet:nil ]);

#define PBCODER_FIXED32_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Fixed32 index:uIndex getter:nil setter:nil blockGet:^uint32_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, uint32_t value){ obj.name = value; } ]);

#define PBCODER_FIXED64_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Fixed64 index:uIndex getter:nil setter:nil blockGet:^uint64_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, uint64_t value){ obj.name = value; } ]);

#define PBCODER_SFIXED32_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_SFixed32 index:uIndex getter:nil setter:nil blockGet:^int32_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, int32_t value){ obj.name = value; } ]);

#define PBCODER_SFIXED64_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_SFixed64 index:uIndex getter:nil setter:nil blockGet:^int64_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, int64_t value){ obj.name = value; } ]);


// deprecated

#define PBCODER_OBJ_PROPERTY(PBStruct, name, type, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithClass:[type class] subClass:NULL index:uIndex getter:NSSelectorFromString(@""#name) setter:genSetterSelector(@""#name) blockGet:nil blockSet:nil ]);

#define PBCODER_BOOL_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Bool index:uIndex getter:nil setter:nil blockGet:^bool(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, bool value){ obj.name = value; } ]);

#define PBCODER_ENUM_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Enum index:uIndex getter:nil setter:nil blockGet:^int32_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, int32_t value){ obj.name = (typeof(obj.name))value; } ]);

#define PBCODER_INT32_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Int32 index:uIndex getter:nil setter:nil blockGet:^int32_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, int32_t value){ obj.name = value; } ]);

#define PBCODER_INT64_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Int64 index:uIndex getter:nil setter:nil blockGet:^int64_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, int64_t value){ obj.name = value; } ]);

#define PBCODER_UINT32_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_UInt32 index:uIndex getter:nil setter:nil blockGet:^uint32_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, uint32_t value){ obj.name = value; } ]);

#define PBCODER_UINT64_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_UInt64 index:uIndex getter:nil setter:nil blockGet:^uint64_t(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, uint64_t value){ obj.name = value; } ]);

#define PBCODER_FLOAT_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Float index:uIndex getter:nil setter:nil blockGet:^float(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, float value){ obj.name = value; } ]);

#define PBCODER_DOUBLE_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Double index:uIndex getter:nil setter:nil blockGet:^double(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, double value){ obj.name = value; } ]);

#define PBCODER_POINT_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Point index:uIndex getter:nil setter:nil blockGet:^CGPoint(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, CGPoint value){ obj.name = value; } ]);

#define PBCODER_SIZE_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Size index:uIndex getter:nil setter:nil blockGet:^CGSize(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, CGSize value){ obj.name = value; } ]);

#define PBCODER_RECT_PROPERTY(PBStruct, name, uIndex) \
	@synthesize name; \
	PBArrayAddHelper _g_pbArrayAddHelper_##PBStruct##name = PBArrayAddHelper(g_s_arrayWrapOf##PBStruct, \
		[[LSCoderPropertyType alloc] initWithCType:LSCoderCType_Rect index:uIndex getter:nil setter:nil blockGet:^CGRect(PBStruct* obj){ return obj.name; } blockSet:^(PBStruct* obj, CGRect value){ obj.name = value; } ]);


//#define PBError(format, ...)	MMErrorWithModule("LSCoder", format, ##__VA_ARGS__)
//#define PBWarning(format, ...)	MMWarningWithModule("LSCoder", format, ##__VA_ARGS__)
//#define PBInfo(format, ...)		MMInfoWithModule("LSCoder", format, ##__VA_ARGS__)
//#define PBDebug(format, ...)	MMDebugWithModule("LSCoder", format, ##__VA_ARGS__)
#define PBError(format, ...)	NSLog(format, ##__VA_ARGS__)
#define PBWarning(format, ...)	NSLog(format, ##__VA_ARGS__)
#define PBInfo(format, ...)		NSLog(format, ##__VA_ARGS__)
#define PBDebug(format, ...)	NSLog(format, ##__VA_ARGS__)
