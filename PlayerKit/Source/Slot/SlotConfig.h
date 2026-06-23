//
//  SlotConfig.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlotType.h"
#import "SceneType.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 插槽可见性和行为的配置对象。
 *
 * @discussion 封装插槽的配置信息，包括插槽类型、排除的场景以及可选的可见性条件回调块。
 *             使用工厂方法创建实例。
 *
 * @see SlotType
 * @see SceneType
 */
@interface SlotConfig : NSObject

/** @brief 此配置适用的插槽类型。 */
@property (nonatomic, assign, readonly) SlotType slotType;

/**
 * @brief 应隐藏此插槽的场景类型集合。
 *
 * @discussion 包含 @c NSNumber 包装的 @c SceneType 值。
 *             如果当前场景在此集合中，则插槽不可见。
 */
@property (nonatomic, copy, readonly, nullable) NSSet<NSNumber *> *excludedScenes;

/**
 * @brief 用于动态控制插槽可见性的可选回调块。
 *
 * @discussion 设置后，此回调块将在排除场景检查之外额外执行。
 *             如果回调块返回 NO，无论场景类型如何，插槽都将被隐藏。
 */
@property (nonatomic, copy, readonly, nullable) BOOL(^visibilityCondition)(void);

/**
 * @brief 使用指定的插槽类型创建插槽配置。
 *
 * @param slotType 要配置的插槽类型。
 *
 * @return 新的插槽配置实例。
 */
+ (instancetype)configWithSlotType:(SlotType)slotType;

/**
 * @brief 使用指定的插槽类型和排除场景创建插槽配置。
 *
 * @param slotType       要配置的插槽类型。
 * @param excludedScenes @c NSNumber 包装的 @c SceneType 值集合，用于排除，或传 nil。
 *
 * @return 新的插槽配置实例。
 */
+ (instancetype)configWithSlotType:(SlotType)slotType
                    excludedScenes:(nullable NSSet<NSNumber *> *)excludedScenes;

/**
 * @brief 使用完整自定义参数创建插槽配置。
 *
 * @param slotType       要配置的插槽类型。
 * @param excludedScenes @c NSNumber 包装的 @c SceneType 值集合，用于排除，或传 nil。
 * @param condition      可选的回调块，返回 YES 表示插槽应可见。
 *
 * @return 新的插槽配置实例。
 */
+ (instancetype)configWithSlotType:(SlotType)slotType
                    excludedScenes:(nullable NSSet<NSNumber *> *)excludedScenes
               visibilityCondition:(nullable BOOL(^)(void))condition;

/**
 * @brief 判断插槽在给定场景中是否应可见。
 *
 * @param sceneType 要检查可见性的场景类型。
 *
 * @return 如果插槽在指定场景中应可见则返回 YES，否则返回 NO。
 *
 * @discussion 可见性由以下规则决定：
 *             1. 如果 @c excludedScenes 包含该场景类型，返回 NO。
 *             2. 如果 @c visibilityCondition 存在且返回 NO，返回 NO。
 *             3. 否则返回 YES。
 */
- (BOOL)isVisibleInScene:(SceneType)sceneType;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
