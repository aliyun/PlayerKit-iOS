//
//  AppDelegate.m
//  Example
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AppDelegate.h"
#import <PlayerKit/AliPlayerKit.h>

@implementation AppDelegate

#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 应用启动后的自定义配置入口
    [AliPlayerKit setup];
    return YES;
}

@end
