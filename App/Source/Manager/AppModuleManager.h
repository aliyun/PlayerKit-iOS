//
//  AppModuleManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppModuleInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 动态模块发现与管理中心。
 *
 * @discussion 使用 Objective-C 运行时反射扫描所有已加载的、遵循 AppModuleProtocol
 *             且类名以"Module"结尾的类。将模块元数据收集到强类型的 AppModuleInfo 对象中，
 *             用于菜单构建和导航路由。
 *
 *             模块发现采用懒加载方式——首次访问 moduleInfoList 或
 *             handleURL:fromViewController: 时触发扫描。
 *
 *             模块按优先级降序自动排序，优先级相同时按标题升序排列。
 *
 * @warning 确保在首次访问前所有模块 Framework 已加载。
 *
 * @see AppModuleProtocol
 * @see AppModuleInfo
 * @see AppSchemaRouter
 */
@interface AppModuleManager : NSObject

/**
 * @brief 返回共享的单例实例。
 *
 * @return 共享的 AppModuleManager 实例。
 */
+ (instancetype)sharedManager;

/**
 * @brief 所有已发现的模块信息对象。
 *
 * @discussion 首次访问时通过懒加载填充。每个 AppModuleInfo 包含 title、schema、
 *             description、category、className 和 priority。
 *             按优先级降序排列，优先级相同时按标题升序排列。
 */
@property (nonatomic, strong, readonly) NSArray<AppModuleInfo *> *moduleInfoList;

/**
 * @brief 处理 Schema URL 并分发到对应的模块。
 *
 * @discussion 在已注册的模块中搜索与给定 Schema 匹配的模块。
 *             如果找到，则实例化该模块的视图控制器并将其推入导航栈。
 *             优先使用 +moduleViewControllerWithURL: 而非 +moduleViewController
 *             以传递 URL 上下文。
 *
 * @param url 要处理的 Schema URL 字符串。
 * @param viewController 提供导航上下文的源视图控制器。
 *
 * @return 如果找到并处理了匹配的模块则返回 YES，否则返回 NO。
 */
- (BOOL)handleURL:(NSString *)url fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
