//
//  LocaleProvider.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 本地化字符串提供者协议。
 *
 * @discussion 宿主 App 可实现此协议，为 PlayerKit 提供自定义翻译。
 *             当返回 nil 时，SDK 将降级到内置 .strings 文件查询。
 *
 * @see LocaleManager
 */
@protocol LocaleProvider <NSObject>

@optional

/**
 * @brief 为指定 key 返回本地化字符串。
 *
 * @discussion 返回 nil 表示不处理此 key，由 SDK 内部 fallback 机制继续解析。
 *             返回非 nil 值将直接使用，不再执行后续 fallback。
 *
 * @param key 本地化字符串的 key，对应 LocaleKeys.h 中声明的常量。
 *
 * @return 本地化后的字符串，或 nil 表示降级处理。
 *
 * @see LocaleKeys.h
 */
- (nullable NSString *)localizedStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
