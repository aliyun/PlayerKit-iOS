//
//  SettingConstants.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingItem;
@class AliPlayerController;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置菜单常量与默认项工厂。
 *
 * @discussion 集中管理设置菜单中各项的 key、可选项列表和默认值，
 *             并提供创建默认设置项列表的工厂方法。
 *             与 Android SettingConstants 概念对齐。
 *
 * @see SettingItem
 * @see SettingMenuSlot
 */
@interface SettingConstants : NSObject

/** @brief 播放相关分组（倍速、清晰度）。 */
FOUNDATION_EXPORT const NSInteger SettingGroupPlayback;

/** @brief 音频相关分组（循环、静音）。 */
FOUNDATION_EXPORT const NSInteger SettingGroupAudio;

/** @brief 显示相关分组（镜像、缩放、旋转）。 */
FOUNDATION_EXPORT const NSInteger SettingGroupDisplay;

/** @brief 设置项行高。 */
FOUNDATION_EXPORT const CGFloat SettingItemHeight;

/** @brief 设置项水平内边距。 */
FOUNDATION_EXPORT const CGFloat SettingItemHorizontalPadding;

/** @brief 设置项标题字号。 */
FOUNDATION_EXPORT const CGFloat SettingItemTitleFontSize;

/** @brief 设置项分隔线高度。 */
FOUNDATION_EXPORT const CGFloat SettingItemSeparatorHeight;

/**
 * @brief 创建默认设置项列表。
 *
 * @param controller 播放器控制器，用于绑定设置项的操作回调。
 *
 * @discussion 创建倍速、循环播放、静音三个默认设置项，
 *             并将用户操作回调绑定到控制器方法。
 *
 * @return 默认设置项数组。
 */
+ (NSArray<SettingItem *> *)defaultItemsWithController:(AliPlayerController *)controller;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
