//
//  SceneLiveViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 直播场景视图控制器。
 *
 * @discussion 展示直播流播放场景。使用 SceneTypeLive 场景类型控制插槽可见性，
 *             自动隐藏 seek bar、进度条等不适用于直播的控件。
 *             直播地址从 UserDefaultsManager 设置中读取，未配置时弹窗引导用户扫码配置。
 *
 *             集成 FAQ：
 *             本示例依赖 DemoSettings 模块，集成时请：
 *             1. 移除 DemoSettings 依赖（仅用于 Demo 演示）
 *             2. 修改 getLiveUrl 方法，替换为您的直播源获取逻辑
 *
 * @see SceneLiveModule
 */
@interface SceneLiveViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
