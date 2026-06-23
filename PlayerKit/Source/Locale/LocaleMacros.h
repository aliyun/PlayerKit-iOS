//
//  LocaleMacros.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#ifndef LocaleMacros_h
#define LocaleMacros_h

#import "LocaleManager.h"

/**
 * @brief 本地化字符串查询宏。
 *
 * @discussion 用于在 SDK 内部快速获取本地化字符串，按 Resolution Chain 解析。
 *
 * @param key LocaleKeys.h 中声明的字符串常量。
 */
#define LocalizedString(key) \
    [[LocaleManager sharedManager] localizedStringForKey:(key)]

/**
 * @brief 带格式化参数的本地化字符串宏。
 *
 * @discussion 先查询本地化格式串，再用 printf 风格参数格式化。
 *
 * @param key LocaleKeys.h 中声明的格式串常量。
 * @param ... 格式化参数。
 */
#define LocalizedFormat(key, ...) \
    [NSString stringWithFormat:LocalizedString(key), ##__VA_ARGS__]

#endif /* LocaleMacros_h */
