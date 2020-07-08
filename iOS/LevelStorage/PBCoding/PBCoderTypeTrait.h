//
//  PBCoderTypeTrait.h
//  MMCommon
//
//  Created by Ling Guo on 7/2/15.
//  Copyright (c) 2015 WXG. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <type_traits>
#include "PBCoder.h"

enum PBCoderPropertyCType {
	PBCoderCType_None,
	PBCoderCType_Bool,
	PBCoderCType_Enum,
	PBCoderCType_Int32,
	PBCoderCType_Int64,
	PBCoderCType_UInt32,
	PBCoderCType_UInt64,
	PBCoderCType_Float,
	PBCoderCType_Double,
	PBCoderCType_Point,
	PBCoderCType_Size,
	PBCoderCType_Rect,
	PBCoderCType_Fixed32,
	PBCoderCType_Fixed64,
	PBCoderCType_SFixed32,
	PBCoderCType_SFixed64,
};

template <typename T>
struct PBCoderTypeTrait {
	static const PBCoderPropertyCType cType = std::is_enum<T>::value ? PBCoderCType_Enum :
		(std::is_same<BOOL, T>::value ? PBCoderCType_Bool : PBCoderCType_None);
};

#pragma mark - bool

template <>
struct PBCoderTypeTrait<bool> {
	static const PBCoderPropertyCType cType = PBCoderCType_Bool;
};

//template <>
//struct PBCoderTypeTrait<BOOL> {
//	static const PBCoderPropertyCType cType = PBCoderCType_Bool;
//};

#pragma mark - Int32

//template <>
//struct PBCoderTypeTrait<char> {
//	static const PBCoderPropertyCType cType = PBCoderCType_Int32;
//};

template <>
struct PBCoderTypeTrait<short> {
	static const PBCoderPropertyCType cType = PBCoderCType_Int32;
};

template <>
struct PBCoderTypeTrait<int> {
	static const PBCoderPropertyCType cType = PBCoderCType_Int32;
};

template <>
struct PBCoderTypeTrait<long> {
	static const PBCoderPropertyCType cType = PBCoderCType_Int32;
};

#pragma mark - UInt32

//template <>
//struct PBCoderTypeTrait<unsigned char> {
//	static const PBCoderPropertyCType cType = PBCoderCType_Int32;
//};

template <>
struct PBCoderTypeTrait<unsigned short> {
	static const PBCoderPropertyCType cType = PBCoderCType_UInt32;
};

template <>
struct PBCoderTypeTrait<unsigned int> {
	static const PBCoderPropertyCType cType = PBCoderCType_UInt32;
};

template <>
struct PBCoderTypeTrait<unsigned long> {
	static const PBCoderPropertyCType cType = PBCoderCType_UInt32;
};

#pragma mark - Int64

template <>
struct PBCoderTypeTrait<long long> {
	static const PBCoderPropertyCType cType = PBCoderCType_Int64;
};

#pragma mark - UInt64

template <>
struct PBCoderTypeTrait<unsigned long long> {
	static const PBCoderPropertyCType cType = PBCoderCType_UInt64;
};

#pragma mark - float

template <>
struct PBCoderTypeTrait<float> {
	static const PBCoderPropertyCType cType = PBCoderCType_Float;
};

#pragma mark - double

template <>
struct PBCoderTypeTrait<double> {
	static const PBCoderPropertyCType cType = PBCoderCType_Double;
};

#pragma mark - for CGRect/CGPoint/CGSize

namespace std {
	template <> struct is_fundamental<CGRect> : public integral_constant<bool, true> {};
	template <> struct is_fundamental<CGPoint> : public integral_constant<bool, true> {};
	template <> struct is_fundamental<CGSize> : public integral_constant<bool, true> {};
}

template <>
struct PBCoderTypeTrait<CGRect> {
	static const PBCoderPropertyCType cType = PBCoderCType_Rect;
};

template <>
struct PBCoderTypeTrait<CGPoint> {
	static const PBCoderPropertyCType cType = PBCoderCType_Point;
};

template <>
struct PBCoderTypeTrait<CGSize> {
	static const PBCoderPropertyCType cType = PBCoderCType_Size;
};

#pragma mark - wrapper for C-MACRO's limitation, or there will be compile error

template <bool isFundamental, typename T>
struct __PBCoderGetClass {
};

template <typename T>
struct __PBCoderGetClass<false, T> {
	Class operator () () const {
		return [typename std::remove_pointer<T>::type class];
	}
};

template <typename T>
struct __PBCoderGetClass<true, T> {
	Class operator () () const {
		return NULL;
	}
};
