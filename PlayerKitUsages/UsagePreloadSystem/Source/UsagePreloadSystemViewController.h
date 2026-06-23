//
//  UsagePreloadSystemViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 演示 PlayerKit 预加载系统用法的视图控制器。
 *
 * @discussion 提供交互式 UI，用于添加预加载任务、暂停/恢复/取消任务，
 *             并实时显示预加载回调状态。
 *             演示与 PlayerPreloader、PlayerPreloadTask、PlayerPreloadConfig 和 PreloadDelegate 的集成。
 *
 * @see UsagePreloadSystemModule
 * @see PlayerPreloader
 * @see PlayerPreloadTask
 * @see PlayerPreloadConfig
 */
@interface UsagePreloadSystemViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
