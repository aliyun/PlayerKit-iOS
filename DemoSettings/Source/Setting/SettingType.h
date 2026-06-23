//
//  SettingType.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @brief 设置项视图类型。
 *
 * @discussion 定义设置列表支持的所有 Cell 样式。
 *             对标 Android 端 SettingType。
 */
typedef NS_ENUM(NSInteger, SettingType) {
    /** 分组头部（映射为 UITableView section header） */
    SettingTypeHeader = 0,

    /** 可点击按钮项 */
    SettingTypeButton = 1,

    /** 纯文本展示项（title + value） */
    SettingTypeText = 2,

    /** 开关切换项（title + UISwitch） */
    SettingTypeSwitch = 3,

    /** 弹出式单选列表项（title + value + ActionSheet） */
    SettingTypeSelector = 4
};
