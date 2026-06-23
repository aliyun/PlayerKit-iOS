//
//  AppMenuItem.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 菜单项类型枚举。
 *
 * @discussion 区分 Section 标题项和可导航的菜单项。
 */
typedef NS_ENUM(NSInteger, AppMenuItemType) {
    /** Section 标题，用作分组头部。 */
    AppMenuItemTypeTitle = 0,
    
    /** 支持 Schema 路由的可导航菜单项。 */
    AppMenuItemTypeItem
};

/**
 * @brief 表示单个菜单条目的数据模型。
 *
 * @discussion 由 AppMenuConfig 和 AppHomeViewController 使用，用于描述首页菜单结构。
 *             支持两种类型：Section 标题和基于 Schema 导航的可操作项。
 *
 * @see AppMenuConfig
 * @see AppHomeViewController
 */
@interface AppMenuItem : NSObject

/**
 * @brief 此菜单项的类型。
 *
 * @discussion 决定该项的显示方式以及是否可交互。
 */
@property (nonatomic, assign, readonly) AppMenuItemType type;

/**
 * @brief 菜单项的显示标题。
 */
@property (nonatomic, copy, readonly) NSString *title;

/**
 * @brief 用于导航路由的 Schema URL 字符串。
 *
 * @discussion 仅当 type 为 AppMenuItemTypeItem 时适用。
 *             由 AppSchemaRouter 用于导航到目标模块。
 */
@property (nonatomic, copy, readonly, nullable) NSString *schema;

/**
 * @brief 菜单项的描述文本。
 *
 * @discussion 提供显示在标题下方的补充说明信息。
 *             仅当 type 为 AppMenuItemTypeItem 时适用。
 */
@property (nonatomic, copy, readonly, nullable) NSString *itemDescription;

/**
 * @brief 创建 Section 标题项。
 *
 * @param title Section 标题文本。
 *
 * @return 类型为 AppMenuItemTypeTitle 的新 AppMenuItem 实例。
 */
+ (instancetype)titleItemWithTitle:(NSString *)title;

/**
 * @brief 创建可导航的菜单项。
 *
 * @param title 显示标题。
 * @param schema 用于导航路由的 Schema URL。
 * @param description 菜单项的简要描述。
 *
 * @return 类型为 AppMenuItemTypeItem 的新 AppMenuItem 实例。
 */
+ (instancetype)menuItemWithTitle:(NSString *)title
                           schema:(NSString *)schema
                      description:(nullable NSString *)description;

@end

NS_ASSUME_NONNULL_END
