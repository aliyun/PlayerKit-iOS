//
//  BottomBarSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

@class GestureNotificationDispatcher;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器 UI 的底部控制栏插槽。
 *
 * @discussion 显示包含播放/暂停按钮、进度滑块和时间标签的底部栏。
 *             定位于播放器视图底部，带有半透明背景。
 *             支持单击手势 toggle 显隐，以及 3 秒自动隐藏。
 *
 * @see BaseSlot
 * @see SlotType
 */
@interface BottomBarSlot : BaseSlot

/**
 * @brief 手势事件分发器（由宿主注入）。
 *
 * @discussion 设置时自动注册为观察者，置 nil 时自动取消注册。
 *             由 SlotHostLayout.wireGestureNotifications 在所有插槽挂载后注入。
 */
@property (nonatomic, weak, nullable) GestureNotificationDispatcher *gestureDispatcher;

@end

NS_ASSUME_NONNULL_END
