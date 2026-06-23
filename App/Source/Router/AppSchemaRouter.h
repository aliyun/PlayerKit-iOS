//
//  AppSchemaRouter.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 应用程序基于 Schema 的导航路由器。
 *
 * @discussion 提供统一的导航入口。首先尝试通过 AppModuleManager 进行内部模块导航。
 *             如果未找到匹配的模块，则尝试将 Schema 作为外部 URL 打开。
 *             如果所有路由尝试均失败，则显示错误提示。
 *
 * @see AppModuleManager
 */
@interface AppSchemaRouter : NSObject

/**
 * @brief 导航到 Schema URL 指定的目标。
 *
 * @discussion 路由优先级：
 *             1. 通过 AppModuleManager 进行内部模块路由。
 *             2. 通过 UIApplication 打开外部 URL。
 *             3. 如果两者均失败则显示错误提示。
 *
 * @param schema 用于导航的 Schema URL 字符串。
 * @param viewController 提供导航上下文的源视图控制器。
 *
 * @warning 必须在主线程上调用。
 */
+ (void)navigateToSchema:(NSString *)schema fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
