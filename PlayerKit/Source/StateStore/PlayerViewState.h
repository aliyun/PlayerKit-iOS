//
//  PlayerViewState.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器视图状态存储，持有与 UI 层级相关的持久状态。
 *
 * @discussion 与 AliPlayerView 绑定，跨视频切换保留。
 *             包含全屏模式和控制栏可见性等 UI 状态。
 *             状态更新包含自动去重处理。
 *
 * @see AliPlayerView
 */
@interface PlayerViewState : NSObject

/** @brief 是否处于全屏模式。默认为 NO。 */
@property (nonatomic, assign, readonly, getter=isFullscreen) BOOL fullscreen;

/** @brief 控制栏（TopBar/BottomBar）是否可见。默认为 NO。 */
@property (nonatomic, assign, readonly) BOOL controlsVisible;

/** @brief 重置所有状态为默认值。 */
- (void)reset;

/** @brief 更新全屏状态。 */
- (void)updateFullscreen:(BOOL)fullscreen;

/** @brief 更新控制栏可见性。 */
- (void)updateControlsVisible:(BOOL)controlsVisible;

@end

NS_ASSUME_NONNULL_END
