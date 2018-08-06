//
//  JustUtil.h
//  JustWebViewPro
//
//  Created by Assassin on 2018/8/2.
//  Copyright © 2018年 PeachRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define JUST_CALLBACK_NOTIFICATION  @"Just_callback_notification"

typedef NS_OPTIONS(NSUInteger, JustEncodingType) {
    JustEncodingTypeUnknown    = 0, ///< unknown
    JustEncodingTypeVoid       = 1, ///< void
    JustEncodingTypeBool       = 2, ///< bool
    JustEncodingTypeInt8       = 3, ///< char / BOOL
    JustEncodingTypeUInt8      = 4, ///< unsigned char
    JustEncodingTypeInt16      = 5, ///< short
    JustEncodingTypeUInt16     = 6, ///< unsigned short
    JustEncodingTypeInt32      = 7, ///< int
    JustEncodingTypeUInt32     = 8, ///< unsigned int
    JustEncodingTypeInt64      = 9, ///< long long
    JustEncodingTypeUInt64     = 10, ///< unsigned long long
    JustEncodingTypeFloat      = 11, ///< float
    JustEncodingTypeDouble     = 12, ///< double
    JustEncodingTypeObject     = 13, ///< id
    JustEncodingTypeString     = 14, ///< String
};

@interface JustMethodModel : NSObject

@property (nonatomic, assign, readonly) Method method;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) SEL sel;
@property (nonatomic, assign, readonly) IMP imp;
@property (nonatomic, strong, readonly) NSString *typeEncoding;
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings;  //参数code

- (instancetype)initWithMethod:(Method)method;

@end

@interface JustObjectModel : NSObject

@property (nonatomic, strong, readonly) NSString *name;  //类名
@property (nonatomic, strong, readonly) id object;       //持有对象用于调用方法
@property (nullable,nonatomic, copy, readonly)NSArray<JustMethodModel *> *methods;  //方法列表

- (instancetype)initWithObject:(id)object;

- (void) dealMethod:(NSDictionary*)infoDic;

- (void)setMethodsArray:(NSArray*)array;

@end



@interface JustUtil : NSObject

+ (NSArray *)allMethodFromClass:(Class)class;

+ (NSString *)objToJsonString:(id)dict;

+ (NSDictionary *)jsonStringToDic:(NSString *)jsonString;

+ (JustEncodingType)getArgumentByType:(NSString *)typeEncoding;

@end
