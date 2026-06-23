//
//  StrategyManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StrategyProtocol;
@class AliPlayerController;
@class AliPlayerModel;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 策略管理器，负责策略的注册、生命周期管理和错误隔离。
 *
 * @discussion 每个 AliPlayerController 拥有一个 StrategyManager 实例。
 *             管理器维护一组有序的策略实例，按注册顺序执行生命周期回调。
 *             每个策略的生命周期调用均通过 @try/@catch 隔离，
 *             单个策略异常不会影响其他策略的正常运行。
 *
 * @warning 所有方法必须在主线程调用。此类不提供内部线程同步。
 *
 * @see StrategyProtocol
 * @see AliPlayerController
 * @see StrategyRegistry
 */
@interface StrategyManager : NSObject

/**
 * @brief 注册策略。
 *
 * @param strategy 遵循 StrategyProtocol 的策略实例。
 *
 * @discussion 如果已存在同名策略，旧策略会被停止并替换。
 *             如果管理器已启动，新策略会立即启动。
 *
 * @see unregisterStrategyWithName:
 */
- (void)registerStrategy:(id<StrategyProtocol>)strategy;

/**
 * @brief 按名称注销策略。
 *
 * @param name 策略的唯一标识名称。
 *
 * @discussion 如果管理器已启动，策略会先被停止再移除。
 *             如果指定名称不存在，此方法不产生任何效果。
 *
 * @see registerStrategy:
 */
- (void)unregisterStrategyWithName:(NSString *)name;

/**
 * @brief 按名称查找策略。
 *
 * @param name 策略的唯一标识名称。
 *
 * @return 匹配的策略实例，未找到返回 nil。
 */
- (nullable id<StrategyProtocol>)strategyWithName:(NSString *)name;

/**
 * @brief 启动所有已注册的策略。
 *
 * @param controller 播放器控制器。
 * @param playerModel 播放配置模型。
 *
 * @discussion 创建 StrategyContext 并对每个策略调用 strategyDidStart:。
 *             如果管理器已处于启动状态，会先停止再重新启动。
 *
 * @see stop
 */
- (void)startWithController:(AliPlayerController *)controller
                playerModel:(AliPlayerModel *)playerModel;

/**
 * @brief 重置所有策略（视频源切换时调用）。
 *
 * @param playerModel 新的播放配置模型。
 *
 * @discussion 使用新模型更新上下文，并对每个策略调用 strategyDidReset。
 *             策略保持事件订阅状态，仅重置内部统计数据。
 *             如果管理器未启动，此方法不产生任何效果。
 *
 * @see startWithController:playerModel:
 */
- (void)resetWithPlayerModel:(AliPlayerModel *)playerModel;

/**
 * @brief 停止所有策略。
 *
 * @discussion 对每个策略调用 strategyDidStop，策略取消事件订阅。
 *             策略实例保留在管理器中，可通过再次 start 重新启动。
 *
 * @see startWithController:playerModel:
 */
- (void)stop;

/**
 * @brief 销毁管理器，停止并移除所有策略。
 *
 * @discussion 先调用 stop 停止所有策略，再清空策略列表。
 *             调用后管理器为空，需重新注册策略才能使用。
 *
 * @see stop
 */
- (void)destroy;

/**
 * @brief 当前已注册的策略数量。
 */
@property (nonatomic, assign, readonly) NSUInteger strategyCount;

/**
 * @brief 管理器是否已启动。
 */
@property (nonatomic, assign, readonly, getter=isStarted) BOOL started;

@end

NS_ASSUME_NONNULL_END
