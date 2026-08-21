//
//  PlayerNotificationDispatcher.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaPlayer.h"

@class TrackQuality;
@protocol PlayerNotificationDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 线程安全的播放器事件通知分发器。
 *
 * @discussion 管理一组遵循 PlayerNotificationDelegate 协议的弱引用观察者集合。
 *             使用串行分派队列确保对观察者列表的线程安全访问。
 *             通知始终在主线程上分派。
 *
 * @see PlayerNotificationDelegate
 */
@interface PlayerNotificationDispatcher : NSObject

/**
 * @brief 事件来源播放器的唯一标识符。
 *
 * @discussion 由 AliPlayerController 在配置 MediaPlayer 后写入，用于让观察者
 *             区分不同播放器实例的事件来源（不再持有 controller 引用）。
 */
@property (nonatomic, copy, nullable) NSString *playerId;

/**
 * @brief 添加通知观察者。
 *
 * @param observer 遵循 PlayerNotificationDelegate 协议的对象，不可为 nil。
 *
 * @discussion 观察者通过 NSHashTable 以弱引用方式存储。
 *             重复添加同一观察者不会产生效果。
 *
 * @see removeObserver:
 */
- (void)addObserver:(id<PlayerNotificationDelegate>)observer;

/**
 * @brief 移除通知观察者。
 *
 * @param observer 要移除的观察者。
 *
 * @discussion 如果观察者未注册，此方法不会产生任何效果。
 *
 * @see addObserver:
 */
- (void)removeObserver:(id<PlayerNotificationDelegate>)observer;

/**
 * @brief 移除所有已注册的观察者。
 *
 * @discussion 清空整个观察者列表。通常在清理或释放时调用。
 */
- (void)removeAllObservers;

/**
 * @brief 向所有已注册的观察者分发通知 Block。
 *
 * @param block 接收每个观察者作为参数的 Block。
 *
 * @discussion 先以线程安全方式获取当前观察者的快照，然后在主线程上对每个观察者
 *             调用该 Block。每次调用均用 @try/@catch 包裹，以防止某个观察者的
 *             异常影响其他观察者。
 */
- (void)notifyObservers:(void(^)(id<PlayerNotificationDelegate> observer))block;

/**
 * @brief 向所有实现了指定 selector 的观察者分发通知。
 *
 * @param selector 用于 respondsToSelector 检查的方法选择器。
 * @param block 对满足条件的观察者执行的操作。
 */
- (void)notifyObservers:(SEL)selector withBlock:(void(^)(id<PlayerNotificationDelegate> observer))block;

#pragma mark - Event Dispatch

/**
 * @brief 分发全屏状态变化通知。
 *
 * @param isFullscreen 当前是否处于全屏模式。
 *
 * @discussion 在主线程上向所有实现了 playerDidChangeFullscreen: 的
 *             观察者分发回调。单个观察者异常被隔离，不影响其他观察者。
 */
- (void)dispatchFullscreenChanged:(BOOL)isFullscreen;

#pragma mark - MediaPlayer Event Dispatch

- (void)dispatchDidChangeState:(PlayerState)state;
- (void)dispatchDidPreparedWithDuration:(NSInteger)duration;
- (void)dispatchDidRenderFirstFrame;
- (void)dispatchDidCompletion;
- (void)dispatchDidUpdatePosition:(NSInteger)position
                         duration:(NSInteger)duration
                 bufferedPosition:(NSInteger)bufferedPosition;
- (void)dispatchDidEncounterError:(NSError *)error;
- (void)dispatchDidCaptureScreenImage:(nullable UIImage *)image;
- (void)dispatchDidChangeVideoWidth:(NSInteger)width height:(NSInteger)height;
- (void)dispatchDidLoadingBegin;
- (void)dispatchDidLoadingEnd;
- (void)dispatchDidUpdateLoadingProgress:(float)progress;
- (void)dispatchDidTrackReady:(NSArray<TrackQuality *> *)tracks;
- (void)dispatchDidTrackChanged:(TrackQuality *)quality;

#pragma mark - Display Mode Dispatch

- (void)dispatchDidChangeMirrorMode:(MirrorMode)mirrorMode;
- (void)dispatchDidChangeScaleMode:(ScaleMode)scaleMode;
- (void)dispatchDidChangeRotateMode:(RotateMode)rotateMode;

#pragma mark - Thumbnail Dispatch

/**
 * @brief 分发缩略图 URL 就绪通知。
 *
 * @param thumbnailUrl 从媒体信息中提取的缩略图 URL，非空字符串。
 *
 * @discussion 在主线程上向所有实现了 @c playerDidReadyThumbnailUrl: 的
 *             观察者分发回调。
 *
 * @note 需要阿里云播放器 SDK 版本 ≥ 7.16.0。
 */
- (void)dispatchDidReadyThumbnailUrl:(NSString *)thumbnailUrl;
- (void)dispatchDidRetrieveThumbnail:(int64_t)positionMs
                               image:(UIImage *)image;

#pragma mark - Cover URL Dispatch

/**
 * @brief 分发封面图 URL 就绪通知。
 *
 * @param coverUrl 从媒体信息中提取的封面图 URL，非空字符串。
 *
 * @discussion 在主线程上向所有实现了 @c playerDidReadyCoverUrl: 的
 *             观察者分发回调。仅 Vid 播放方式下有效。
 *
 * @note 需要阿里云播放器 SDK 版本 ≥ 7.16.0。
 */
- (void)dispatchDidReadyCoverUrl:(NSString *)coverUrl;

#pragma mark - Video Title Dispatch

/**
 * @brief 分发视频标题就绪通知。
 *
 * @param videoTitle 从媒体信息中提取的视频标题，非空字符串。
 *
 * @discussion 在主线程上向所有实现了 @c playerDidReadyVideoTitle: 的
 *             观察者分发回调。仅 Vid 播放方式下有效。
 *
 * @note 需要阿里云播放器 SDK 版本 ≥ 7.16.0。
 */
- (void)dispatchDidReadyVideoTitle:(NSString *)videoTitle;

/**
 * @brief 返回当前已注册的观察者数量。
 *
 * @return 活跃观察者的数量。
 *
 * @discussion 此数量反映调用时刻的活跃（未被释放）观察者数。
 */
- (NSUInteger)observerCount;

@end

NS_ASSUME_NONNULL_END
