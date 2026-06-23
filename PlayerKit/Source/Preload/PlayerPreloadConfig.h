//
//  PlayerPreloadConfig.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 预加载配置模型。
 *
 * @discussion 定义预加载行为的参数，包括预加载时长、清晰度选择、网络策略等。
 *             属性与 SDK 的 AVPPreloadConfig 一一对应。
 *
 * @see PlayerPreloadTask
 * @see PlayerPreloader
 */
@interface PlayerPreloadConfig : NSObject

/**
 * @brief 预加载时长，单位毫秒，默认为 3000。
 *
 * @discussion 设置值小于 0 时会被修正为 0。
 */
@property (nonatomic, assign) NSInteger preloadDuration;

/**
 * @brief 预加载起始位置，单位毫秒，默认为 0。
 *
 * @discussion 从视频的指定位置开始预加载。
 */
@property (nonatomic, assign) NSInteger loadStartPositionMs;

/**
 * @brief 默认清晰度标识，默认为 @"AUTO"。
 *
 * @discussion 传入 nil 或空字符串时会重置为 @"AUTO"。
 *             仅对 VidAuth / VidSts 类型视频源有效。
 */
@property (nonatomic, copy) NSString *defaultQuality;

/**
 * @brief 默认分辨率（宽 × 高），默认为 0（不限制）。
 *
 * @discussion 仅对 VidAuth / VidSts 类型视频源有效。
 */
@property (nonatomic, assign) NSInteger defaultResolution;

/**
 * @brief 默认码率（比特率），默认为 0（不限制）。
 *
 * @discussion 仅对 VidAuth / VidSts 类型视频源有效。
 */
@property (nonatomic, assign) NSInteger defaultBandWidth;

/**
 * @brief 网络超时时间，单位毫秒，默认为 0（使用 SDK 默认值）。
 */
@property (nonatomic, assign) NSInteger networkTimeout;

/**
 * @brief 网络重试次数，默认为 0（使用 SDK 默认值）。
 */
@property (nonatomic, assign) NSInteger networkRetryCount;

/**
 * @brief Referrer 信息，默认为 nil。
 */
@property (nonatomic, copy, nullable) NSString *referrer;

/**
 * @brief 自定义请求头，默认为 nil。
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *customHeaders;

/**
 * @brief 使用默认配置创建实例。
 *
 * @return 默认配置的预加载配置实例。
 */
- (instancetype)init;

/**
 * @brief 指定预加载时长和默认清晰度创建实例。
 *
 * @param preloadDuration 预加载时长，单位毫秒。
 * @param defaultQuality  默认清晰度标识。
 *
 * @return 配置完成的预加载配置实例。
 */
- (instancetype)initWithPreloadDuration:(NSInteger)preloadDuration
                         defaultQuality:(nullable NSString *)defaultQuality NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
