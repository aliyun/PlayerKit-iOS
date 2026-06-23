//
//  CenterDisplaySlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

@class GestureNotificationDispatcher;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 中心显示插槽。
 *
 * @discussion 在播放器中心区域显示手势操作的状态提示，包括：
 *             - 倍速提示：长按时显示倍速播放文案，松开后隐藏。
 *             - 亮度提示：左侧垂直拖动时显示亮度图标、进度条和百分比。
 *             - 音量提示：右侧垂直拖动时显示音量图标、进度条和百分比。
 *
 *             三种提示互斥，同一时间只显示一种。
 *             遵循 GestureNotificationDelegate 接收手势事件通知。
 *
 *             依赖：由 SlotHostLayout 在 rebuildSlots 后自动注入 gestureDispatcher。
 *
 *             可见性规则：在 Minimal 场景中不可见。
 *
 * @see BaseSlot
 * @see GestureNotificationDelegate
 * @see GestureControlSlot
 */
@interface CenterDisplaySlot : BaseSlot

/**
 * @brief 手势事件分发器（由宿主注入）。
 *
 * @discussion 设置时自动注册为观察者，置 nil 时自动取消注册。
 *             由 SlotHostLayout.wireGestureNotifications 在所有插槽挂载后注入，
 *             消除了对插槽加载顺序的依赖。
 */
@property (nonatomic, weak, nullable) GestureNotificationDispatcher *gestureDispatcher;

@end

NS_ASSUME_NONNULL_END
