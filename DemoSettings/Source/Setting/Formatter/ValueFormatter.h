//
//  ValueFormatter.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 值格式化器协议。
 *
 * @discussion 定义值类型与显示字符串之间的双向转换。
 *             主要用于选择器类型的设置项，将内部值类型（如枚举、整数等）
 *             与用户界面显示的字符串进行转换。
 *             对标 Android 端 ValueFormatter<T>。
 *
 * @see SettingModel
 */
@protocol ValueFormatter <NSObject>

/**
 * @brief 将值类型转换为显示字符串。
 *
 * @param value 值对象，可能为 nil。
 *
 * @return 用于界面展示的字符串。
 */
- (NSString *)formatValue:(nullable id)value;

/**
 * @brief 将显示字符串解析为值类型。
 *
 * @param displayString 界面上的显示字符串。
 *
 * @return 解析后的值对象，解析失败时可能返回 nil。
 */
- (nullable id)parseDisplayString:(NSString *)displayString;

/**
 * @brief 获取默认值。
 *
 * @discussion 当解析失败或没有已保存值时使用。
 *
 * @return 默认值对象。
 */
- (id)defaultValue;

@end

NS_ASSUME_NONNULL_END
