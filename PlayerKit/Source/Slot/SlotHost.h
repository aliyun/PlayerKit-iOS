//
//  SlotHost.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlotProtocol.h"
#import "SlotType.h"
#import "SceneType.h"

@class AliPlayerController;
@class AliPlayerModel;
@class PlayerStateStore;
@class PlayerViewState;
@class SlotManager;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 管理插槽视图的插槽宿主协议。
 *
 * @discussion 插槽宿主提供容器视图、当前播放器模型、播放器控制器，
 *             以及为播放器画面设置渲染视图的能力。此协议由 SlotHostLayout 实现。
 *
 * @see SlotHostLayout
 * @see SlotProtocol
 */
@protocol SlotHost <NSObject>

/**
 * @brief 返回宿主容器视图。
 *
 * @return 承载所有插槽视图的 UIView。
 */
- (UIView *)hostView;

/**
 * @brief 返回当前播放器模型（如可用）。
 *
 * @return 当前的 AliPlayerModel，如果未绑定数据则返回 nil。
 */
- (nullable AliPlayerModel *)model;

/**
 * @brief 与此宿主关联的播放器控制器。
 *
 * @discussion 插槽可以使用控制器查询播放状态并发出播放命令（play、pause、seekTo: 等）。
 *             如果当前未绑定控制器则返回 nil。
 */
@property (nonatomic, weak, readonly, nullable) AliPlayerController *controller;

/**
 * @brief 提供当前播放状态只读访问的状态存储。
 *
 * @discussion 插槽可以使用此属性观察和响应播放状态变化，
 *             而无需通过控制器。如果当前未绑定控制器则返回 nil。
 *             与 Android SlotHost.getPlayerStateStore() 对齐。
 *
 * @see PlayerStateStore
 * @see AliPlayerController
 */
@property (nonatomic, strong, readonly, nullable) PlayerStateStore *playerStateStore;

/**
 * @brief 提供视图层级状态只读访问的状态存储。
 *
 * @discussion 插槽可以使用此属性读取全屏模式、控制栏可见性等 UI 状态。
 *             与 playerStateStore 不同，viewState 跨视频切换保留。
 *
 * @see PlayerViewState
 */
@property (nonatomic, strong, readonly, nullable) PlayerViewState *viewState;

/**
 * @brief 为底层播放器设置渲染视图。
 *
 * @param renderView 用于视频渲染的视图，或传 nil 以清除。
 *
 * @discussion 此方法由 PlayerSurfaceSlot 调用，
 *             用于向播放器控制器提供渲染视图。
 *             与 Android ISurfaceManager.setDisplayView() 对齐。
 *
 * @see AliPlayerController
 */
- (void)setRenderView:(nullable UIView *)renderView;

/**
 * @brief 解散插槽视图，将其从宿主管理和视图层级中移除。
 *
 * @discussion 宿主将对插槽调用 onDetach，将其从内部跟踪中移除，
 *             并从父视图中移除。确保生命周期管理的一致性。
 *
 * @param slotView 要解散的插槽视图。
 */
- (void)dismissSlotView:(UIView<SlotProtocol> *)slotView;

/**
 * @brief 返回所有当前已挂载的插槽视图。
 *
 * @return 此宿主管理的所有插槽视图数组。
 *
 * @discussion 可用于插槽间通信，例如 CenterDisplaySlot 通过此方法
 *             查找 GestureControlSlot 并注册为其通知观察者。
 */
- (NSArray<UIView<SlotProtocol> *> *)allSlotViews;

/**
 * @brief 根据插槽类型返回对应的已挂载插槽视图。
 *
 * @param slotType 要查找的插槽类型。
 *
 * @return 对应类型的插槽视图，如果该类型未挂载则返回 nil。
 *
 * @discussion 提供 O(1) 的类型化插槽查找，避免遍历 allSlotViews + isKindOfClass 模式。
 *             插槽间通信的首选方式。
 */
- (nullable UIView<SlotProtocol> *)slotViewForType:(SlotType)slotType;

/**
 * @brief 插槽管理器，提供元素级可见性查询。
 *
 * @discussion 插槽可通过此属性查询当前的隐藏元素配置，
 *             以决定是否创建或显示特定的子元素。
 *
 * @see SlotManager
 * @see SlotElements
 */
@property (nonatomic, strong, readonly, nullable) SlotManager *slotManager;

/**
 * @brief 当前场景类型。
 *
 * @discussion 由 AliPlayerView.attach: 在 rebuildSlots 之前写入到 SlotHostLayout，
 *             因此 sceneType 在所有 slot 的 onAttach: 之前即已就绪，整个 slot 生命周期内稳定可读。
 *             slot 应优先通过此属性读取场景类型，而不是经由 host.model.sceneType 链式访问，
 *             避免在 model 尚未绑定时返回 nil 透传出的隐性 SceneTypeVOD（0）默认值。
 *
 * @see SceneType
 */
@property (nonatomic, assign, readonly) SceneType sceneType;

/**
 * @brief 通知宿主：返回键被按下（非全屏状态）。
 *
 * @discussion 当插槽内部 UI 触发返回事件（如顶部栏返回按钮、左边缘手势）且当前不处于全屏状态时，
 *             插槽调用此方法通知宿主。宿主将事件传递给 AliPlayerView 的 onBackPressed 回调。
 *             若回调未设置，宿主执行默认的 responder chain 导航行为。
 */
- (void)notifyBackPressed;

@end

NS_ASSUME_NONNULL_END
