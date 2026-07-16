//
//  SingletonLifecycleStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseLifecycleStrategy.h"
#import "PlayerLifecycleStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 单例播放器生命周期策略（全局共享单例）。
 *
 * @discussion 全局维护唯一播放器实例，所有 acquirePlayer 调用返回同一实例。
 *             recyclePlayer 默认仅停止播放但保持实例存活，force 为 YES 时销毁实例。
 *
 *             适用于整个 App 仅需一个播放器实例的场景（如后台音频播放），
 *             可最大程度减少播放器初始化次数。
 *
 *             clear 会销毁当前单例播放器实例并置空，之后再次 acquirePlayer 会重新创建。
 *
 *             本类采用 dispatch_once 真单例模式，通过 +sharedInstance 获取全局唯一实例。
 *
 * @warning 使用此策略时，多个 AliPlayerController 不可同时持有播放器，
 *          否则会导致状态冲突。
 *
 * @see PlayerLifecycleStrategy
 * @see BaseLifecycleStrategy
 * @see DefaultLifecycleStrategy
 * @see ReusePoolLifecycleStrategy
 */
@interface SingletonLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// 获取全局共享的单例策略实例。
+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
