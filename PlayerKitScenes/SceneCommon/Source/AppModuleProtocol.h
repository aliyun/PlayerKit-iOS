//
//  AppModuleProtocol.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 默认模块优先级值。
 *
 * @discussion 未显式指定优先级的模块将使用此默认值 (0)。
 *             值越大在菜单列表中越靠前。
 */
static const NSInteger AppModulePriorityDefault = 0;

/**
 * @brief 定义可动态发现模块契约的协议。
 *
 * @discussion 遵循此协议的类将在运行时通过 Objective-C 反射被 AppModuleManager 自动发现。
 *             类名必须以"Module"后缀结尾。
 *
 *             必需方法提供用于菜单构建的模块元数据：
 *             - 标题、Schema URL、描述和分类。
 *             - 用于创建模块主视图控制器的工厂方法。
 *
 *             可选方法支持自定义功能，如：
 *             - 感知 URL 的视图控制器创建，用于传递导航上下文。
 *             - 菜单显示的优先级排序。
 *
 * @see AppModuleManager
 * @see AppModuleInfo
 */
@protocol AppModuleProtocol <NSObject>

@required

/**
 * @brief 返回此模块的显示标题。
 *
 * @return 在菜单中显示的本地化或硬编码标题字符串。
 */
+ (NSString *)moduleTitle;

/**
 * @brief 返回用于导航路由的 Schema URL。
 *
 * @discussion Schema 遵循格式：@c playerkit://scenes/xxx。
 *             由 AppSchemaRouter 用于分发导航请求。
 *
 * @return 唯一标识此模块的 Schema URL 字符串。
 */
+ (NSString *)moduleSchema;

/**
 * @brief 返回用于菜单分组的分类名称。
 *
 * @discussion 具有相同分类的模块在首页归入同一 Section。
 *
 * @return 分类字符串（例如 @"播放场景"、@"工具"）。
 */
+ (NSString *)moduleCategory;

/**
 * @brief 创建并返回模块的主视图控制器。
 *
 * @return 此模块的新 UIViewController 实例。
 */
+ (UIViewController *)moduleViewController;

@optional

/**
 * @brief 返回此模块的简要描述。
 *
 * @return 在菜单中作为副标题显示的简短描述。未实现时不显示副标题。
 */
+ (NSString *)moduleDescription;

/**
 * @brief 创建带有 URL 上下文的视图控制器用于导航。
 *
 * @discussion 当需要将 URL 参数传递给目标视图控制器时，
 *             优先使用此方法而非 +moduleViewController。
 *
 * @param url 包含查询参数的完整 Schema URL 字符串。
 *
 * @return 配置了 URL 上下文的新 UIViewController 实例。
 */
+ (UIViewController *)moduleViewControllerWithURL:(NSString *)url;

/**
 * @brief 返回用于菜单排序的显示优先级。
 *
 * @discussion 值越大在菜单中越靠前。未实现此方法的模块默认为
 *             AppModulePriorityDefault (0)。
 *
 * @return 整数优先级值。
 */
+ (NSInteger)modulePriority;

@end

NS_ASSUME_NONNULL_END
