//
//  PlayerStateStore.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaPlayer.h"
#import "MirrorMode.h"
#import "ScaleMode.h"
#import "RotateMode.h"

@class AliPlayerController;
@class TrackQuality;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器状态存储，持有当前播放状态。
 *
 * @discussion 提供对所有播放状态属性的只读访问。
 *             状态更新由 MediaPlayer 实现通过私有更新方法在内部执行。
 *             所有状态更新包含自动去重处理。
 *
 * @see AliPlayerController
 */
@interface PlayerStateStore : NSObject

/** @brief 当前播放状态。默认为 PlayerStateIdle。 */
@property (nonatomic, assign, readonly) PlayerState playState;

/** @brief 总时长，单位毫秒。默认为 0。 */
@property (nonatomic, assign, readonly) NSInteger duration;

/** @brief 当前播放位置，单位毫秒。默认为 0。 */
@property (nonatomic, assign, readonly) NSInteger currentPosition;

/** @brief 已缓冲位置，单位毫秒。默认为 0。 */
@property (nonatomic, assign, readonly) NSInteger bufferedPosition;

/** @brief 当前播放速度。默认为 1.0（正常速度）。 */
@property (nonatomic, assign, readonly) float speed;

/** @brief 是否启用循环播放。默认为 NO。 */
@property (nonatomic, assign, readonly, getter=isLoop) BOOL loop;

/** @brief 是否静音。默认为 NO。 */
@property (nonatomic, assign, readonly, getter=isMuted) BOOL muted;

/** @brief 当前镜像模式。默认为 MirrorModeNone。 */
@property (nonatomic, assign, readonly) MirrorMode mirrorMode;

/** @brief 当前缩放模式。默认为 ScaleModeCenterCrop。 */
@property (nonatomic, assign, readonly) ScaleMode scaleMode;

/** @brief 当前旋转角度。默认为 RotateModeDegree0。 */
@property (nonatomic, assign, readonly) RotateMode rotateMode;

/** @brief 视频原始宽度（像素）。默认为 0。 */
@property (nonatomic, assign, readonly) NSInteger videoWidth;

/** @brief 视频原始高度（像素）。默认为 0。 */
@property (nonatomic, assign, readonly) NSInteger videoHeight;

/** @brief 当前可用的清晰度轨道列表。默认为 nil。 */
@property (nonatomic, copy, readonly, nullable) NSArray<TrackQuality *> *trackQualityList;

/** @brief 当前选中的清晰度轨道。默认为 nil。 */
@property (nonatomic, strong, readonly, nullable) TrackQuality *selectedTrackQuality;

/** @brief 重置所有状态为默认值。 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
