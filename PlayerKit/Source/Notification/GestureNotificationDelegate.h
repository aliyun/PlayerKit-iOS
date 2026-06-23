//
//  GestureNotificationDelegate.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 手势事件通知代理协议。
 *
 * @discussion 定义接收播放器手势控制状态变化的回调方法。
 *             由 GestureNotificationDispatcher 多播分发给所有观察者。
 *             所有回调均在主线程上派发。
 *
 *             回调参数聚焦于「显示所需的数据」，而非手势的原始坐标信息。
 *
 * @see GestureNotificationDispatcher
 * @see GestureControlSlot
 */
@protocol GestureNotificationDelegate <NSObject>

@optional

#pragma mark - Single Tap

/**
 * @brief 单击手势触发时调用。
 *
 * @discussion 通常用于切换控制栏（TopBar / BottomBar）的显示和隐藏。
 */
- (void)gestureDidSingleTap;

#pragma mark - Long Press (Speed)

/**
 * @brief 长按手势开始时调用（倍速播放激活）。
 *
 * @discussion 通常用于在屏幕中心显示倍速播放提示。
 */
- (void)gestureDidBeginLongPress;

/**
 * @brief 长按手势结束时调用（倍速播放恢复）。
 *
 * @discussion 通常用于隐藏倍速播放提示。
 */
- (void)gestureDidEndLongPress;

#pragma mark - Left Vertical Drag (Brightness)

/**
 * @brief 左侧垂直拖动更新时调用（亮度调节中）。
 *
 * @param currentPercent 当前亮度值，范围 0.0 ~ 1.0。
 *
 * @discussion 通常用于在屏幕中心显示亮度进度条和百分比。
 */
- (void)gestureDidUpdateBrightnessWithPercent:(CGFloat)currentPercent;

/**
 * @brief 左侧垂直拖动结束时调用（亮度调节结束）。
 *
 * @discussion 通常用于隐藏亮度调节提示。
 */
- (void)gestureDidEndBrightnessAdjust;

#pragma mark - Right Vertical Drag (Volume)

/**
 * @brief 右侧垂直拖动更新时调用（音量调节中）。
 *
 * @param currentPercent 当前音量值，范围 0.0 ~ 1.0。
 *
 * @discussion 通常用于在屏幕中心显示音量进度条和百分比。
 */
- (void)gestureDidUpdateVolumeWithPercent:(CGFloat)currentPercent;

/**
 * @brief 右侧垂直拖动结束时调用（音量调节结束）。
 *
 * @discussion 通常用于隐藏音量调节提示。
 */
- (void)gestureDidEndVolumeAdjust;

@end

NS_ASSUME_NONNULL_END
