# JustWebView  for  IOS

![dsBridge](https://github.com/taosiyu/JustWebViewPro/raw/master/img/top.png)


![language](https://img.shields.io/badge/language-object--c-yellow.svg) ![support](https://img.shields.io/badge/support-IOS%208%2B-green.svg)
> ios端易用的内嵌JSbridge的WKWebView， 通过它，你可以在Javascript和原生之间调用彼此的函数.

### 注意

JustWebView 0.1 版本在测试阶段，但是基本的功能都已实现，可能在后面会进行微小的调节和bug修改

## 特性

1. IOS端易用，轻量且强大，侵入性低。
2. 支持以类的方式集中统一管理API
3. 支持对象API调用
4. 支持回调

## 安装

```shell
下载直接放入工程中直接使用
```

## 示例

请参考工程目录下的 `demo` 文件夹. 运行并查看示例交互.


## 如何使用

1. 新建一个类，实现你需要调用的API 

   ```objective-c
   @implementation ApiTest
   //test1 
   - (NSString *) test1:(NSString *) msg
   {
       return [msg stringByAppendingString:@"[ syn call]"];
   }
   //test9
  	- (void) test9:(NSString *) msg :(void (^)(NSString 	* 	_Nullable result,id data))completionHandler
	{
    	completionHandler(@"test2",@"323");
	}
   @end 
   ```
	##### 这里的回调函数是标准格式，如果需要有回调函数，请放在方法最后声明，并按照上述的格式使用
2. 添加API类实例到 JustWebView 

   ```objective-c
   JustWebView *webView = [[JustWebView alloc]initWithFrame:self.view.frame];
    TestFun *fun = [TestFun new];
    [webView addScriptMessageHandlerByObject:fun];
   ```

3. 在Javascript中调用原生 API.

   - 初始化 

     ```objective-c
     //在JustWebView创建初始化时默认会注入一个 javascript API （全局）
     //注入js
		- (void)beginJavascriptInsert{
		....
	 }
     //
     ```
	在html 中可以直接调用
   - 调用原生API .

     ```javascript
		//调用按钮
     <div class="btn" onclick="callNative()">call Native</div>
		
		//直接调用
     function callNative() {
        this.justToNative("testfun", "test9","['name']","callcell");
    	}
     ```
	#### 其中的justToNative是指定的js调用native的方法，这个可以自定义方法名
	#### 注意: - (void)test3:(BOOL)str string:(NSString*)title js端调用时方法名为		test3string
	####  修改宏 JUST_JS_TO_NATIVE_FUNCTION_NAME 就可以修改名字
	#### 当然也可以直接 window.webkit.messageHandlers.你的类名.postMessage（参数）来直接调用
4. 在Object-c中调用Javascript API 

    ```objective-c
       - (void)callHandler:(NSString *)methodName withData:(id)data
       - (void)callHandler:(NSString *)methodName arguments:(NSArray *)args
    ```

   

## 对象方法调用

为了更好的管理对象和方法，这边统一用一个字典保存对象和方法，这里会对对象做处理，对象会转成JustObjectModel，对象方法会转成JustMethodModel，方便后期的使用。


## 参数和回调

js可以直接调用native方法通过注入的方法（通过justToNative方法）参数最后一个是回调方法（js的方法）
在native执行之后可以回调给js.
justToNative参数可参考demo，参数是有固定顺序的请不要调用错误
#### 例子:
this.justToNative("testfun", "test9","['name']","callcell");

1:native对象名
2:native对象对应方法
3:参数list
4:callback函数

# WKUIDelegate

可以通过指定JustUIDelegate对象来自定义WKUIDelegate的相关方法


## API 介绍
可以查看注释

## 喜欢请给个star


