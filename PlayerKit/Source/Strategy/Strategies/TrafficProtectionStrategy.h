//
//  TrafficProtectionStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@class TrafficProtectionStrategy;

/**
 * @brief 蜂窝网络流量保护策略代理。
 */
@protocol TrafficProtectionStrategyDelegate <NSObject>
@optional

/**
 * @brief 检测到当前正在使用蜂窝网络播放（仅在状态首次切换或开始播放时回调）。
 *
 * @param strategy 策略实例。
 */
- (void)trafficProtectionStrategyDidDetectCellularNetwork:(TrafficProtectionStrategy *)strategy;

/**
 * @brief 检测到网络切换回 Wi-Fi。
 *
 * @param strategy 策略实例。
 */
- (void)trafficProtectionStrategyDidDetectWifiNetwork:(TrafficProtectionStrategy *)strategy;

@end

/**
 * @brief 蜂窝网络流量保护策略。
 *
 * @discussion 监控网络状态变化，当检测到设备使用蜂窝网络播放视频时发出警告。
 *             策略在启动时检查当前网络状态，并持续监听网络变化事件。
 *
 *             此策略仅进行检测和日志记录，不会自动暂停播放。
 *             应用层可通过查询 isOnCellularNetwork 属性或设置 delegate 来决定是否展示提示。
 *
 * @see BaseStrategy
 */
@interface TrafficProtectionStrategy : BaseStrategy

/** @brief 当前是否处于蜂窝网络。 */
@property (nonatomic, assign, readonly) BOOL isOnCellularNetwork;

/** @brief 回调代理。 */
@property (nonatomic, weak, nullable) id<TrafficProtectionStrategyDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
