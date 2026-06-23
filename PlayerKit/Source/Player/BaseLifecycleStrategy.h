//
//  BaseLifecycleStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/22.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MediaPlayer;
@protocol PlayerFactory;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器生命周期策略基类。
 *
 * @discussion 提供所有策略实现的共享基础设施：
 *             - 持有并管理 PlayerFactory 实例。
 *             - 提供 createPlayer / destroyPlayer: 模板方法，
 *               封装工厂调用与日志记录，子类应通过这些方法而非直接调用工厂。
 *
 *             本类不声明 PlayerLifecycleStrategy 协议一致性，
 *             子类需自行声明并实现 acquirePlayer、recyclePlayer:force:、clear 等方法。
 *
 * @see PlayerLifecycleStrategy
 * @see DefaultLifecycleStrategy
 * @see ReusePoolLifecycleStrategy
 * @see SingletonLifecycleStrategy
 * @see IdScopedPoolLifecycleStrategy
 */
@interface BaseLifecycleStrategy : NSObject

/**
 * @brief 当前注入的播放器工厂。
 *
 * @discussion 通过 setupWithFactory: 设置，子类通过 createPlayer / destroyPlayer: 间接使用。
 */
@property (nonatomic, strong, readonly) id<PlayerFactory> factory;

/**
 * @brief 注入播放器工厂。
 *
 * @param factory 用于创建和销毁播放器实例的工厂，不可为 nil。
 *
 * @discussion 该方法具备幂等性，仅首次调用生效。重复调用将打印警告日志并忽略。
 *             实现 PlayerLifecycleStrategy 协议的 setupWithFactory: 方法。
 *             子类继承后无需重写，除非需要额外初始化逻辑（此时应调用 super）。
 */
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/**
 * @brief 通过工厂创建新的播放器实例。
 *
 * @discussion 子类应调用此方法而非直接调用 factory.createPlayer，
 *             以确保创建操作被统一记录。
 *
 * @return 新创建的播放器实例。
 */
- (id<MediaPlayer>)createPlayer;

/**
 * @brief 通过工厂销毁播放器实例。
 *
 * @param player 要销毁的播放器实例，为 nil 时不执行任何操作。
 *
 * @discussion 子类应调用此方法而非直接调用 factory.destroyPlayer:，
 *             以确保销毁操作被统一记录。
 */
- (void)destroyPlayer:(nullable id<MediaPlayer>)player;

@end

NS_ASSUME_NONNULL_END
