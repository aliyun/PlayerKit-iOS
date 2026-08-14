//
//  PlayerNotificationDelegate.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaPlayer.h"

@class TrackQuality;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器通知代理协议。
 *
 * @discussion 定义接收播放器状态变化、播放进度更新和错误通知的回调方法。
 *             所有回调均在主线程上派发。
 *
 * @see AliPlayerController
 * @see PlayerNotificationDispatcher
 */
@protocol PlayerNotificationDelegate <NSObject>

@optional

#pragma mark - Playback State

/**
 * @brief 当播放器状态变化时调用。
 *
 * @param state 新的播放器状态。
 *
 * @discussion 当播放器在状态之间转换时通知
 *             （例如 idle → preparing → prepared → playing）。
 *
 * @see PlayerState
 */
- (void)playerDidChangeState:(PlayerState)state;

/**
 * @brief 当播放器完成准备并可以播放时调用。
 *
 * @param duration 媒体总时长，单位为毫秒。
 *
 * @discussion 此时媒体元数据已可用，播放可以开始。
 */
- (void)playerDidPreparedWithDuration:(NSInteger)duration;

/**
 * @brief 当首帧视频画面已渲染时调用。
 *
 * @discussion 表示视频画面正在显示内容。
 *             适用于隐藏封面图或加载指示器。
 */
- (void)playerDidRenderFirstFrame;

/**
 * @brief 当播放到达媒体末尾时调用。
 *
 * @discussion 播放完成后播放器状态将转换为已停止。
 */
- (void)playerDidCompletion;

#pragma mark - Playback Progress

/**
 * @brief 定期调用以报告播放进度。
 *
 * @param position         当前播放位置，单位为毫秒。
 * @param duration         媒体总时长，单位为毫秒。
 * @param bufferedPosition 已缓冲位置，单位为毫秒。
 *
 * @discussion 在播放期间定期调用。
 *             用于更新进度条和时间标签。
 */
- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition;

#pragma mark - Error

/**
 * @brief 当播放错误发生时调用。
 *
 * @param error 描述失败的错误对象。
 *
 * @discussion 播放器状态将转换为错误状态。
 *             检查错误的 domain 和 code 以获取具体的失败详情。
 */
- (void)playerDidEncounterError:(NSError *)error;

#pragma mark - Snapshot

/**
 * @brief 截图完成时调用。
 *
 * @param image 截取到的图片，截图失败时为 nil。
 *
 * @discussion 由 AliPlayerController.snapshot 触发，
 *             截图完成后在主线程回调。
 */
- (void)playerDidCompleteSnapshot:(nullable UIImage *)image;

#pragma mark - Video Size

/**
 * @brief 视频尺寸变化时调用。
 *
 * @param width  视频原始宽度（像素）。
 * @param height 视频原始高度（像素）。
 *
 * @discussion 通常在 prepare 完成后首次回调，
 *             用于判断视频方向（横屏/竖屏）。
 */
- (void)playerDidChangeVideoWidth:(NSInteger)width
                           height:(NSInteger)height;

#pragma mark - Fullscreen

/**
 * @brief 全屏状态变化回调。
 *
 * @param isFullscreen 当前是否处于全屏模式。
 *
 * @discussion 在全屏过渡完成后回调，确保状态与视觉变化同步。
 *
 * @see AliPlayerController.setFullscreen:animated:
 */
- (void)playerDidChangeFullscreen:(BOOL)isFullscreen;

#pragma mark - Controls Visibility

/**
 * @brief 控制栏（TopBar/BottomBar）可见性变化回调。
 *
 * @param visible 控制栏是否应可见。
 *
 * @discussion 由 GestureControlSlot 单击手势或自动隐藏定时器触发。
 *             所有需要同步显隐的控制栏都应实现此方法，避免各自独立 toggle 导致概率性不同步。
 */
- (void)playerDidChangeControlsVisible:(BOOL)visible;

#pragma mark - Loading

/**
 * @brief 开始缓冲加载时调用。
 *
 * @discussion 在网络卡顿或缓冲不足时触发，表示播放器正在等待数据。
 *             适用于显示加载指示器。
 */
- (void)playerDidLoadingBegin;

/**
 * @brief 缓冲加载结束时调用。
 *
 * @discussion 缓冲数据充足可恢复播放时触发。
 *             适用于隐藏加载指示器。
 */
