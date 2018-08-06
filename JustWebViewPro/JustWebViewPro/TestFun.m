//
//  TestFun.m
//  JustWebViewPro
//
//  Created by Assassin on 2018/8/2.
//  Copyright © 2018年 PeachRain. All rights reserved.
//

#import "TestFun.h"

@implementation TestFun

- (void)test:(NSString *)str {
    NSLog(@"test 显示的是: %@",str);
}

- (void)test2:(NSInteger)str {
    NSLog(@"这是回调信息 显示的是%li",str);
}

- (void)test3:(BOOL)str string:(NSString*)title {
    NSLog(@"test3 显示的是:%i %@",str,title);
}

- (void)test4:(NSString *)str {
    NSLog(@"test4 显示的是: %@",str);
}

- (void)test7:(id)str {
    NSLog(@"显示的是%@",str);
}

- (NSUInteger)test5:(NSString *)str withAge:(NSInteger)age {
    NSLog(@"显示的是%@",str);
    return 1;
}

- (void)test8:(id)str msg:(void (^)(void))completionHandler{
    NSLog(@"显示的是%@",str);
    completionHandler();
}

- (void) test9:(NSString *) msg :(void (^)(NSString * _Nullable result,id data))completionHandler
{
    completionHandler(@"test2",@"323");
}

@end
