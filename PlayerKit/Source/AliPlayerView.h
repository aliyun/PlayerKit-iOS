//
//  AliPlayerView.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerNotificationDelegate.h"
#import "FullscreenTransition.h"
#import "SlotManager.h"

@class AliPlayerController;
@class AliPlayerModel;
@class PlayerViewState;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器视图容器。
 *
 * @discussion 作为播放器的容器视图，负责管理 AliPlayerController 的绑定与解绑。
 *             渲染视图由插槽系统中的 PlayerSurfaceSlot 创建并管理。
 *             View 仅负责视图层管理，不涉及播放配置与生命周期控制。
 *
 * @see AliPlayerController
 */
@interface AliPlayerView : UIView <PlayerNotificationDelegate>

/** @brief 关联的播放器控制器（弱引用）。 */
@property (nonatomic, weak, readonly, nullable) AliPlayerController *controller;

/** @brief 播放器视图状态，持有跨视频保留的 UI 状态（如全屏、控制栏可见性）。 */
@property (nonatomic, strong, readonly) PlayerViewState *viewState;

/**
 * @brief 插槽管理器，用于插槽注册、可见性控制和元素级隐藏。
 *
 * @discussion 在 AliPlayerView 初始化时即创建，可在 attach: 之前
 *             预配置自定义 Provider、隐藏特定插槽或元素。
 *             默认已注册所有内置插槽 Provider 和场景可见性配置。
 */
@property (nonatomic, strong, readonly) SlotManager *slotManager;

/**
 * @brief 全屏过渡动画实现。
 *
 * @discussion 默认使用 DefaultFullscreenTransition（独立 Window 旋转方案）。
 *             可注入自定义实现以适配特殊业务场景。
 */
@property (nonatomic, strong, null_resettable) id<FullscreenTransition> fullscreenTransition;

/**
 * @brief 绑定播放器控制器并激活插槽系统。
 *
 * @param controller 要绑定的播放器控制器。
 *
 * @discussion Model 从 controller.playerModel 获取。如果控制器已配置模型，
 *             插槽系统将根据 slotManager 的注册配置和可见性设置自动构建。
 *             如需自定义插槽 Provider，请在调用此方法前通过 slotManager 配置。
 *
 * @see slotManager
 * @see detach
 */
- (void)attach:(AliPlayerController *)controller;

/**
 * @brief 解绑播放器控制器。
 *
 * @discussion 清空 controller 引用并解绑插槽系统。
 *             不会调用 controller 的 destroy 方法，控制器的生命周期由调用方自行管理。
 *
 * @see attach:
 */
- (void)detach;

/**
 * @brief 返回键事件回调。
 *
 * @discussion 当播放器内部 UI 触发返回事件（如顶部栏返回按钮点击、左边缘手势滑动）且当前不处于全屏状态时，
 *             将调用此回调通知外部。外部通过此钩子实现自定义的返回导航逻辑（如 pop、dismiss 等）。
 *             全屏状态下的返回操作由播放器内部自动处理（退出全屏），不触发此回调。
 *
 * @note 若未设置此回调，播放器将通过 responder chain 尝试默认导航行为。
 *       设置此回调后，默认行为将被替代，由调用方完全掌控返回逻辑。
 */
@property (nonatomic, copy, nullable) void (^onBackPressed)(void);

@end

NS_ASSUME_NONNULL_END
