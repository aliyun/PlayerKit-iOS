//
//  AppMenuConfig.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppMenuItem;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 首页菜单配置管理器。
 *
 * @discussion 汇总 AppModuleManager 中所有已注册的模块信息，
 *             按分类组织为适合 UITableView 展示的结构化 Section 布局。
 *
 * @see AppModuleManager
 * @see AppHomeViewController
 */
@interface AppMenuConfig : NSObject

/**
 * @brief 返回首页整理好的菜单 Section 列表。
 *
 * @discussion 每个内层数组代表一个包含 AppMenuItem 对象的 Section。
 *             每个 Section 的第一项通常是标题项 (AppMenuItemTypeTitle)，
 *             后面跟着可导航项 (AppMenuItemTypeItem)。
 *
 * @return 按分类分组的 AppMenuItem 对象二维数组。
 */
- (NSArray<NSArray<AppMenuItem *> *> *)menuSections;

@end

NS_ASSUME_NONNULL_END
