//
//  SlotActionNotificationDelegate.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/24.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Slot 插槽操作事件通知代理协议。
 *
 * @discussion 用于解耦 Slot 插槽之间的直接方法调用（如 TopBar/BottomBar 调用 SettingMenu）。
 *             通过 SlotActionNotificationDispatcher 多播分发给所有观察者。
 *             所有回调均异步派发到主线程，避免在按钮事件处理链中同步执行重量级 UI 操作。
 *
 * @see SlotActionNotificationDispatcher
 */
@protocol SlotActionNotificationDelegate <NSObject>

@optional

/**
 * @brief 请求切换设置菜单的显示/隐藏状态。
 *
 * @discussion 通常由 TopBarSlot 的设置按钮点击触发，由 SettingMenuSlot 响应。
 */
- (void)slotDidRequestToggleSettingMenu;

/**
 * @brief 请求显示倍速选择面板。
 *
 * @discussion 通常由 BottomBarSlot 的倍速按钮点击触发，
 *             由 SettingMenuSlot 准备数据并调用 OptionPanelSlot 显示面板。
 */
- (void)slotDidRequestShowSpeedPanel;

/**
 * @brief 请求显示画质选择面板。
 *
 * @discussion 通常由 BottomBarSlot 的画质按钮点击触发，
 *             由 SettingMenuSlot 准备数据并调用 OptionPanelSlot 显示面板。
 */
- (void)slotDidRequestShowQualityPanel;

@end

NS_ASSUME_NONNULL_END
