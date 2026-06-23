//
//  SettingViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Demo 设置页面控制器。
 *
 * @discussion 提供声明式的分组设置列表，包含通用设置、日志配置、版本信息等。
 *             使用 Grouped UITableView 展示，支持 Button / Text / Switch / Selector 四种 Cell 样式。
 *             对标 Android 端 SettingActivity。
 *
 * @see SettingModel
 * @see SettingType
 */
@interface SettingViewController : UITableViewController

@end

NS_ASSUME_NONNULL_END
