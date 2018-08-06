//
//  JustUtil.m
//  JustWebViewPro
//
//  Created by PeachRain on 2018/8/2.
//  Copyright © 2018年 PeachRain. All rights reserved.
//

#import "JustUtil.h"
#import <objc/message.h>

//methodModel
@implementation JustMethodModel

- (instancetype)initWithMethod:(Method)method {
    if (!method) return nil;
    self = [super init];
    _method = method;
    _sel = method_getName(method);
    _imp = method_getImplementation(method);
    const char *name = sel_getName(_sel);
    if (name) {
        _name = [[[NSString stringWithUTF8String:name] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    }
    const char *typeEncoding = method_getTypeEncoding(method);
    if (typeEncoding) {
        _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
    }
    char *returnType = method_copyReturnType(method);
    if (returnType) {
        _returnTypeEncoding = [NSString stringWithUTF8String:returnType];
        free(returnType);
    }
    unsigned int argumentCount = method_getNumberOfArguments(method);
    if (argumentCount > 0) {
        NSMutableArray *argumentTypes = [NSMutableArray new];
        for (unsigned int i = 0; i < argumentCount; i++) {
            char *argumentType = method_copyArgumentType(method, i);
            NSString *type = argumentType ? [NSString stringWithUTF8String:argumentType] : nil;
            [argumentTypes addObject:type ? type : @""];
            if (argumentType) free(argumentType);
        }
        NSInteger index = [argumentTypes indexOfObject:@":"];
        index++;
        if (index == argumentTypes.count) {
            _argumentTypeEncodings = [NSArray array];
        }else
            _argumentTypeEncodings = [argumentTypes subarrayWithRange:NSMakeRange(index, argumentTypes.count - index)];
    }
    return self;
}

@end

@implementation JustObjectModel

- (instancetype)initWithObject:(id)object {
    if (!object) return nil;
    self = [super init];
    
    const char *name = class_getName([object class]);
    _name = [[NSString stringWithUTF8String:name] lowercaseString];
    _object = object;
    _methods = [self allMethodsFromClass:[object class]];
    
    return self;
}

- (void)setMethodsArray:(NSArray*)array {
    _methods = [NSArray arrayWithObjects:array, nil];
}

//获取所有方法对象
- (NSArray *)allMethodsFromClass:(Class)class
{
    NSMutableArray *methodInfos = [NSMutableArray new];
    u_int methodCount;
    Method *methods = class_copyMethodList(class, &methodCount);
    if (methods) {
        for (unsigned int i = 0; i < methodCount; i++) {
            JustMethodModel *info = [[JustMethodModel alloc] initWithMethod:methods[i]];
            [methodInfos addObject:info];
        }
        free(methods);
    }
    return methodInfos;
}

//执行某个方法
- (void) dealMethod:(NSDictionary*)infoDic {
    NSString *methodName = [[NSString stringWithFormat:@"%@",infoDic[@"method"]] lowercaseString];
    if (!methodName) {
        return;
    }
    
    if (infoDic[@"params"] && ![infoDic[@"params"] isKindOfClass:[NSArray class]]) {
        return;
    }
    
    NSString *callback = nil;
    if (infoDic[@"callback"]) {
        callback = infoDic[@"callback"];
    }
    
    NSArray *strs = infoDic[@"params"];
    if (methodName) {
        for (JustMethodModel *method in _methods) {
            if ([method.name isEqualToString:methodName]) {
                [self makeInvokeSendMsgToObject:method withArg:strs withCallback:callback];
                break;
            }
        }
    }else {
        NSLog(@"JustWebViewPro: jsToNative error: 调用的方法不存在 info：%s (%d)",__FUNCTION__,__LINE__);
    }
}

//通过消息派发执行方法
- (void)makeInvokeSendMsgToObject:(JustMethodModel*)method withArg:(NSArray*)arg withCallback:(NSString*)callback {
    NSInteger args = [arg count];
    BOOL hasCallback = callback ? YES : NO;
    if (hasCallback) {
        args++;
    }
    
    if (args != method.argumentTypeEncodings.count) {
        NSLog(@"JustWebViewPro: jsToNative error: 调用参数错误 info：%s (%d)",__FUNCTION__,__LINE__);
        return;
    }
    //直接消息派发
    if (args == 0) {
        ((void (*)(id, SEL))(void *) objc_msgSend)(self.object, method.sel);
    }else if (args == 1) {
        if (hasCallback) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(self.object, method.sel, ^(NSString* method, id data) {
                [self sendNotification:method withData:data callback:callback];
            });
        }else{
            id param = arg.firstObject;
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(self.object, method.sel, param);
        }
    }else if (args == 2) {
        if (hasCallback) {
            id param = arg.firstObject;
            ((void (*)(id, SEL, id, id))(void *) objc_msgSend)(self.object, method.sel, param, ^(NSString* method, id data) {
                [self sendNotification:method withData:data callback:callback];
            });
        }else{
            id param = arg.firstObject;
            id param2 = arg.lastObject;
            ((void (*)(id, SEL, id, id))(void *) objc_msgSend)(self.object, method.sel, param, param2);
        }
    }else if (args == 3) {
        
        if (hasCallback) {
            id param = arg.firstObject;
            id param2 = arg[1];
            ((void (*)(id, SEL, id, id, id))(void *) objc_msgSend)(self.object, method.sel, param, param2, ^(NSString* method, id data) {
                [self sendNotification:method withData:data callback:callback];
            });
        }else{
            id param = arg.firstObject;
            id param2 = arg[1];
            id param3 = arg.lastObject;
            ((void (*)(id, SEL, id, id, id))(void *) objc_msgSend)(self.object, method.sel, param, param2, param3);
        }
    }else {
        NSLog(@"JustWebViewPro: jsToNative error: 调用的方法参数不能多于3个 info：%s (%d)",__FUNCTION__,__LINE__);
    }
    
}

//发送回调消息
- (void)sendNotification:(NSString*)method withData:(id)data callback:(NSString*)imp{
    NSDictionary *dic = @{@"method":method,@"callback":imp,@"data": data};
    [[NSNotificationCenter defaultCenter] postNotificationName:JUST_CALLBACK_NOTIFICATION object:nil userInfo:dic];
}

@end


@implementation JustUtil

//暂时无用可以删除
+ (JustEncodingType)getArgumentByType:(NSString *)typeEncoding {
    if ([typeEncoding isEqualToString:@"v"]) {
        return JustEncodingTypeVoid;
    }else if ([typeEncoding isEqualToString:@"B"]) {
        return JustEncodingTypeBool;
    }else if ([typeEncoding isEqualToString:@"c"]) {
        return JustEncodingTypeInt8;
    }else if ([typeEncoding isEqualToString:@"C"]) {
        return JustEncodingTypeUInt8;
    }else if ([typeEncoding isEqualToString:@"s"]) {
        return JustEncodingTypeInt16;
    }else if ([typeEncoding isEqualToString:@"S"]) {
        return JustEncodingTypeUInt16;
    }else if ([typeEncoding isEqualToString:@"i"]) {
        return JustEncodingTypeInt32;
    }else if ([typeEncoding isEqualToString:@"I"]) {
        return JustEncodingTypeUInt32;
    }else if ([typeEncoding isEqualToString:@"1"]) {
        return JustEncodingTypeInt32;
    }else if ([typeEncoding isEqualToString:@"L"]) {
        return JustEncodingTypeUInt32;
    }else if ([typeEncoding isEqualToString:@"q"]) {
        return JustEncodingTypeInt64;
    }else if ([typeEncoding isEqualToString:@"Q"]) {
        return JustEncodingTypeUInt64;
    }else if ([typeEncoding isEqualToString:@"f"]) {
        return JustEncodingTypeFloat;
    }else if ([typeEncoding isEqualToString:@"d"]) {
        return JustEncodingTypeDouble;
    }else if ([typeEncoding isEqualToString:@"@"]) {
        return JustEncodingTypeString;
    }else {
        return JustEncodingTypeUnknown;
    }
}

+(NSArray *)allMethodFromClass:(Class)class
{
    NSMutableArray *arr = [NSMutableArray array];
    u_int count;
    Method *methods = class_copyMethodList(class, &count);
    for (int i =0; i<count; i++) {
        SEL name1 = method_getName(methods[i]);
        const char *selName= sel_getName(name1);
        NSString *strName = [NSString stringWithCString:selName encoding:NSUTF8StringEncoding];
        [arr addObject:strName];
    }
    free(methods);
    return arr;
}

+ (NSString *)objToJsonString:(id)dict
{
    if ([dict isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"%@",dict];
    }
    
    if (![dict isKindOfClass:[NSDictionary class]]) {
        NSLog(@"JustWebViewPro: jsToNative error: json转换出错 info：%s (%d)",__FUNCTION__,__LINE__);
        return nil;
    }
    
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (! jsonData) {
        return @"{}";
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

+ (NSDictionary *)jsonStringToDic:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

@end
