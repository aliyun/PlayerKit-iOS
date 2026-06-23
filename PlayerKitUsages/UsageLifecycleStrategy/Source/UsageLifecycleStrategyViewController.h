//
//  UsageLifecycleStrategyViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器生命周期策略用法示例的主视图控制器。
 *
 * @discussion 展示 PlayerKit 播放器生命周期策略的完整接入流程，包括：
 *             - 三种内置策略（Default、ReusePool、Singleton）的切换与对比
 *             - 策略对播放器实例创建/复用行为的可视化展示
 *             - 多视频源切换场景下策略行为的差异观察
 *
 * @see UsageLifecycleStrategyModule
 * @see PlayerLifecycleStrategy
 */
@interface UsageLifecycleStrategyViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
