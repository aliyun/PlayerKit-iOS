//
//  FirstFrameStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@class FirstFrameStrategy;

/**
 * @brief 首帧耗时监测策略代理。
 */
@protocol FirstFrameStrategyDelegate <NSObject>
@optional

/**
 * @brief 首帧渲染完成回调。
 *
 * @param strategy      策略实例。
 * @param prepareTimeMs 准备阶段耗时（毫秒）。
 * @param renderTimeMs  渲染阶段耗时（毫秒）。
 * @param totalTimeMs   总耗时（毫秒）。
 */
- (void)firstFrameStrategy:(FirstFrameStrategy *)strategy
       didRenderFirstFrameWithPrepareTime:(NSInteger)prepareTimeMs
                               renderTime:(NSInteger)renderTimeMs
                                totalTime:(NSInteger)totalTimeMs;

@end

/**
 * @brief 首帧耗时监测策略。
 *
 * @discussion 测量从播放器开始准备到首帧画面渲染的时间，分为两个阶段：
 *             - 准备阶段耗时（Preparing → Prepared）
 *             - 渲染阶段耗时（Prepared → FirstFrameRendered）
 *             - 总耗时（Preparing → FirstFrameRendered）
 *
 *             通过日志输出各阶段耗时数据，帮助分析播放启动性能。
 *             当播放器进入错误或停止状态时自动重置计时。
 *             可设置 delegate 以获取首帧耗时数据。
 *
 * @see BaseStrategy
 * @see PlayerNotificationDelegate
 */
@interface FirstFrameStrategy : BaseStrategy

/** @brief 回调代理。 */
@property (nonatomic, weak, nullable) id<FirstFrameStrategyDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
