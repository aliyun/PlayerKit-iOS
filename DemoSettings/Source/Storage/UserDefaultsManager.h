//
//  UserDefaultsManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 基于 NSUserDefaults 的持久化存储管理工具（单例模式）。
 *
 * @discussion 提供统一的持久化存储能力，支持多种数据类型的存储与读取。
 *
 * @see LinkConstants
 * @see LinkViewController
 */
@interface UserDefaultsManager : NSObject

/**
 * @brief 获取单例实例。
 */
+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - String

/**
 * @brief 保存字符串类型的值。
 *
 * @param value 要保存的字符串。
 * @param key 存储键名。
 */
- (void)saveString:(nullable NSString *)value forKey:(NSString *)key;

/**
 * @brief 获取字符串类型的值。
 *
 * @param key 存储键名。
 *
 * @return 存储的字符串值，不存在时返回 nil。
 */
- (nullable NSString *)stringForKey:(NSString *)key;

#pragma mark - Integer

/**
 * @brief 保存整数类型的值。
 *
 * @param value 要保存的整数。
 * @param key 存储键名。
 */
- (void)saveInteger:(NSInteger)value forKey:(NSString *)key;

/**
 * @brief 获取整数类型的值。
 *
 * @param key 存储键名。
 * @param defValue 默认值，键不存在时返回。
 *
 * @return 存储的整数值或默认值。
 */
- (NSInteger)integerForKey:(NSString *)key defValue:(NSInteger)defValue;

#pragma mark - Boolean

/**
 * @brief 保存布尔类型的值。
 *
 * @param value 要保存的布尔值。
 * @param key 存储键名。
 */
- (void)saveBool:(BOOL)value forKey:(NSString *)key;

/**
 * @brief 获取布尔类型的值。
 *
 * @param key 存储键名。
 * @param defValue 默认值，键不存在时返回。
 *
 * @return 存储的布尔值或默认值。
 */
- (BOOL)boolForKey:(NSString *)key defValue:(BOOL)defValue;

#pragma mark - Float

/**
 * @brief 保存浮点类型的值。
 *
 * @param value 要保存的浮点值。
 * @param key 存储键名。
 */
- (void)saveFloat:(float)value forKey:(NSString *)key;

/**
 * @brief 获取浮点类型的值。
 *
 * @param key 存储键名。
 * @param defValue 默认值，键不存在时返回。
 *
 * @return 存储的浮点值或默认值。
 */
- (float)floatForKey:(NSString *)key defValue:(float)defValue;

#pragma mark - Remove

/**
 * @brief 删除指定键的值。
 *
 * @param key 存储键名。
 */
- (void)removeForKey:(NSString *)key;

/**
 * @brief 清空所有存储的数据。
 */
- (void)clearAll;

@end

NS_ASSUME_NONNULL_END
