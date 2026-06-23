//
//  LinkViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 链接配置页面控制器。
 *
 * @discussion 负责管理播放器链接配置功能，提供链接输入的列表展示、扫码入口以及数据持久化功能。
 *             支持通过手动输入或扫描二维码的方式配置视频播放链接、Vid、PlayAuth 等参数。
 *             对标 Android 端的 LinkActivity。
 *
 *             集成 FAQ：
 *             本页面依赖 DemoSettings 模块，仅用于 Demo 演示。
 *             集成时请替换为您自己的视频源配置逻辑。
 *
 * @see LinkConstants
 * @see LinkItem
 * @see UserDefaultsManager
 */
@interface LinkViewController : UIViewController

/**
 * @brief 过滤显示的配置项 key 列表。
 *
 * @discussion 如果设置此属性，则只显示指定 key 列表中的配置项。
 *             例如，直播场景仅显示 LinkKeyVideoLiveURL 对应的配置项。
 *             为 nil 时显示所有配置项。
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *filterKeys;

@end

NS_ASSUME_NONNULL_END
