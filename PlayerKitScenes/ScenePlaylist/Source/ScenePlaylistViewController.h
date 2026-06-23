//
//  ScenePlaylistViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 列表播放场景视图控制器。
 *
 * @discussion 演示如何使用列表播放功能，实现多个视频的连续播放。
 *             当一个视频播放完成后，会自动播放下一个视频。
 *
 *             设计说明：
 *             - playerView 复用，整个生命周期只有一个实例。
 *             - 使用双控制器模式：currentController（当前播放）+ nextController（预创建）。
 *             - 当前视频播放完成时，销毁当前控制器，将 nextController 提升为 currentController，
 *               并预创建新的 nextController。
 *             - 使用 SingletonLifecycleStrategy 复用播放器实例，减少初始化开销。
 *
 * @see ScenePlaylistModule
 * @see SingletonLifecycleStrategy
 */
@interface ScenePlaylistViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
