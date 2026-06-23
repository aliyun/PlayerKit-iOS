//
//  SlotHostLayout.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlotHost.h"
#import "SceneType.h"
#import "SlotType.h"

@class AliPlayerController;
@class AliPlayerModel;
@class SlotManager;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 实现 SlotHost 协议的宿主容器视图。
 *
 * @discussion 管理播放器视图中所有插槽视图的生命周期。
 *             负责根据 SlotManager 中的注册和可见性配置来构建、挂载、卸载和绑定数据到插槽视图。
 *             此类为框架内部实现，外部应通过 SlotManager 进行交互。
 *
 * @see SlotHost
 * @see SlotManager
 * @see AliPlayerView
 */
@interface SlotHostLayout : UIView <SlotHost>

/** @brief 与此宿主关联的播放器控制器（弱引用，只读）。 */
@property (nonatomic, weak, readonly, nullable) AliPlayerController *controller;

/**
 * @brief 绑定播放器控制器。
 *
 * @param controller 播放器控制器实例（以弱引用持有）。
 */
- (void)bindController:(AliPlayerController *)controller;

/**
 * @brief 绑定 SlotManager，建立双向引用。
 *
 * @param slotManager 要绑定的 SlotManager 实例。
 *
 * @discussion 由 AliPlayerView 在 attach: 时调用。
 *             SlotHostLayout 持有 SlotManager 以查询可见性和构建插槽；
 *             同时将自身注册回 SlotManager 的 hostLayout 弱引用。
 */
- (void)bindSlotManager:(SlotManager *)slotManager;

/**
 * @brief 解绑控制器，卸载所有插槽。
 *
 * @discussion 对所有已挂载的插槽调用 @c onDetach，移除所有子视图，
 *             并清除内部引用。
 */
- (void)unbind;

/**
 * @brief 从 SlotManager 重建所有插槽视图。
 *
 * @discussion 卸载并移除所有现有插槽，然后按 Z 轴顺序遍历所有内置插槽类型
 *             来构建和挂载新的插槽。如果当前已绑定数据，新插槽将立即收到 @c onBindData: 回调。
 */
- (void)rebuildSlots;

/**
 * @brief 将播放数据绑定到所有已挂载的插槽。
 *
 * @param model 包含播放信息的播放器模型。
 *
 * @see unbindData
 */
- (void)bindData:(AliPlayerModel *)model;

/**
 * @brief 从所有已挂载的插槽解绑播放数据。
 *
 * @see bindData:
 */
- (void)unbindData;

/**
 * @brief 用于插槽可见性过滤的场景类型。
 *
 * @discussion 与 SlotManager 中的 SlotConfig 配合使用，确定哪些插槽应可见。
 *             默认值为 SceneTypeVOD。当场景类型变更时，插槽系统会自动重建。
 *
 * @see SceneType
 * @see SlotManager
 */
@property (nonatomic, assign) SceneType sceneType;

/**
 * @brief 返回所有当前已挂载的插槽视图。
 *
 * @return 此宿主布局管理的所有插槽视图数组。
 */
- (NSArray<UIView<SlotProtocol> *> *)allSlotViews;

/**
 * @brief 返回键事件处理回调（由 AliPlayerView 在 attach 时注入）。
 *
 * @discussion 当 Slot 通过 notifyBackPressed 上报返回事件时，
 *             SlotHostLayout 调用此 handler 通知外层。
 */
@property (nonatomic, copy, nullable) void (^backPressedHandler)(void);

@end

NS_ASSUME_NONNULL_END
