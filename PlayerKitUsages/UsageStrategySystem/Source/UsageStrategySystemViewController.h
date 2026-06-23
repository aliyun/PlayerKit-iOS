//
//  UsageStrategySystemViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 策略系统用法示例的主视图控制器。
 *
 * @discussion 展示 PlayerKit 策略系统的完整接入流程，包括：
 *             - 内置策略（首帧监测、卡顿检测、流量保护）自动生效
 *             - 自定义策略（ResumePlayStrategy 断点续播）的注册和使用
 *             - 策略生命周期事件的可视化日志
 *
 * @see UsageStrategySystemModule
 * @see ResumePlayStrategy
 */
@interface UsageStrategySystemViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
