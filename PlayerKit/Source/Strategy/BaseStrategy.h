//
//  BaseStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StrategyProtocol.h"
#import "PlayerNotificationDelegate.h"

@class StrategyContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 策略抽象基类，提供通用的生命周期管理。
 *
 * @discussion 实现 StrategyProtocol 和 PlayerNotificationDelegate，
 *             自动处理播放器事件的订阅与取消订阅。
 *             子类只需覆写 strategyName、感兴趣的 PlayerNotificationDelegate 回调方法，
 *             以及 resetInternalState 来重置自身状态。
 *
 *             生命周期流转：
 *             - strategyDidStart: → 保存上下文 → 注册为控制器的通知代理
 *             - strategyDidReset: → 更新上下文 → 调用 resetInternalState 重置内部状态
 *             - strategyDidStop   → 注销通知代理 → 清空上下文
 *
 * @warning 子类必须覆写 strategyName 方法，否则会触发异常。
 *          如果覆写 strategyDidStart: / strategyDidStop / strategyDidReset:，
 *          必须调用 super。
 *
 * @see StrategyProtocol
 * @see PlayerNotificationDelegate
 * @see StrategyContext
 */
@interface BaseStrategy : NSObject <StrategyProtocol, PlayerNotificationDelegate>

/**
 * @brief 当前策略上下文（仅在 start 和 stop 之间有效）。
 *
 * @discussion 子类可通过此属性访问播放器控制器和状态信息。
 *             在 strategyDidStart: 之前和 strategyDidStop 之后为 nil。
 */
@property (nonatomic, strong, readonly, nullable) StrategyContext *context;

/**
 * @brief 子类重置内部状态的钩子方法。
 *
 * @discussion 在 strategyDidReset: 时由基类调用（上下文已更新后）。
 *             子类应在此方法中清零计数器、定时器等临时状态，
 *             但不应取消事件订阅（由基类管理）。
 *             默认实现为空操作。
 */
- (void)resetInternalState;

@end

NS_ASSUME_NONNULL_END
