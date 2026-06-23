//
//  StrategyContext.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AliPlayerController;
@class AliPlayerModel;
@class PlayerStateStore;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 策略上下文，为策略提供只读的播放器环境信息。
 *
 * @discussion 在策略启动时由 StrategyManager 创建并传入。
 *             包含当前播放器控制器、播放模型和状态存储的引用。
 *             策略通过此对象访问播放器状态，而非直接持有控制器引用。
 *
 * @warning 此对象在 strategyDidStop 后不再有效，不应继续使用。
 *
 * @see StrategyProtocol
 * @see StrategyManager
 */
@interface StrategyContext : NSObject

/** @brief 关联的播放器控制器（弱引用）。 */
@property (nonatomic, weak, readonly) AliPlayerController *controller;

/** @brief 当前播放配置模型。 */
@property (nonatomic, strong, readonly) AliPlayerModel *playerModel;

/** @brief 播放器状态存储，提供当前播放状态的只读快照。 */
@property (nonatomic, strong, readonly, nullable) PlayerStateStore *stateStore;

/**
 * @brief 使用播放器控制器和播放模型初始化上下文。
 *
 * @param controller 播放器控制器实例。
 * @param playerModel 播放配置模型。
 *
 * @return 初始化后的上下文实例。
 */
- (instancetype)initWithController:(AliPlayerController *)controller
                       playerModel:(AliPlayerModel *)playerModel NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
