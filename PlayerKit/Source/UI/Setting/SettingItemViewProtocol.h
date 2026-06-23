//
//  SettingItemViewProtocol.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingItem;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置菜单中单个设置项视图的协议定义。
 *
 * @discussion 约束所有设置项视图（选择器、开关等）的基本行为，
 *             使其能够与 SettingMenuSlot 进行统一交互和管理。
 *
 * @see SettingItem
 * @see SettingSelectorItemView
 * @see SettingSwitcherItemView
 */
@protocol SettingItemViewProtocol <NSObject>

/**
 * @brief 设置项对应的根视图。
 *
 * @discussion SettingMenuSlot 通过此属性将视图添加到父容器中。
 */
@property (nonatomic, readonly) UIView *contentView;

/**
 * @brief 绑定设置项数据并刷新 UI。
 *
 * @param item 要绑定的设置项数据。
 *
 * @discussion 通常在视图初始化或首次展示时调用。
 */
- (void)bindItem:(SettingItem *)item;

/**
 * @brief 仅更新值，不触发变更回调。
 *
 * @param value 最新的设置值。
 *
 * @discussion 用于外部状态同步时更新 UI，不应触发 valueChangedBlock。
 */
- (void)updateValueOnly:(id)value;

@end

NS_ASSUME_NONNULL_END
