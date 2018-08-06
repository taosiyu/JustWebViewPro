//
//  ViewController.m
//  JustWebViewPro
//
//  Created by Assassin on 2018/8/2.
//  Copyright © 2018年 PeachRain. All rights reserved.
//

#import "ViewController.h"
#import "JustWebView.h"
#import "TestFun.h"

@interface ViewController ()

@property(nonatomic,strong)JustWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化
    self.webView = [[JustWebView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.webView];
    
    
    //加载html
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:@"test"
                                                          ofType:@"html"];
    NSString * htmlContent = [NSString stringWithContentsOfFile:htmlPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    //创建对象并注册
    TestFun *fun = [TestFun new];
    [self.webView addScriptMessageHandlerByObject:fun];
    [self.webView loadHTMLString:htmlContent baseURL:baseURL];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
