//
//  StutterDetectStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@class StutterDetectStrategy;

@protocol StutterDetectStrategyDelegate <NSObject>
@optional
/**
 * @brief 卡顿检测策略检测到一次卡顿。
 *
 * @param strategy 当前卡顿检测策略实例。
 * @param durationInMilliseconds 本次卡顿耗时，单位：毫秒。
 */
- (void)stutterDetectStrategy:(StutterDetectStrategy *)strategy
                   didStutter:(NSInteger)durationMs;

/**
 * @brief 卡顿检测策略完成播放会话分析。
 *
 * @discussion 播放会话结束时回调，用于上报本次会话的停留时长、有效播放时长、
 *             卡顿总时长以及卡顿总次数。
 *
 *             停留时长指从进入播放会话到会话结束的总时长，包含暂停时长。
 *             有效播放时长指实际有效播放的累计时长。
 *
 * @param strategy 当前卡顿检测策略实例。
 * @param stayDurationInMilliseconds 停留时长，从进入播放会话到会话结束的总时长，包含暂停时长，单位：毫秒。
 * @param validPlayDurationInMilliseconds 有效播放时长，单位：毫秒。
 * @param totalStutterDurationInMilliseconds 卡顿总时长，单位：毫秒。
 * @param stutterCount 卡顿总次数。
 */
- (void)stutterDetectStrategy:(StutterDetectStrategy *)strategy
            didAnalyzeSession:(NSInteger)stayDurationMs
            validPlayDuration:(NSInteger)validPlayDurationMs
         totalStutterDuration:(NSInteger)totalStutterDurationMs
                 stutterCount:(NSInteger)stutterCount;
@end

/**
 * @brief 卡顿检测策略。
 *
 * @discussion 通过监听 Loading 事件检测卡顿。
 *             首帧渲染前的 Loading 不计入卡顿统计。
 *
 *             统计数据包括：
 *             - 卡顿次数
 *             - 卡顿总时长
 *             - 有效播放时长（排除卡顿期间）
 *
 *             当播放会话结束（停止、完成或错误）时输出会话分析报告。
 *
 * @see BaseStrategy
 * @see PlayerNotificationDelegate
 */
@interface StutterDetectStrategy : BaseStrategy

/** @brief 当前会话的卡顿次数。 */
@property (nonatomic, assign, readonly) NSInteger stutterCount;

/** @brief 当前会话的卡顿总时长，单位毫秒。 */
@property (nonatomic, assign, readonly) NSInteger totalStutterDurationMs;

/** @brief 卡顿阈值（毫秒），超过该时长才视为卡顿，默认 0。 */
@property (nonatomic, assign, readonly) NSInteger stutterThresholdMs;

/** @brief 回调代理。 */
@property (nonatomic, weak, nullable) id<StutterDetectStrategyDelegate> delegate;

/// 创建卡顿检测策略（指定阈值）
- (instancetype)initWithThreshold:(NSInteger)thresholdMs;

@end

NS_ASSUME_NONNULL_END
