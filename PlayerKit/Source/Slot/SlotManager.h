//
//  SlotManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SlotType.h"
#import "SlotProtocol.h"
#import "CustomSlotType.h"

@class SlotConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 插槽系统的统一管理入口。
 *
 * @discussion 整合插槽注册、可见性控制、元素级可见性和运行时访问能力为单一入口。
 *             通过 @c AliPlayerView.slotManager 获取实例。
 *
 *             **核心能力**：
 *             - 插槽注册：管理 SlotType → SlotProvider 的映射关系
 *             - 插槽级可见性：整体隐藏/显示某种类型的插槽
 *             - 场景级可见性：通过 SlotConfig 控制场景维度的插槽可见性
 *             - 元素级可见性：隐藏/显示插槽内部的特定 UI 元素
 *             - 运行时访问：获取已挂载的插槽视图、触发重建等
 *
 *             **使用时机**：
 *             SlotManager 在 AliPlayerView 初始化时即创建，可在 attach 之前
 *             预配置隐藏的插槽和元素。配置将在后续 rebuildSlots 时生效。
 *             默认已注册所有内置插槽 Provider 和可见性配置。用户可通过
 *             registerSlotType:provider: 覆盖默认 Provider。
 *
 * @see SlotElements
 * @see SlotHostLayout
 * @see AliPlayerView
 */
@interface SlotManager : NSObject

#pragma mark - Slot Registration

/**
 * @brief 为指定的插槽类型注册 Provider。
 *
 * @param type     插槽类型。
 * @param provider 创建插槽视图的 Provider Block。
 *
 * @discussion 如果该类型已注册过 Provider（包括默认 Provider），将被替换。
 *
 * @see unregisterSlotType:
 */
- (void)registerSlotType:(SlotType)type provider:(SlotProvider)provider;

/**
 * @brief 注销指定插槽类型的 Provider。
 *
 * @param type 要注销的插槽类型。
 */
- (void)unregisterSlotType:(SlotType)type;

/**
 * @brief 检查指定插槽类型是否已注册 Provider。
 *
 * @param type 要检查的插槽类型。
 *
 * @return 如果已注册返回 YES。
 */
- (BOOL)isRegistered:(SlotType)type;

#pragma mark - Custom Slot Registration

/**
 * @brief 为自定义插槽类型注册 Provider。
 *
 * @param type     自定义插槽类型（key + order）。
 * @param provider 创建插槽视图的 Provider Block。
 *
 * @discussion 如果相同 key 的自定义类型已注册，将被替换（order 也会更新）。
 *             自定义插槽在 rebuildSlots 时按 order 与内置插槽统一排序。
 *
 * @see unregisterCustomSlotType:
 * @see CustomSlotType
 */
- (void)registerCustomSlotType:(CustomSlotType *)type provider:(SlotProvider)provider;

/**
 * @brief 注销自定义插槽类型。
 *
 * @param type 要注销的自定义插槽类型。
 */
- (void)unregisterCustomSlotType:(CustomSlotType *)type;

/**
 * @brief 检查指定自定义插槽类型是否已注册。
 *
 * @param type 要检查的自定义插槽类型。
 *
 * @return 如果已注册返回 YES。
 */
- (BOOL)isCustomSlotRegistered:(CustomSlotType *)type;

/**
 * @brief 获取所有已注册的自定义插槽类型。
 *
 * @return 已注册的自定义插槽类型数组，未注册时返回空数组。
 */
- (NSArray<CustomSlotType *> *)customSlotTypes;

#pragma mark - Slot Visibility

/**
 * @brief 隐藏指定插槽（整体不渲染）。
 *
 * @param type 要隐藏的插槽类型。
 *
 * @discussion 被隐藏的插槽在 rebuildSlots 时不会被构建和挂载。
 *             此配置在 rebuildSlots 时生效。
 *
 * @see showSlot:
 * @see isSlotHidden:
 */
- (void)hideSlot:(SlotType)type;

/**
 * @brief 显示之前隐藏的插槽。
 *
 * @param type 要显示的插槽类型。
 *
 * @discussion 恢复插槽在 rebuildSlots 时的构建资格。
 *             需调用 rebuildSlots 才能使变更生效。
 *
 * @see hideSlot:
 */
- (void)showSlot:(SlotType)type;

/**
 * @brief 检查指定插槽是否被隐藏。
 *
 * @param type 要检查的插槽类型。
 *
 * @return 如果被隐藏返回 YES。
 */
- (BOOL)isSlotHidden:(SlotType)type;

#pragma mark - Scene-based Visibility

/**
 * @brief 为插槽类型注册场景可见性配置。
 *
 * @param config 插槽可见性配置。
 *
 * @discussion 如果相同插槽类型已存在配置，将被替换。
 *             默认已注册所有内置插槽的可见性配置（来自 DefaultSlotFactory）。
 *
 * @see SlotConfig
 * @see unregisterSlotConfigForType:
 */
