//
//  JustWebView.h
//  JustWebViewPro
//
//  Created by PeachRain on 2018/8/2.
//  Copyright © 2018年 PeachRain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

//调用本类方法时的关键字
#define JUST_GLOBLE_NAME @"justmain"
#define JUST_JS_TO_NATIVE_FUNCTION_NAME  @"justToNative"

@interface JustWebView : WKWebView <WKUIDelegate,WKScriptMessageHandler,WKNavigationDelegate>

@property (nullable, nonatomic, weak) id <WKUIDelegate> JustUIDelegate;

- (void)loadUrl: (NSString * _Nonnull) url;

/*
 *添加MessageHandlerName (自定义类注册，方法会被同名的方式缓存可以调用)
 */
- (void)addScriptMessageHandlerByObject:(id)object;

/*
 *移除MessageHandlerName (webview页面不使用时请主动调用移除方法)
 */
- (void)removeScriptMessageHandler;

/*
 *可以添加本类方法给js调用
 */
- (void)addMainScriptMessageHandleWithSEL:(SEL)sel;

/*
 *native调用js方法
 */
- (void)callHandler:(NSString *)methodName arguments:(NSArray *)args;

- (void)callHandler:(NSString *)methodName withData:(id)data;

/*
 *设置加载进度条
 */
-(void)configProgress;

@end
