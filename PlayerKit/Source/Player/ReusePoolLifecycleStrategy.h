//
//  ReusePoolLifecycleStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseLifecycleStrategy.h"
#import "PlayerLifecycleStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 复用池播放器生命周期策略。
 *
 * @discussion 维护一个空闲播放器实例池，acquirePlayer 优先从池中获取已停止的播放器，
 *             池为空时通过工厂创建新实例。recyclePlayer 默认将播放器停止后归还池中。
 *
 *             适用于信息流等频繁创建/销毁播放器的场景，可显著减少播放器初始化开销。
 *
 *             池容量通过 maxPoolSize 控制，超出容量时回收的播放器将直接销毁。
 *             支持通过 preloadWithCount: 预填充池。
 *             clear 仅清空空闲池，不影响已 acquire 但未 recycle 的活跃实例。
 *
 * @warning 此策略的所有方法线程安全。
 *
 * @see PlayerLifecycleStrategy
 * @see BaseLifecycleStrategy
 * @see DefaultLifecycleStrategy
 * @see SingletonLifecycleStrategy
 */
@interface ReusePoolLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/**
 * @brief 池的最大容量，默认为 3。
 *
 * @discussion 超出此容量时，recyclePlayer 将直接销毁播放器而非归还池中。
 *             修改此值不会影响池中已有的实例。
 */
@property (nonatomic, assign) NSInteger maxPoolSize;

/**
 * @brief 当前池中空闲播放器数量。
 */
@property (nonatomic, assign, readonly) NSInteger idleCount;

/**
 * @brief 当前已 acquire 但未 recycle 的活跃播放器数量。
 */
@property (nonatomic, assign, readonly) NSInteger activeCount;

/**
 * @brief 使用指定最大容量创建策略实例。
 *
 * @param maxPoolSize 池的最大容量。
 *
 * @return 策略实例。
 */
- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
