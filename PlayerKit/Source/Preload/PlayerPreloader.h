//
//  PlayerPreloader.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlayerPreloadTask;
@protocol PreloadDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器全局预加载接口。
 *
 * @discussion 封装播放器 SDK 的全局预加载功能，提供统一的预加载任务管理。
 *             支持添加、取消、暂停和恢复预加载任务。
 *
 * @see PlayerPreloadTask
 * @see PreloadDelegate
 * @see DefaultPlayerPreloader
 */
@protocol PlayerPreloader <NSObject>

/**
 * @brief 添加预加载任务。
 *
 * @param task     预加载任务对象，不可为 nil。
 * @param delegate 任务状态代理监听器，不可为 nil。
 *
 * @return 分配的唯一任务 ID，用于后续控制与查询。
 *
 * @see PlayerPreloadTask
 * @see PreloadDelegate
 */
- (NSString *)addTask:(PlayerPreloadTask *)task delegate:(id<PreloadDelegate>)delegate;

/**
 * @brief 取消指定任务 ID 的加载。
 *
 * @param taskId 要取消加载的任务 ID。
 *
 * @discussion 不会删除已经下载的文件，仅取消未完成部分的加载。
 */
- (void)cancelTask:(NSString *)taskId;

/**
 * @brief 暂停指定任务 ID 的加载。
 *
 * @param taskId 要暂停的任务 ID。
 */
- (void)pauseTask:(NSString *)taskId;

/**
 * @brief 恢复指定任务 ID 的加载。
 *
 * @param taskId 要恢复的任务 ID。
 */
- (void)resumeTask:(NSString *)taskId;

/**
 * @brief 取消所有预加载任务。
 */
- (void)cancelAll;

@end

NS_ASSUME_NONNULL_END
