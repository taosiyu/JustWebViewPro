//
//  JustWebView.m
//  JustWebViewPro
//
//  Created by Assassin on 2018/8/2.
//  Copyright © 2018年 PeachRain. All rights reserved.
//

#import "JustWebView.h"
#import "JustUtil.h"

@interface JustWebView()
{
    NSMutableDictionary<NSString *,JustObjectModel*> *_javaScriptAndObject;
    
    NSMutableDictionary<NSString *,NSString *> *_javaScriptCallBacks;
    
    UIProgressView *_progressView;
}

@end

@implementation JustWebView

#pragma mark -private

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        super.UIDelegate = self;
        
        _javaScriptAndObject = [NSMutableDictionary dictionary];
        
        _javaScriptCallBacks = [NSMutableDictionary dictionary];
        
        [self beginConfiguration];
        [self beginJavascriptInsert];
        [self addMainScriptMessageHandle];
        
        
    }
    return self;
}

//config基本配置
- (void)beginConfiguration {
    
    /// 偏好设置,涉及JS交互
    self.configuration.preferences = [[WKPreferences alloc]init];
    self.configuration.preferences.javaScriptEnabled = YES;
    self.configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    self.configuration.processPool = [[WKProcessPool alloc]init];
    self.configuration.allowsInlineMediaPlayback = YES;
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    self.configuration.userContentController = controller;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(justcallback:) name:JUST_CALLBACK_NOTIFICATION object:nil];
    
}

//注入js
- (void)beginJavascriptInsert{
    //注入通用执行js方法 justToNative
    //js端执行方法 justToNative（对应的类型（小写） , methodName（类中方法名），参数）
    //例子:this.justToNative("testfun", "test","['name','test']","callcell")
    NSString *jsStr = [NSString stringWithFormat:@"function %@(name,methodName,param,callback) { if (name == null || methodName == null){return;};var dic = \"{method:\" + \"'\" + methodName + \"'\";if(param){dic = dic + \",params:\" + param;};if (callback) {dic = dic + \",callback:\" +\"'\" + callback + \"'\";};dic = dic +\"}\";var nativeStr = 'window.webkit.messageHandlers.' + name + '.postMessage' + '(' + (dic ? dic : null) + ')';eval(nativeStr);}",JUST_JS_TO_NATIVE_FUNCTION_NAME];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:jsStr
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                               forMainFrameOnly:YES];
    [self.configuration.userContentController addUserScript:script];
    
}

- (void)addMainScriptMessageHandle {
    JustObjectModel *objc = [[JustObjectModel alloc]initWithObject:self];
    if (objc) {
        [objc setMethodsArray:nil];
        //缓存对象并注入name到js
        [_javaScriptAndObject setValue:objc forKey:JUST_GLOBLE_NAME];
        //调用本类方法所需要的标记
        [self.configuration.userContentController addScriptMessageHandler:self name:JUST_GLOBLE_NAME];
    }
}

//可以添加本类方法给js调用
- (void)addMainScriptMessageHandleWithSEL:(SEL)sel {
    if (!sel) {
        return;
    }
    
    JustObjectModel *objc = [_javaScriptAndObject valueForKey:JUST_GLOBLE_NAME];
    if (objc) {
        Method method = class_getInstanceMethod([self class], sel);
        JustMethodModel *info = [[JustMethodModel alloc] initWithMethod:method];
        NSMutableArray *temp = [NSMutableArray arrayWithObjects:objc.methods, nil];
        [temp addObject:info];
        [objc setMethodsArray:temp];
        //重新替换
        [_javaScriptAndObject setValue:objc forKey:JUST_GLOBLE_NAME];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JUST_CALLBACK_NOTIFICATION object:nil];
    [self removeEstimatedProgressKVO];
    [self removeScriptMessageHandler];
    [self.configuration.userContentController removeAllUserScripts];
}

//统一的回调
- (void)justcallback:(NSNotification*)noti {
    @synchronized(self) {
        if ([noti.userInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary*)noti.userInfo;
            NSString *callback = dic[@"callback"];
            id dataInfo = dic[@"data"];
            [self callHandler:callback withData:dataInfo];
        }
    }
}

