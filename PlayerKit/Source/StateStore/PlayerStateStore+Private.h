//
//  PlayerStateStore+Private.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerStateStore.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief PlayerStateStore 的私有更新方法。
 *
 * @discussion 这些方法仅供 MediaPlayer 实现内部使用。
 *             每个更新方法均包含自动去重处理。
 */
@interface PlayerStateStore (Private)

- (void)updatePlayState:(PlayerState)state;
- (void)updateDuration:(NSInteger)duration;
- (void)updateCurrentPosition:(NSInteger)position;
- (void)updateBufferedPosition:(NSInteger)position;
- (void)updateSpeed:(float)speed;
- (void)updateLoop:(BOOL)loop;
- (void)updateMuted:(BOOL)muted;
- (void)updateMirrorMode:(MirrorMode)mirrorMode;
- (void)updateScaleMode:(ScaleMode)scaleMode;
- (void)updateRotateMode:(RotateMode)rotateMode;
- (void)updateVideoWidth:(NSInteger)width height:(NSInteger)height;
- (void)updateTrackQualityList:(nullable NSArray<TrackQuality *> *)list;
- (void)updateSelectedTrackQuality:(nullable TrackQuality *)quality;

@end

NS_ASSUME_NONNULL_END
