//
//  AliPlayerController+Private.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AliPlayerController.h"

@class AliPlayerView;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AliPlayerController 的内部接口 Category。
 *
 * @discussion 此头文件定义了仅供 PlayerKit 模块内部使用的接口。
 *             外部使用方不应依赖这些 API。
 *
 * @warning 这是私有 API，不保证向后兼容性。
 */
@interface AliPlayerController (Private)

/**
 * @brief 关联的播放器视图（弱引用，仅供内部使用）。
 *
 * @discussion 由 AliPlayerView 在 @c attach: 时设置，在 @c detach 时清空。
 *             供全屏过渡、插槽联动等需要访问宿主视图的内部逻辑使用。
 *
 * @warning 这是私有 API，不应在外部访问。
 */
@property (nonatomic, weak, nullable) AliPlayerView *playerView;

/**
 * @brief 将外部渲染视图绑定到底层播放器（仅供内部使用）。
 *
 * @param renderView 用于视频渲染的视图。
 *
 * @discussion 此方法由 AliPlayerView 内部调用。
 *             外部使用方应使用 @c AliPlayerView 及其
 *             @c attach: 方法。
 *
 * @see AliPlayerView
 *
 * @warning 这是私有 API，不应在外部调用。
 */
- (void)bindRenderView:(UIView *)renderView;

@end

NS_ASSUME_NONNULL_END
