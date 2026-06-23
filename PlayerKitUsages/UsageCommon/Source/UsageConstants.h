//
//  UsageConstants.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Module Category

/**
 * @brief 用法示例模块的模块分类名称。
 *
 * @discussion 在 App 模块系统中注册用法示例模块时用作显示分类。
 */
FOUNDATION_EXPORT NSString * const UsageModuleCategory;

#pragma mark - Schema

/**
 * @brief 用法示例模块的 Schema 主机名。
 *
 * @discussion 用作所有用法示例模块 URL Schema 路由中的 host 部分。
 */
FOUNDATION_EXPORT NSString * const UsageSchemaHost;

NS_ASSUME_NONNULL_END
