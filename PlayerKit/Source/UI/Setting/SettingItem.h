//
//  SettingItem.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingItemType.h"
#import "SettingOptions.h"
#import "SceneType.h"
#import "SlotElements.h"

NS_ASSUME_NONNULL_BEGIN

@class SettingItem;

/**
 * @brief 设置项值变更回调 Block。
 *
 * @param item     当前设置项。
 * @param newValue 新的值。
 */
typedef void (^SettingValueChangedBlock)(SettingItem *item, id newValue);

/**
 * @brief 设置项值格式化 Block。
 *
 * @param value 原始值。
 *
 * @return 用于 UI 显示的字符串。
 */
typedef NSString * _Nonnull (^SettingFormatterBlock)(id value);

/**
 * @brief 设置项数据模型。
 *
 * @discussion 描述设置菜单中的单个配置项，包括标识、标题、类型、当前值、
 *             可选值列表、值变更回调和格式化器。
 *             与 Android SettingItem 概念对齐。
 *
 * @see SettingItemType
 * @see SettingOptions
 */
@interface SettingItem : NSObject

/** @brief 设置项唯一标识，对应 SettingMenuElement 位掩码中的某一位。 */
@property (nonatomic, assign, readonly) SettingMenuElement element;

/** @brief 设置项显示标题。 */
@property (nonatomic, copy, readonly) NSString *title;

/** @brief 设置项类型，决定 UI 展示形式。 */
@property (nonatomic, assign, readonly) SettingItemType type;

/** @brief 当前选中的值。 */
@property (nonatomic, strong, nullable) id currentValue;

/** @brief 可选值列表，仅 Selector 类型使用。 */
@property (nonatomic, strong, nullable) id<SettingOptions> options;

/** @brief 设置项所属分组索引，相同 group 值的项在竖屏 UI 中共享圆角卡片背景。 */
@property (nonatomic, assign) NSInteger group;

/** @brief 支持的场景类型集合，为 nil 表示所有场景均支持。 */
@property (nonatomic, copy, nullable) NSIndexSet *supportedScenes;

/** @brief 值变更回调，用户修改设置时触发。 */
@property (nonatomic, copy, nullable) SettingValueChangedBlock valueChangedBlock;

/** @brief 值格式化器，将 currentValue 转为显示字符串。 */
@property (nonatomic, copy, nullable) SettingFormatterBlock formatterBlock;

/**
 * @brief 创建设置项。
 *
 * @param element      唯一标识，对应 SettingMenuElement 中的某一位。
 * @param title        显示标题。
 * @param type         设置项类型。
 * @param initialValue 初始值，可为 nil。
 *
 * @return 设置项实例。
 */
- (instancetype)initWithElement:(SettingMenuElement)element
                          title:(NSString *)title
                           type:(SettingItemType)type
                   initialValue:(nullable id)initialValue NS_DESIGNATED_INITIALIZER;

/**
 * @brief 获取当前值的格式化显示文本。
 *
 * @discussion 若设置了 formatterBlock 则使用格式化结果；
 *             否则使用 description 方法。
 *
 * @return 用于 UI 显示的字符串。
 */
- (NSString *)displayValue;

/**
 * @brief 判断该设置项是否支持指定场景。
 *
 * @param sceneType 场景类型。
 *
 * @return 若 supportedScenes 为 nil（支持所有场景）或包含该场景则返回 YES。
 */
- (BOOL)isSupportedInScene:(SceneType)sceneType;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