#pragma mark -public
//加载网页
- (void)loadUrl:(NSString *)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self loadRequest:request];
}


//添加MessageHandlerName
- (void)addScriptMessageHandlerByObject:(id)object {
    if (object!=NULL) {
        JustObjectModel *objc = [[JustObjectModel alloc]initWithObject:object];
        if (objc) {
            //缓存对象并注入name到js
            [_javaScriptAndObject setValue:objc forKey:objc.name];
            [self.configuration.userContentController addScriptMessageHandler:self name:objc.name];
        }
    }
}

//移除MessageHandlerName
- (void)removeScriptMessageHandler {
    if (_javaScriptAndObject.allValues.count > 0) {
        for (JustObjectModel *objc in _javaScriptAndObject.allValues) {
            [self.configuration.userContentController removeScriptMessageHandlerForName:objc.name];
        }
    }
    [self.configuration.userContentController addScriptMessageHandler:self name:JUST_GLOBLE_NAME];
}

//加载条
-(void)configProgress{
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.progressTintColor = [UIColor blueColor];
    _progressView.trackTintColor = [UIColor grayColor];
    _progressView.progress = 0.5f;
    CGFloat topY = 0;
    if ([UIScreen mainScreen].bounds.size.width == 375.f && [UIScreen mainScreen].bounds.size.height == 812.f) {
        topY = 44;
    };
    _progressView.frame = CGRectMake(0, topY, self.bounds.size.width, 2);
    [self addSubview:_progressView];
    
    [self addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self) {
            if (self.estimatedProgress == 1.0) {
                _progressView.progress = 1.0;
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    _progressView.alpha = 0.0f;
                } completion:nil];
            } else {
                _progressView.progress = self.estimatedProgress;
            }
        }
    }
}

- (void)removeEstimatedProgressKVO {
    [self removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)callHandler:(NSString *)methodName withData:(id)data{
    NSString * json = [JustUtil objToJsonString:@{@"data":[JustUtil objToJsonString: data]}];
    [self evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",methodName,json]
           completionHandler:nil];
}

- (void)callHandler:(NSString *)methodName arguments:(NSArray *)args{
    [self callHandler:methodName arguments:args completionHandler:nil];
}

- (void)callHandler:(NSString *)methodName completionHandler:(void (^)(id _Nullable))completionHandler{
    [self callHandler:methodName arguments:nil completionHandler:completionHandler];
}

-(void)callHandler:(NSString *)methodName arguments:(NSArray *)args completionHandler:(void (^)(id  _Nullable value))completionHandler
{
    NSString * json = [JustUtil objToJsonString:@{@"data":[JustUtil objToJsonString: args]}];
    [self evaluateJavaScript:[NSString stringWithFormat:@"%@(%@)",methodName,json]
           completionHandler:nil];
}

#pragma mark -WKUIDelegate
// 在JS端调用alert函数时(警告弹窗)，会触发此代理方法。
// 通过completionHandler()回调JS
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    if( self.JustUIDelegate &&  [self.JustUIDelegate respondsToSelector:
                                 @selector(webView:runJavaScriptAlertPanelWithMessage
                                           :initiatedByFrame:completionHandler:)])
    {
        return [self.JustUIDelegate webView:webView runJavaScriptAlertPanelWithMessage:message
                           initiatedByFrame:frame
                          completionHandler:completionHandler];
    }
    
    if ([self getRootViewcontroller]) {
        UIAlertController *alert = [self getAlertController:message title:@"提示" okBtn:@"确定" cancel:nil okBlock:nil cBlock:nil];
        [[self getRootViewcontroller] presentViewController:alert animated:YES completion:completionHandler];
    }
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    if( self.JustUIDelegate && [self.JustUIDelegate respondsToSelector:
                              @selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)])
    {
        return[self.JustUIDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message
                        initiatedByFrame:frame
                       completionHandler:completionHandler];
    }
    
    if ([self getRootViewcontroller]) {
        UIAlertController *alert = [self getAlertController:message title:@"提示" okBtn:@"确定" cancel:@"取消" okBlock:^void (bool alert) {
            completionHandler(alert);
        } cBlock:^void (bool alert) {
            completionHandler(alert);
        }];
        [[self getRootViewcontroller] presentViewController:alert animated:YES completion:nil];
    }
    
}

