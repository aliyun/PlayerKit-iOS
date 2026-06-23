//
//  StrategyProtocol.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StrategyContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器策略协议，定义策略的生命周期契约。
 *
 * @discussion 每个策略必须实现此协议以参与播放器的策略管理。
 *             策略通过 StrategyManager 进行注册和管理，生命周期跟随播放器控制器。
 *             策略名称必须全局唯一，作为注册和查找的标识符。
 *
 * @see BaseStrategy
 * @see StrategyManager
 * @see StrategyContext
 */
@protocol StrategyProtocol <NSObject>

@required

/**
 * @brief 策略的唯一标识名称。
 *
 * @discussion 用于在 StrategyManager 中进行注册、查找和日志记录。
 *             同名策略注册时会替换已有实例。
 *
 * @return 策略名称字符串，不可为空。
 */
- (NSString *)strategyName;

/**
 * @brief 策略启动，绑定播放器上下文。
 *
 * @param context 播放器上下文，包含控制器、播放模型和状态存储的引用。
 *
 * @discussion 由 StrategyManager 在播放器配置完成后调用。
 *             策略应在此方法中完成事件订阅和初始状态设置。
 *             context 在 strategyDidStop 前始终有效。
 *
 * @warning 不要在此方法之外缓存 context 的引用。
 *
 * @see strategyDidStop
 * @see StrategyContext
 */
- (void)strategyDidStart:(StrategyContext *)context;

/**
 * @brief 策略停止，解绑播放器上下文。
 *
 * @discussion 由 StrategyManager 在播放器销毁或策略注销时调用。
 *             策略应在此方法中取消所有事件订阅、释放资源。
 *             调用后 context 不再有效。
 *
 * @see strategyDidStart:
 */
- (void)strategyDidStop;

/**
 * @brief 策略重置，更新上下文并清除内部状态。
 *
 * @param context 新的策略上下文（包含更新后的播放模型）。
 *
 * @discussion 当同一控制器切换视频源时（重新 configure），由 StrategyManager 调用。
 *             策略应重置内部计数器和临时状态，但保持事件订阅不变。
 *             新的 context 包含更新后的 playerModel，旧 context 不再有效。
 *
 * @see strategyDidStart:
 */
- (void)strategyDidReset:(StrategyContext *)context;

@end

NS_ASSUME_NONNULL_END