- (void)registerSlotConfig:(SlotConfig *)config;

/**
 * @brief 移除指定插槽类型的场景可见性配置。
 *
 * @param slotType 要移除配置的插槽类型。
 *
 * @discussion 移除后，该插槽在所有场景下默认可见（仅受 hideSlot: 控制）。
 *
 * @see registerSlotConfig:
 */
- (void)unregisterSlotConfigForType:(SlotType)slotType;

/**
 * @brief 获取指定插槽类型的场景可见性配置。
 *
 * @param type 插槽类型。
 *
 * @return 配置对象，未配置则返回 nil。
 */
- (nullable SlotConfig *)slotConfigForType:(SlotType)type;

#pragma mark - Element Visibility

/**
 * @brief 隐藏指定插槽内的特定元素（位掩码）。
 *
 * @param mask 元素位掩码，按位或组合 SlotElements.h 中对应 Slot 的 NS_OPTIONS 常量。
 * @param type 插槽类型。
 *
 * @discussion 调用后会将对应的位加入隐藏掩码、并从显示掩码中清除。
 *             被隐藏的元素在插槽构建时不会被创建，或在运行时被隐藏，具体行为取决于各插槽的实现。
 *             对于 GestureControl 插槽，隐藏元素表示禁用对应手势。
 *
 * @see showElements:forSlot:
 * @see hiddenElementMaskForSlot:
 * @see SlotElements
 */
- (void)hideElements:(NSUInteger)mask forSlot:(SlotType)type;

/**
 * @brief 显示指定插槽内的特定元素（位掩码）。
 *
 * @param mask 要显示的元素位掩码。
 * @param type 插槽类型。
 *
 * @discussion 调用后会将对应的位加入显示掩码、并从隐藏掩码中清除。
 *             显示掩码用于覆盖 Slot 通过 onRegisterElements 声明的默认隐藏元素。
 *
 * @see hideElements:forSlot:
 * @see shownElementMaskForSlot:
 */
- (void)showElements:(NSUInteger)mask forSlot:(SlotType)type;

/**
 * @brief 替换指定插槽的隐藏元素位掩码。
 *
 * @param mask 新的隐藏元素位掩码。传 0 清除该插槽的隐藏配置。
 * @param type 插槽类型。
 *
 * @discussion 此方法替换（而非追加）指定插槽的隐藏元素配置，并清除该插槽的显示掩码。
 *
 * @see hideElements:forSlot:
 * @see hiddenElementMaskForSlot:
 */
- (void)setHiddenElementMask:(NSUInteger)mask forSlot:(SlotType)type;

/**
 * @brief 获取指定插槽的隐藏元素位掩码。
 *
 * @param type 插槽类型。
 *
 * @return 隐藏元素位掩码。无配置时返回 0。
 */
- (NSUInteger)hiddenElementMaskForSlot:(SlotType)type;

/**
 * @brief 获取指定插槽的显示元素位掩码。
 *
 * @param type 插槽类型。
 *
 * @return 显示元素位掩码。无配置时返回 0。
 *
 * @discussion 显示掩码用于覆盖 Slot 子类 onRegisterElements 声明的默认不可见元素。
 */
- (NSUInteger)shownElementMaskForSlot:(SlotType)type;

/**
 * @brief 批量设置所有插槽的隐藏元素位掩码（替换之前的配置）。
 *
 * @param config 配置字典，Key 为 @c NSNumber 包装的 SlotType，Value 为 @c NSNumber 包装的位掩码。
 *               传 nil 清空所有配置。
 *
 * @discussion 此方法会替换所有现有的隐藏元素配置，并清除所有显示掩码。
 */
- (void)setAllHiddenElementMasks:(nullable NSDictionary<NSNumber *, NSNumber *> *)config;

/**
 * @brief 清空所有元素可见性配置（隐藏掩码与显示掩码）。
 */
- (void)clearAllElementMasks;

#pragma mark - Runtime Access

/**
 * @brief 获取指定类型的已挂载插槽视图。
 *
 * @param type 要查找的插槽类型。
 *
 * @return 插槽视图，如果未挂载或宿主布局不存在则返回 nil。
 *
 * @discussion 只有在 attach 之后才能获取到有效视图。
 */
- (nullable UIView<SlotProtocol> *)slotViewForType:(SlotType)type;

/**
 * @brief 重建所有插槽。
 *
 * @discussion 根据当前注册配置和可见性设置重新构建所有插槽视图。
 */
- (void)rebuildSlots;

/**
 * @brief 清空所有配置（注册、隐藏插槽、隐藏元素、场景配置）并重新注册默认值。
 *
 * @discussion 重置 SlotManager 到初始状态。不会触发 rebuildSlots。
 */
- (void)clearAll;

#pragma mark - Unavailable

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