- (void)playerDidLoadingEnd;

/**
 * @brief 缓冲加载进度变化时调用。
 *
 * @param progress 缓冲进度，范围 0-100。
 */
- (void)playerDidUpdateLoadingProgress:(float)progress;

#pragma mark - Display Mode

/**
 * @brief 镜像模式变化时调用。
 *
 * @param mirrorMode 新的镜像模式。
 */
- (void)playerDidChangeMirrorMode:(MirrorMode)mirrorMode;

/**
 * @brief 缩放模式变化时调用。
 *
 * @param scaleMode 新的缩放模式。
 */
- (void)playerDidChangeScaleMode:(ScaleMode)scaleMode;

/**
 * @brief 旋转模式变化时调用。
 *
 * @param rotateMode 新的旋转模式。
 */
- (void)playerDidChangeRotateMode:(RotateMode)rotateMode;

#pragma mark - Thumbnail

/**
 * @brief 媒体缩略图 URL 就绪时调用。
 *
 * @param thumbnailUrl 从媒体信息中提取的缩略图 URL，非空字符串。
 *
 * @discussion 在 prepare 完成后从 SDK 媒体信息中读取并派发。
 *             仅 Vid 播放方式下由控制台配置的雪碧图才会返回有效值。
 *             每次 prepare 完成均会派发，观察者需自行做初始化去重。
 *
 * @note SDK 版本要求：通过 @c getMediaInfo.thumbnails 获取缩略图 URL
 *      需要阿里云播放器 SDK 版本 ≥ 7.16.0，低版本 SDK 该接口可能返回 nil。
 */
- (void)playerDidReadyThumbnailUrl:(NSString *)thumbnailUrl;

/**
 * @brief 缩略图获取成功时调用。
 *
 * @param positionMs 请求的缩略图位置，单位为毫秒。
 * @param image      获取到的缩略图图片。
 *
 * @discussion 由 AliPlayerController.requestThumbnailAtPosition: 触发，
 *             SDK 异步回调后在主线程派发。
 */
- (void)playerDidRetrieveThumbnail:(int64_t)positionMs
                             image:(UIImage *)image;

#pragma mark - Cover URL

/**
 * @brief 封面图 URL 就绪时调用（从 MediaInfo 自动提取）。
 *
 * @param coverUrl 从媒体信息中提取的封面图 URL，非空字符串。
 *
 * @discussion 在 prepare 完成后从 SDK 媒体信息中读取并派发。
 *             仅 Vid 播放方式下由服务端配置的封面才会返回有效值。
 *             观察者需自行判断是否已有手动设置的封面 URL，避免重复加载。
 *
 * @note SDK 版本要求：通过 @c getMediaInfo.coverURL 获取封面图 URL
 *      需要阿里云播放器 SDK 版本 ≥ 7.16.0，低版本 SDK 该接口可能返回 nil。
 */
- (void)playerDidReadyCoverUrl:(NSString *)coverUrl;

#pragma mark - Video Title

/**
 * @brief 视频标题就绪时调用（从 MediaInfo 自动提取）。
 *
 * @param videoTitle 从媒体信息中提取的视频标题，非空字符串。
 *
 * @discussion 在 prepare 完成后从 SDK 媒体信息中读取并派发。
 *             仅 Vid 播放方式下由服务端配置的标题才会返回有效值。
 *             观察者需自行判断是否已有手动设置的标题，避免覆盖。
 *
 * @note SDK 版本要求：通过 @c getMediaInfo.title 获取视频标题
 *      需要阿里云播放器 SDK 版本 ≥ 7.16.0，低版本 SDK 该接口可能返回 nil。
 */
- (void)playerDidReadyVideoTitle:(NSString *)videoTitle;

#pragma mark - Track

/**
 * @brief 可用轨道信息准备就绪时调用。
 *
 * @param tracks 可用清晰度轨道列表。
 */
- (void)playerDidTrackReady:(NSArray<TrackQuality *> *)tracks;

/**
 * @brief 轨道切换完成时调用。
 *
 * @param quality 切换后的轨道信息。
 */
- (void)playerDidTrackChanged:(TrackQuality *)quality;

@end

NS_ASSUME_NONNULL_END
