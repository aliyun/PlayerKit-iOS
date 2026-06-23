//
//  SettingItemType.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置项类型枚举。
 *
 * @discussion 决定设置项在 UI 中的展现形式。
 *             SELECTOR 类型显示选项列表供用户选择；
 *             SWITCHER 类型显示开关控件。
 *
 * @see SettingItem
 */
typedef NS_ENUM(NSInteger, SettingItemType) {
    /** 选择器类型，点击弹出选项列表 */
    SettingItemTypeSelector = 0,

    /** 开关类型，显示 UISwitch */
    SettingItemTypeSwitcher = 1,
};

NS_ASSUME_NONNULL_END
