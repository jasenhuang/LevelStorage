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

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <type_traits>
#import "LSCoder.h"

enum LSCoderPropertyCType {
	LSCoderCType_None,
	LSCoderCType_Bool,
	LSCoderCType_Enum,
	LSCoderCType_Int32,
	LSCoderCType_Int64,
	LSCoderCType_UInt32,
	LSCoderCType_UInt64,
	LSCoderCType_Float,
	LSCoderCType_Double,
	LSCoderCType_Point,
	LSCoderCType_Size,
	LSCoderCType_Rect,
	LSCoderCType_Fixed32,
	LSCoderCType_Fixed64,
	LSCoderCType_SFixed32,
	LSCoderCType_SFixed64,
};

template <typename T>
struct LSCoderTypeTrait {
	static const LSCoderPropertyCType cType = std::is_enum<T>::value ? LSCoderCType_Enum :
		(std::is_same<BOOL, T>::value ? LSCoderCType_Bool : LSCoderCType_None);
};

#pragma mark - bool

template <>
struct LSCoderTypeTrait<bool> {
	static const LSCoderPropertyCType cType = LSCoderCType_Bool;
};

//template <>
//struct LSCoderTypeTrait<BOOL> {
//	static const LSCoderPropertyCType cType = LSCoderCType_Bool;
//};

#pragma mark - Int32

//template <>
//struct LSCoderTypeTrait<char> {
//	static const LSCoderPropertyCType cType = LSCoderCType_Int32;
//};

template <>
struct LSCoderTypeTrait<short> {
	static const LSCoderPropertyCType cType = LSCoderCType_Int32;
};

template <>
struct LSCoderTypeTrait<int> {
	static const LSCoderPropertyCType cType = LSCoderCType_Int32;
};

template <>
struct LSCoderTypeTrait<long> {
	static const LSCoderPropertyCType cType = LSCoderCType_Int32;
};

#pragma mark - UInt32

//template <>
//struct LSCoderTypeTrait<unsigned char> {
//	static const LSCoderPropertyCType cType = LSCoderCType_Int32;
//};

template <>
struct LSCoderTypeTrait<unsigned short> {
	static const LSCoderPropertyCType cType = LSCoderCType_UInt32;
};

template <>
struct LSCoderTypeTrait<unsigned int> {
	static const LSCoderPropertyCType cType = LSCoderCType_UInt32;
};

template <>
struct LSCoderTypeTrait<unsigned long> {
	static const LSCoderPropertyCType cType = LSCoderCType_UInt32;
};

#pragma mark - Int64

template <>
struct LSCoderTypeTrait<long long> {
	static const LSCoderPropertyCType cType = LSCoderCType_Int64;
};

#pragma mark - UInt64

template <>
struct LSCoderTypeTrait<unsigned long long> {
	static const LSCoderPropertyCType cType = LSCoderCType_UInt64;
};

#pragma mark - float

template <>
struct LSCoderTypeTrait<float> {
	static const LSCoderPropertyCType cType = LSCoderCType_Float;
};

#pragma mark - double

template <>
struct LSCoderTypeTrait<double> {
	static const LSCoderPropertyCType cType = LSCoderCType_Double;
};

#pragma mark - for CGRect/CGPoint/CGSize

namespace std {
	template <> struct is_fundamental<CGRect> : public integral_constant<bool, true> {};
	template <> struct is_fundamental<CGPoint> : public integral_constant<bool, true> {};
	template <> struct is_fundamental<CGSize> : public integral_constant<bool, true> {};
}

template <>
struct LSCoderTypeTrait<CGRect> {
	static const LSCoderPropertyCType cType = LSCoderCType_Rect;
};

template <>
struct LSCoderTypeTrait<CGPoint> {
	static const LSCoderPropertyCType cType = LSCoderCType_Point;
};

template <>
struct LSCoderTypeTrait<CGSize> {
	static const LSCoderPropertyCType cType = LSCoderCType_Size;
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
