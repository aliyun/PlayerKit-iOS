//
//  SlotManager+Private.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotManager.h"

@class SlotHostLayout;
@class CustomSlotType;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief SlotManager 内部接口，供 SlotHostLayout 和 AliPlayerView 使用。
 */
@interface SlotManager (Private)

/**
 * @brief 内部初始化方法（替代被禁用的 init）。
 */
- (instancetype)initInternal;

/**
 * @brief 绑定宿主布局。
 *
 * @param hostLayout 供运行时委托操作的 SlotHostLayout 实例。
 */
- (void)bindHostLayout:(SlotHostLayout *)hostLayout;

/**
 * @brief 使用已注册的 Provider 构建指定类型的插槽视图。
 *
 * @param type       要构建的插槽类型。
 * @param parentView 传递给 Provider Block 的父视图。
 *
 * @return 构建的插槽视图；如果未注册 Provider 则返回 nil。
 */
- (nullable UIView<SlotProtocol> *)buildSlotForType:(SlotType)type parentView:(UIView *)parentView;

/**
 * @brief 使用已注册的 Provider 构建自定义插槽视图。
 *
 * @param type       自定义插槽类型。
 * @param parentView 传递给 Provider Block 的父视图。
 *
 * @return 构建的插槽视图；如果未注册 Provider 则返回 nil。
 */
- (nullable UIView<SlotProtocol> *)buildCustomSlotForType:(CustomSlotType *)type parentView:(UIView *)parentView;

/**
 * @brief 获取所有已注册的自定义插槽类型（内部使用）。
 *
 * @return 已注册的自定义插槽类型数组。
 */
- (NSArray<CustomSlotType *> *)registeredCustomSlotTypes;

@end

NS_ASSUME_NONNULL_END
