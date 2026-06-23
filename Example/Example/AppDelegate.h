//
//  AppDelegate.h
//  Example
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * @brief 应用程序入口代理类。
 *
 * @discussion 负责应用程序生命周期管理，包括启动初始化、
 *             窗口创建和根视图控制器设置。
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

/**
 * @brief 应用程序主窗口。
 *
 * @discussion 在 application:didFinishLaunchingWithOptions: 中创建并配置。
 */
@property (nonatomic, strong) UIWindow *window;

@end
