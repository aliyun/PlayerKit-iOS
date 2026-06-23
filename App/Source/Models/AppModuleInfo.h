//
//  AppModuleInfo.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 表示已发现模块元数据的强类型数据模型。
 *
 * @discussion 封装从遵循 AppModuleProtocol 的模块类中提取的所有元数据。
 *             以编译期类型安全替代之前基于 NSDictionary 的方式。
 *
 * @see AppModuleProtocol
 * @see AppModuleManager
 */
@interface AppModuleInfo : NSObject

/**
 * @brief 模块的显示标题。
 */
@property (nonatomic, copy, readonly) NSString *title;

/**
 * @brief 用于导航路由的 Schema URL 字符串。
 *
 * @discussion 遵循格式：@c playerkit://scenes/xxx。
 */
@property (nonatomic, copy, readonly) NSString *schema;

/**
 * @brief 模块的简要描述文本。
 *
 * @discussion 如果模块未提供描述，则可能为 nil。
 */
@property (nonatomic, copy, readonly, nullable) NSString *moduleDescription;

/**
 * @brief 用于菜单分组的分类名称。
 *
 * @discussion 如果模块未指定分类，则可能为 nil。
 *             未指定分类的模块将归入"Other"分组。
 */
@property (nonatomic, copy, readonly, nullable) NSString *category;

/**
 * @brief 用于运行时解析的模块类名。
 */
@property (nonatomic, copy, readonly) NSString *className;

/**
 * @brief 用于菜单排序的显示优先级。
 *
 * @discussion 值越大在菜单列表中越靠前。
 *             未指定时默认为 AppModulePriorityDefault (0)。
 */
@property (nonatomic, assign, readonly) NSInteger priority;

/**
 * @brief 创建包含所有元数据字段的模块信息实例。
 *
 * @param title 显示标题。
 * @param schema Schema URL 字符串。
 * @param moduleDescription 简要描述文本。
 * @param category 用于分组的分类名称。
 * @param className 模块类名。
 * @param priority 显示优先级值。
 *
 * @return 新的 AppModuleInfo 实例。
 */
+ (instancetype)infoWithTitle:(NSString *)title
                       schema:(NSString *)schema
            moduleDescription:(nullable NSString *)moduleDescription
                     category:(nullable NSString *)category
                    className:(NSString *)className
                     priority:(NSInteger)priority;

@end

NS_ASSUME_NONNULL_END
