//
//  PreloadDelegate.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoSource;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 预加载任务状态代理协议。
 *
 * @discussion 用于接收预加载任务的完成、错误和取消事件。
 *             回调方法可能在后台线程触发，上层需自行分派到主线程处理。
 *
 * @see PlayerPreloader
 */
@protocol PreloadDelegate <NSObject>

/**
 * @brief 预加载任务完成时调用。
 *
 * @param taskId 对应任务的唯一 ID。
 * @param source 此任务对应的视频数据源。
 */
- (void)preloadTaskDidComplete:(NSString *)taskId source:(VideoSource *)source;

/**
 * @brief 预加载任务发生错误时调用。
 *
 * @param taskId 对应任务的唯一 ID。
 * @param source 此任务对应的视频数据源。
 * @param error  描述错误信息的 NSError 对象。
 */
- (void)preloadTaskDidFail:(NSString *)taskId source:(VideoSource *)source error:(NSError *)error;

/**
 * @brief 预加载任务被取消时调用。
 *
 * @param taskId 对应任务的唯一 ID。
 * @param source 此任务对应的视频数据源。
 */
- (void)preloadTaskDidCancel:(NSString *)taskId source:(VideoSource *)source;

@end

NS_ASSUME_NONNULL_END
