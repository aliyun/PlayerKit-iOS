//
//  PlayerFactory.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MediaPlayer;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器工厂协议。
 *
 * @discussion 定义创建和销毁播放器实例的工厂接口，允许不同的创建策略。
 *             通过 AliPlayerKit 的 setPlayerFactory: 方法可替换为自定义工厂实现。
 *             每次调用 createPlayer 都应返回一个新的实例。
 *
 * @see MediaPlayer
 * @see DefaultPlayerFactory
 */
@protocol PlayerFactory <NSObject>

/**
 * @brief 创建播放器实例。
 *
 * @discussion 每次调用都会创建一个新的播放器实例。
 *             创建后的播放器处于 PlayerStateIdle 状态，需通过 setDataSource: 设置数据源后使用。
 *
 * @return 遵循 MediaPlayer 协议的播放器实例，不会为 nil。
 *
 * @see destroyPlayer:
 */
- (id<MediaPlayer>)createPlayer;

/**
 * @brief 销毁播放器实例。
 *
 * @param player 要销毁的播放器实例，可以为 nil（nil 时仅记录警告日志，不执行任何操作）。
 *
 * @discussion 释放播放器占用的所有资源。调用此方法后，播放器实例将无法继续使用。
 *             如果传入的 player 为 nil，则只记录警告日志。
 *
 * @see createPlayer
 */
- (void)destroyPlayer:(nullable id<MediaPlayer>)player;

@end

NS_ASSUME_NONNULL_END
