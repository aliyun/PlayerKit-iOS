//
//  DefaultLifecycleStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseLifecycleStrategy.h"
#import "PlayerLifecycleStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 默认播放器生命周期策略。
 *
 * @discussion 每次 acquirePlayer 通过工厂创建新实例，每次 recyclePlayer 销毁实例。
 *             等价于未引入生命周期策略前的原始行为。
 *
 *             适用于大多数标准播放场景，无额外内存开销。
 *
 * @see PlayerLifecycleStrategy
 * @see BaseLifecycleStrategy
 * @see ReusePoolLifecycleStrategy
 * @see SingletonLifecycleStrategy
 */
@interface DefaultLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

@end

NS_ASSUME_NONNULL_END