//有使用的情况下请重写
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(nonnull void (^)(NSString * _Nullable))completionHandler{
    if(self.JustUIDelegate && [self.JustUIDelegate respondsToSelector:
                               @selector(JustUIDelegate:runJavaScriptTextInputPanelWithPrompt
                                         :defaultText:initiatedByFrame
                                         :completionHandler:)])
    {
        return [self.JustUIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt
                                defaultText:defaultText
                           initiatedByFrame:frame
                          completionHandler:completionHandler];
    }
    
    if ([self getRootViewcontroller]) {
        UIAlertController *alert = [self getAlertController:prompt title:@"提示" okBtn:@"确定" cancel:@"取消" okBlock:^void (bool alert) {
            completionHandler(@"");
        } cBlock:^void (bool alert) {
            completionHandler(@"");
        }];
        [[self getRootViewcontroller] presentViewController:alert animated:YES completion:nil];
    }
}

- (UIAlertController *)getAlertController:(NSString *)message title:(NSString *)title okBtn:(NSString *)okStr cancel:(NSString *)cStr okBlock:(void (^)(bool))okBlock cBlock:(void (^)(bool))cBlock{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:okStr style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              //响应事件
                                                              if (okBlock) {
                                                                  okBlock(YES);
                                                              }
                                                          }];
    [alert addAction:defaultAction];
    if (cStr.length > 0) {
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:cStr style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 //响应事件
                                                                 if (cBlock) {
                                                                     cBlock(NO);
                                                                 }
                                                             }];
        
        
        [alert addAction:cancelAction];
    }
    
    return alert;
}

#pragma mark -WKNavigationDelegate

// 发送请求前决定是否跳转，并在此拦截拨打电话的URL
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    /// decisionHandler(WKNavigationActionPolicyCancel);不允许加载
    /// decisionHandler(WKNavigationActionPolicyAllow);允许加载
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

//内容开始加载
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    _progressView.alpha = 1.0;
}

/// 加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
//    [self hideErrorView];
    if (_progressView && _progressView.progress < 1.0) {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _progressView.alpha = 0.0f;
        } completion:nil];
    }
    
    // 禁止长按弹窗，UIActionSheet样式弹窗
    [webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
    // 禁止长按弹窗，UIMenuController样式弹窗
    [self evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
}

/// 加载失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if (error.code == NSURLErrorNotConnectedToInternet) {
//        [self showErrorView];
        // 无网络(APP第一次启动并且没有得到网络授权时可能也会报错)
    } else if (error.code == NSURLErrorCancelled){
        ///-999 上一页面还没加载完，就加载当下一页面，就会报这个错。
        return;
    }
}


#pragma mark -userContentController

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"JS调iOS  name : %@    body : %@",message.name,message.body);
    if (!message.name) {
        return;
    }
    
    //查询执行对象
    JustObjectModel *objc = [_javaScriptAndObject valueForKey:message.name];
    
    if (objc) {
        if ([message.body isKindOfClass:[NSDictionary class]]) {
            NSDictionary *infoDic = (NSDictionary*)message.body;
            if (infoDic.allValues.count > 0) {
                [objc dealMethod:infoDic];
            }
        }else if ([message.body isKindOfClass:[NSString class]]){
            NSDictionary *infoDic = [JustUtil jsonStringToDic:message.body];
            if (infoDic.allValues.count > 0) {
                [objc dealMethod:infoDic];
            }
        }
    }else {
        NSLog(@"JustWebViewPro: jsToNative error: 调用的方法对象不存在 info：%s (%d)",__FUNCTION__,__LINE__);
    }
}

- (UIViewController *)getRootViewcontroller {
    id<UIApplicationDelegate> appdelegate = [UIApplication sharedApplication].delegate;
    return appdelegate.window.rootViewController;
}

@end









