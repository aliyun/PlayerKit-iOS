//
//  GestureControlSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

@class GestureControlSlot;
@class GestureNotificationDispatcher;

#pragma mark - GestureControlSlotConfig

/**
 * @brief 手势控制插槽的配置对象，用于控制各手势的启用/禁用。
 *
 * @discussion 允许对手势控制插槽识别的手势进行细粒度控制。
 *             所有手势默认启用。此配置独立于基于场景类型的过滤逻辑，
 *             场景类型过滤会根据当前播放场景自动应用。
 *
 * @see GestureControlSlot
 */
@interface GestureControlSlotConfig : NSObject <NSCopying>

/** @brief 是否启用单击手势。默认 YES。 */
@property (nonatomic, assign) BOOL singleTapEnabled;

/** @brief 是否启用双击手势。默认 YES。 */
@property (nonatomic, assign) BOOL doubleTapEnabled;

/** @brief 是否启用长按手势。默认 YES。 */
@property (nonatomic, assign) BOOL longPressEnabled;

/** @brief 是否启用水平拖动手势（进度拖拽）。默认 YES。 */
@property (nonatomic, assign) BOOL horizontalDragEnabled;

/** @brief 是否启用左侧垂直拖动手势（亮度调节）。默认 YES。 */
@property (nonatomic, assign) BOOL leftVerticalDragEnabled;

/** @brief 是否启用右侧垂直拖动手势（音量调节）。默认 YES。 */
@property (nonatomic, assign) BOOL rightVerticalDragEnabled;

/**
 * @brief 创建默认配置，所有手势均启用。
 *
 * @return 所有属性均为 YES 的新配置实例。
 */
+ (instancetype)defaultConfig;

@end

#pragma mark - GestureControlSlotDelegate

/**
 * @brief 手势控制插槽的事件代理协议。
 *
 * @discussion 所有方法均为可选。当播放区域内检测到手势时通知代理。
 *             手势检测会遵循场景类型和配置的过滤规则。
 *
 * @see GestureControlSlot
 * @see GestureControlSlotConfig
 */
@protocol GestureControlSlotDelegate <NSObject>

@optional

#pragma mark - Tap Gestures

/**
 * @brief 检测到单击手势时调用。
 *
 * @param slot  检测到手势的手势控制插槽。
 * @param point 单击位置（插槽坐标系）。
 *
 * @discussion 通常用于切换控制面板的显隐。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didDetectSingleTapAtPoint:(CGPoint)point;

/**
 * @brief 检测到双击手势时调用。
 *
 * @param slot  检测到手势的手势控制插槽。
 * @param point 双击位置（插槽坐标系）。
 *
 * @discussion 通常用于切换播放/暂停状态。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didDetectDoubleTapAtPoint:(CGPoint)point;

#pragma mark - Long Press Gestures

/**
 * @brief 长按手势开始时调用。
 *
 * @param slot  检测到手势的手势控制插槽。
 * @param point 长按位置（插槽坐标系）。
 *
 * @discussion 通常用于激活倍速播放（如 2x 倍速）。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didBeginLongPressAtPoint:(CGPoint)point;

/**
 * @brief 长按手势结束时调用。
 *
 * @param slot 检测到手势的手势控制插槽。
 *
 * @discussion 通常用于恢复正常播放速度。
 */
- (void)gestureControlSlotDidEndLongPress:(GestureControlSlot *)slot;

#pragma mark - Horizontal Drag Gestures (Progress Seeking)

/**
 * @brief 水平拖动手势开始时调用。
 *
 * @param slot  检测到手势的手势控制插槽。
 * @param point 拖动起始位置（插槽坐标系）。
 *
 * @discussion 通常用于开始快进/快退预览。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didBeginHorizontalDragAtPoint:(CGPoint)point;

/**
 * @brief 水平拖动手势更新时调用。
 *
 * @param slot         检测到手势的手势控制插槽。
 * @param deltaPercent 增量拖动距离占插槽宽度的百分比。
 *                     正值表示向右拖动，负值表示向左拖动。
 *                     范围通常为 -1.0 到 1.0。
 *
 * @discussion 通常用于更新快进/快退进度预览。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didUpdateHorizontalDragWithDelta:(CGFloat)deltaPercent;

/**
 * @brief 水平拖动手势结束时调用。
 *
 * @param slot 检测到手势的手势控制插槽。
 *
 * @discussion 通常用于提交 Seek 操作。
 */
