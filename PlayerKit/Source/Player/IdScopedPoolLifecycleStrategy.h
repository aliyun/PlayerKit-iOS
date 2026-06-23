//
//  IdScopedPoolLifecycleStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/22.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseLifecycleStrategy.h"
#import "PlayerLifecycleStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief ID 作用域池播放器生命周期策略。
 *
 * @discussion 为每个 uniqueId 维护一个独立的播放器实例。
 *             只要 uniqueId 不变，每次 acquire 都会返回同一个 Player 实例。
 *             策略内部使用 LRU（Least Recently Used）机制控制实例数量，
 *             当实例数量超过 maxPoolSize 时，会自动销毁最近最少使用的实例。
 *
 *             设计思想参考阿里云微短剧解决方案中的多实例播放器池 LRU 管理机制。
 *
 * @warning 此策略的所有方法线程安全。
 *
 * @see PlayerLifecycleStrategy
 * @see BaseLifecycleStrategy
 * @see DefaultLifecycleStrategy
 * @see ReusePoolLifecycleStrategy
 * @see SingletonLifecycleStrategy
 */
@interface IdScopedPoolLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/**
 * @brief 池的最大容量，默认为 3。
 *
 * @discussion 当映射表中的实例数量超过此值时，LRU 机制会自动淘汰最近最少使用的实例。
 *             修改此值时，如果新值小于当前实例数量，会立即按 LRU 顺序淘汰多余实例。
 */
@property (nonatomic, assign) NSInteger maxPoolSize;

/**
 * @brief 当前映射表中的播放器实例数量（含活跃和空闲）。
 */
@property (nonatomic, assign, readonly) NSInteger poolCount;

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
