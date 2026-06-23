//
//  ResumePlayStrategy.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseStrategy.h"

@class VideoSource;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 断点续播策略，记录并恢复播放位置。
 *
 * @discussion 通过 NSUserDefaults 持久化播放位置，实现跨会话的断点续播。
 *             当播放器准备完成时自动跳转到上次保存的位置。
 *             播放完毕后清除存储（下次从头播放）。
 *
 *             持久化策略：
 *             - 每 5 秒节流保存当前播放位置
 *             - 距结尾 10 秒内清除存储（视为播放完毕）
 *             - 视频源切换时重置节流计时
 *
 *             存储键格式：@"com.aliyun.playerkit.resume_position_{mediaId}"
 *
 * @see BaseStrategy
 */
@interface ResumePlayStrategy : BaseStrategy

/**
 * @brief 查询指定视频源的续播位置。
 *
 * @param source 视频源对象。
 *
 * @return 上次保存的播放位置（毫秒），无记录返回 0。
 *
 * @discussion 可在配置播放器前调用此方法，用于 UI 展示或设置起始时间。
 */
+ (NSInteger)resumePositionForSource:(nullable VideoSource *)source;

/**
 * @brief 清除指定视频源的续播记录。
 *
 * @param source 视频源对象。
 *
 * @discussion 用于手动清除续播记录（例如用户主动重置）。
 */
+ (void)clearResumePositionForSource:(nullable VideoSource *)source;

@end

NS_ASSUME_NONNULL_END