- (void)gestureControlSlotDidEndHorizontalDrag:(GestureControlSlot *)slot;

#pragma mark - Left Vertical Drag Gestures (Brightness)

/**
 * @brief 左侧垂直拖动手势开始时调用。
 *
 * @param slot  检测到手势的手势控制插槽。
 * @param point 拖动起始位置（插槽坐标系）。
 *
 * @discussion 通常用于开始亮度调节。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didBeginLeftVerticalDragAtPoint:(CGPoint)point;

/**
 * @brief 左侧垂直拖动手势更新时调用。
 *
 * @param slot           检测到手势的手势控制插槽。
 * @param deltaPercent   增量拖动距离占插槽高度的百分比。
 *                       负值表示向上拖动（增加亮度）。
 * @param currentPercent 应用增量后的当前亮度值（0.0 到 1.0）。
 *
 * @discussion 通常用于调节屏幕亮度。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot
didUpdateLeftVerticalDragWithDelta:(CGFloat)deltaPercent
            currentPercent:(CGFloat)currentPercent;

/**
 * @brief 左侧垂直拖动手势结束时调用。
 *
 * @param slot 检测到手势的手势控制插槽。
 *
 * @discussion 通常用于结束亮度调节。
 */
- (void)gestureControlSlotDidEndLeftVerticalDrag:(GestureControlSlot *)slot;

#pragma mark - Right Vertical Drag Gestures (Volume)

/**
 * @brief 右侧垂直拖动手势开始时调用。
 *
 * @param slot  检测到手势的手势控制插槽。
 * @param point 拖动起始位置（插槽坐标系）。
 *
 * @discussion 通常用于开始音量调节。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot didBeginRightVerticalDragAtPoint:(CGPoint)point;

/**
 * @brief 右侧垂直拖动手势更新时调用。
 *
 * @param slot           检测到手势的手势控制插槽。
 * @param deltaPercent   增量拖动距离占插槽高度的百分比。
 *                       负值表示向上拖动（增加音量）。
 * @param currentPercent 应用增量后的当前音量值（0.0 到 1.0）。
 *
 * @discussion 通常用于调节系统音量。
 */
- (void)gestureControlSlot:(GestureControlSlot *)slot
didUpdateRightVerticalDragWithDelta:(CGFloat)deltaPercent
            currentPercent:(CGFloat)currentPercent;

/**
 * @brief 右侧垂直拖动手势结束时调用。
 *
 * @param slot 检测到手势的手势控制插槽。
 *
 * @discussion 通常用于结束音量调节。
 */
- (void)gestureControlSlotDidEndRightVerticalDrag:(GestureControlSlot *)slot;

@end

#pragma mark - GestureControlSlot

/**
 * @brief 播放器 UI 的手势控制插槽。
 *
 * @discussion 在播放区域内检测和分发手势事件。
 *             支持单击、双击、长按、水平拖动和垂直拖动（左/右侧）手势。
 *
 *             手势的可用性会根据当前场景类型（VOD、Live、VideoList、
 *             Restricted、Minimal）和配置对象自动过滤。
 *
 * @see GestureControlSlotDelegate
 * @see GestureControlSlotConfig
 * @see BaseSlot
 */
@interface GestureControlSlot : BaseSlot

/**
 * @brief 接收手势事件回调的代理。
 *
 * @discussion 以 weak 引用持有以避免循环引用。
 *             在附加插槽之前设置此属性以接收手势通知。
 */
@property (nonatomic, weak, nullable) id<GestureControlSlotDelegate> delegate;

/**
 * @brief 控制各手势启用状态的配置对象。
 *
 * @discussion 修改后立即生效。设置为 nil 会恢复默认配置（所有手势启用）。
 *             赋值时会执行 copy。
 */
@property (nonatomic, copy, null_resettable) GestureControlSlotConfig *config;

/**
 * @brief 手势事件多播通知分发器。
 *
 * @discussion 用于将手势事件分发给内部订阅者（如 CenterDisplaySlot）。
 *             与 delegate 共存：delegate 用于外部自定义逻辑，
 *             gestureDispatcher 用于内部插槽间通信。
 *
 * @see GestureNotificationDispatcher
 * @see GestureNotificationDelegate
 */
@property (nonatomic, strong, readonly) GestureNotificationDispatcher *gestureDispatcher;

@end

NS_ASSUME_NONNULL_END
