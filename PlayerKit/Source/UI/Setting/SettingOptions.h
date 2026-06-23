//
//  SettingOptions.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 选择器选项源协议（只读）。
 *
 * @discussion 为选择器类型设置项提供可选值集合的按索引访问。
 *             实现此协议的对象为 SettingSelectorItemView 提供选项数据。
 *
 * @see SettingItem
 * @see SettingSelectorItemView
 */
@protocol SettingOptions <NSObject>

/**
 * @brief 选项数量。
 *
 * @return 可选值的个数。
 */
- (NSInteger)count;

/**
 * @brief 获取指定索引的选项值。
 *
 * @param index 选项索引，范围为 [0, count)。
 *
 * @return 该索引对应的选项值。
 */
- (id)objectAtIndex:(NSInteger)index;

@end

/**
 * @brief 基于 NSArray 的选项源实现。
 *
 * @discussion 将 NSArray 包装为符合 SettingOptions 协议的只读选项源。
 *
 * @see SettingOptions
 */
@interface ArraySettingOptions : NSObject <SettingOptions>

/**
 * @brief 通过数组创建选项源。
 *
 * @param array 选项数组，不可为 nil。
 *
 * @return 选项源实例。
 */
- (instancetype)initWithArray:(NSArray *)array NS_DESIGNATED_INITIALIZER;

/**
 * @brief 便捷工厂方法。
 *
 * @param array 选项数组。
 *
 * @return 选项源实例。
 */
+ (instancetype)optionsWithArray:(NSArray *)array;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
