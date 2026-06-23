//
//  PlayerPreloadTask.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoSource;
@class PlayerPreloadConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 预加载任务模型。
 *
 * @discussion 封装一次预加载任务的输入，包括视频数据源和预加载配置。
 *
 * @see VideoSource
 * @see PlayerPreloadConfig
 * @see PlayerPreloader
 */
@interface PlayerPreloadTask : NSObject

/** @brief 视频数据源。 */
@property (nonatomic, strong, readonly) VideoSource *videoSource;

/** @brief 预加载配置。 */
@property (nonatomic, strong, readonly) PlayerPreloadConfig *preloadConfig;

/**
 * @brief 创建预加载任务。
 *
 * @param videoSource   视频数据源，不可为 nil。
 * @param preloadConfig 预加载配置，不可为 nil。
 *
 * @return 预加载任务实例。
 */
- (instancetype)initWithVideoSource:(VideoSource *)videoSource
                      preloadConfig:(PlayerPreloadConfig *)preloadConfig NS_DESIGNATED_INITIALIZER;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
