//
//  SettingMenuSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BasePanelSlot.h"
#import "SlotActionNotificationDelegate.h"
#import "SlotElements.h"

@class SettingItem;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置菜单插槽。
 *
 * @discussion 提供倍速、循环播放、静音等设置项，与播放器状态保持同步，
 *             并根据场景类型自动过滤不适用的设置项。
 *
 *             呈现形态随横竖屏切换：横屏为从右侧滑入的抽屉面板，竖屏为从底部升起的弹窗。
 *             由于竖屏下播放器仅占据屏幕顶部一小块区域，面板与蒙层承载在挂到窗口上的
 *             临时容器内（重写 @c panelHostView ），而非插槽自身的视图层级。
 *
 *             插槽自身位于播放器视图 z-order 最顶层（order = 100）。
 *
 * @see BasePanelSlot
 * @see SettingItem
 * @see SettingConstants
 */
@interface SettingMenuSlot : BasePanelSlot <SlotActionNotificationDelegate>

/**
 * @brief 切换设置菜单的显示/隐藏状态。
 *
 * @discussion 如果菜单当前隐藏，则以动画方式显示；如果当前显示，则以动画方式隐藏。
 *             外部插槽（如 TopBar、BottomBar）可通过此方法触发菜单。
 */
- (void)toggleMenu;

/**
 * @brief 显示设置菜单。
 *
 * @discussion 以动画方式从右侧滑入面板。显示前会自动同步播放器当前状态。
 */
- (void)showMenu;

/**
 * @brief 隐藏设置菜单。
 *
 * @discussion 以动画方式将面板滑出右侧并隐藏遮罩。
 */
- (void)hideMenu;

/**
 * @brief 获取指定 element 的设置项。
 *
 * @param element 设置项唯一标识（如 SettingMenuElementSpeed、SettingMenuElementTrackInfo）。
 * @return 对应的 SettingItem，未找到时返回 nil。
 */
- (nullable SettingItem *)settingItemForElement:(SettingMenuElement)element;

@end

NS_ASSUME_NONNULL_END
