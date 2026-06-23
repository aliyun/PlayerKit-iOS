//
//  AppHomeViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 显示模块菜单列表的首页视图控制器。
 *
 * @discussion 展示基于 UITableView 的菜单界面，数据来源于 AppMenuConfig。
 *             支持按分类分组的 Section 标题，选中菜单项时通过 AppSchemaRouter 导航到对应模块。
 *
 * @see AppMenuConfig
 * @see AppSchemaRouter
 */
@interface AppHomeViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
