//
//  FullscreenTransition.h
//  AliPlayerKit
//
//  Created by keria on 2024/3/15.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AliPlayerView;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 全屏过渡协议。
 *
 * @discussion 定义播放器视图进入/退出全屏的过渡行为。
 *             实现方负责管理全屏窗口、视图迁移、动画及旋转适配等细节。
 */
@protocol FullscreenTransition <NSObject>

/**
 * @brief 进入全屏。
 *
 * @param playerView 需要全屏展示的播放器视图。
 * @param animated   是否执行过渡动画。
 * @param completion 过渡完成后的回调（可为 nil）。
 */
- (void)enterFullscreenWithPlayerView:(AliPlayerView *)playerView
                             animated:(BOOL)animated
                           completion:(nullable void(^)(void))completion;

/**
 * @brief 退出全屏。
 *
 * @param playerView 需要还原的播放器视图。
 * @param animated   是否执行过渡动画。
 * @param completion 过渡完成后的回调（可为 nil）。
 */
- (void)exitFullscreenWithPlayerView:(AliPlayerView *)playerView
                            animated:(BOOL)animated
                          completion:(nullable void(^)(void))completion;

/** @brief 当前是否处于全屏状态。 */
@property (nonatomic, readonly) BOOL isInFullscreen;

@end

NS_ASSUME_NONNULL_END
