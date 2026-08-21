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

/**
 * @brief 用户开始拖动进度条时调用。
 *
 * @discussion 通常由 BottomBarSlot 在进度条 touch down 时派发，
 *             由 SeekThumbnailSlot 响应并显示拖动预览浮层（如缩略图预览）。
 *
 * @see slotDidUpdateSeekPreview:duration:
 * @see slotDidEndSeekPreview
 */
- (void)slotDidBeginSeekPreview;

/**
 * @brief 拖动进度条期间目标位置变化时调用。
 *
 * @param targetPositionMs 拖动目标位置，单位为毫秒。
 * @param durationMs       媒体总时长，单位为毫秒。
 *
 * @discussion 在拖动期间高频调用，仅携带位置与时长信息，不携带图片对象。
 *             需要缩略图的观察者应自行通过 AliPlayerController
 *             的 requestThumbnailAtPosition: 异步请求。
 */
- (void)slotDidUpdateSeekPreview:(int64_t)targetPositionMs
                        duration:(int64_t)durationMs;

/**
 * @brief 用户结束拖动进度条时调用。
 *
 * @discussion 通常由 BottomBarSlot 在进度条 touch up / touch cancel 时派发，
 *             由 SeekThumbnailSlot 响应并隐藏拖动预览浮层。
 */
- (void)slotDidEndSeekPreview;

/**
 * @brief 请求显示章节面板。
 *
 * @discussion 通常由 BottomBarSlot 的章节按钮点击触发，
 *             由 ChapterPanelSlot 响应并显示章节列表面板。
 */
- (void)slotDidRequestShowChapterPanel;

@end

NS_ASSUME_NONNULL_END
