//
//  PlayerLifecycleStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MediaPlayer;
@protocol PlayerFactory;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器实例生命周期管理策略协议。
 *
 * @discussion 定义播放器实例的获取与回收行为，允许不同策略控制播放器的创建、复用和销毁方式。
 *             框架内置四种策略实现：
 *             - DefaultLifecycleStrategy：每次获取创建新实例，回收即销毁（默认行为）。
 *             - ReusePoolLifecycleStrategy：维护空闲播放器池，优先复用池中实例。
 *             - SingletonLifecycleStrategy：全局唯一播放器实例，所有获取返回同一实例。
 *             - IdScopedPoolLifecycleStrategy：为每个 uniqueId 维护独立实例，LRU 淘汰。
 *
 *             策略使用前必须调用 setupWithFactory: 注入播放器工厂。
 *             所有内置策略均继承自 BaseLifecycleStrategy 基类，
 *             该基类提供工厂管理和 createPlayer / destroyPlayer: 模板方法。
 *
 * @see BaseLifecycleStrategy
 * @see DefaultLifecycleStrategy
 * @see ReusePoolLifecycleStrategy
 * @see SingletonLifecycleStrategy
 * @see IdScopedPoolLifecycleStrategy
 * @see PlayerFactory
 */
@protocol PlayerLifecycleStrategy <NSObject>

/**
 * @brief 注入播放器工厂。
 *
 * @param factory 用于创建和销毁播放器实例的工厂，不可为 nil。
 *
 * @discussion 必须在首次调用 acquirePlayer 之前调用。
 *             重复调用会替换之前注入的工厂。
 */
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/**
 * @brief 获取播放器实例。
 *
 * @discussion 根据策略实现，可能创建新实例或复用已有实例。
 *             获取的播放器处于 PlayerStateIdle 或 PlayerStateStopped 状态，
 *             使用前需调用 setDataSource: 和 prepare。
 *
 * @return 遵循 MediaPlayer 协议的播放器实例。
 *
 * @see recyclePlayer:force:
 */
- (id<MediaPlayer>)acquirePlayer;

/**
 * @brief 回收播放器实例。
 *
 * @param player 要回收的播放器实例，为 nil 时不执行任何操作。
 * @param force  YES 强制销毁实例，无论策略是否支持复用；
 *               NO 由策略决定处理方式（可能放入复用池或保持存活）。
 *
 * @discussion 当 force 为 NO 时，各策略的行为：
 *             - Default：销毁播放器。
 *             - ReusePool：停止播放并归还池中。
 *             - Singleton：停止播放但保持实例存活。
 *
 * @see acquirePlayer
 */
- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force;

/**
 * @brief 释放策略持有的所有播放器实例。
 *
 * @discussion 调用后策略恢复到初始状态，所有缓存的播放器实例将被销毁。
 */
- (void)clear;

@optional

/**
 * @brief 预加载指定数量的播放器实例到池中。
 *
 * @param count 期望预加载的播放器数量。
 *
 * @discussion 仅对维护播放器池的策略（如 ReusePoolLifecycleStrategy）有意义。
 *             不支持预加载的策略可不实现此方法。
 */
- (void)preloadWithCount:(NSInteger)count;

/**
 * @brief 根据业务唯一标识获取播放器实例。
 *
 * @param uniqueId 业务唯一标识，用于区分不同视频源或业务场景。
 *
 * @discussion 仅 IdScopedPoolLifecycleStrategy 实现此方法。
 *             当策略实现了此方法时，AliPlayerController 会优先调用它代替 acquirePlayer。
 *             相同 uniqueId 多次调用将返回同一实例（LRU 命中）。
 *
 * @return 遵循 MediaPlayer 协议的播放器实例。
 *
 * @see IdScopedPoolLifecycleStrategy
 */
- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId;

/**
 * @brief 根据业务唯一标识回收播放器实例。
 *
 * @param player   要回收的播放器实例，为 nil 时不执行任何操作。
 * @param uniqueId 该播放器对应的业务唯一标识。
 * @param force    YES 强制销毁实例；NO 由策略决定处理方式。
 *
 * @discussion 仅 IdScopedPoolLifecycleStrategy 实现此方法。
 *             当策略实现了此方法时，AliPlayerController 会优先调用它代替 recyclePlayer:force:。
 *
 * @see IdScopedPoolLifecycleStrategy
 */
- (void)recyclePlayer:(nullable id<MediaPlayer>)player uniqueId:(NSString *)uniqueId force:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
