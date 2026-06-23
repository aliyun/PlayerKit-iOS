//
//  PlayerStateStore.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerStateStore.h"
#import "TrackQuality.h"
#import "Log.h"
#import <os/lock.h>

@interface PlayerStateStore ()

@property (nonatomic, assign, readwrite) PlayerState playState;
@property (nonatomic, assign, readwrite) NSInteger duration;
@property (nonatomic, assign, readwrite) NSInteger currentPosition;
@property (nonatomic, assign, readwrite) NSInteger bufferedPosition;
@property (nonatomic, assign, readwrite) float speed;
@property (nonatomic, assign, readwrite, getter=isLoop) BOOL loop;
@property (nonatomic, assign, readwrite, getter=isMuted) BOOL muted;
@property (nonatomic, assign, readwrite) MirrorMode mirrorMode;
@property (nonatomic, assign, readwrite) ScaleMode scaleMode;
@property (nonatomic, assign, readwrite) RotateMode rotateMode;
@property (nonatomic, assign, readwrite) NSInteger videoWidth;
@property (nonatomic, assign, readwrite) NSInteger videoHeight;
@property (nonatomic, copy, readwrite, nullable) NSArray<TrackQuality *> *trackQualityList;
@property (nonatomic, strong, readwrite, nullable) TrackQuality *selectedTrackQuality;

@end

@implementation PlayerStateStore {
    os_unfair_lock _lock;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = OS_UNFAIR_LOCK_INIT;
        [self reset];

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Thread-Safe Getters

- (NSArray<TrackQuality *> *)trackQualityList {
    os_unfair_lock_lock(&_lock);
    NSArray<TrackQuality *> *list = _trackQualityList;
    os_unfair_lock_unlock(&_lock);
    return list;
}

- (TrackQuality *)selectedTrackQuality {
    os_unfair_lock_lock(&_lock);
    TrackQuality *quality = _selectedTrackQuality;
    os_unfair_lock_unlock(&_lock);
    return quality;
}

#pragma mark - Public Methods

- (void)reset {
    os_unfair_lock_lock(&_lock);
    _playState = PlayerStateIdle;
    _duration = 0;
    _currentPosition = 0;
    _bufferedPosition = 0;
    _speed = 1.0f;
    _loop = NO;
    _muted = NO;
    _mirrorMode = MirrorModeNone;
    _scaleMode = ScaleModeFitCenter;
    _rotateMode = RotateModeDegree0;
    _videoWidth = 0;
    _videoHeight = 0;
    _trackQualityList = nil;
    _selectedTrackQuality = nil;
    os_unfair_lock_unlock(&_lock);
}

#pragma mark - Private Methods

- (void)updatePlayState:(PlayerState)state {
    os_unfair_lock_lock(&_lock);
    if (_playState == state) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updatePlayState: %ld -> %ld", (long)_playState, (long)state);
    _playState = state;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateDuration:(NSInteger)duration {
    os_unfair_lock_lock(&_lock);
    if (_duration == duration) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateDuration: %ld", (long)duration);
    _duration = duration;
    os_unfair_lock_unlock(&_lock);
}

// 高频更新，不输出日志以避免日志洪泛
- (void)updateCurrentPosition:(NSInteger)position {
    os_unfair_lock_lock(&_lock);
    if (_currentPosition == position) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    _currentPosition = position;
    os_unfair_lock_unlock(&_lock);
}

// 高频更新，不输出日志以避免日志洪泛
- (void)updateBufferedPosition:(NSInteger)position {
    os_unfair_lock_lock(&_lock);
    if (_bufferedPosition == position) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    _bufferedPosition = position;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateSpeed:(float)speed {
    os_unfair_lock_lock(&_lock);
    if (_speed == speed) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateSpeed: %.2f -> %.2f", _speed, speed);
    _speed = speed;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateLoop:(BOOL)loop {
    os_unfair_lock_lock(&_lock);
    if (_loop == loop) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateLoop: %@ -> %@", _loop ? @"YES" : @"NO", loop ? @"YES" : @"NO");
    _loop = loop;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateMuted:(BOOL)muted {
    os_unfair_lock_lock(&_lock);
    if (_muted == muted) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateMuted: %@ -> %@", _muted ? @"YES" : @"NO", muted ? @"YES" : @"NO");
    _muted = muted;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateMirrorMode:(MirrorMode)mirrorMode {
    os_unfair_lock_lock(&_lock);
    if (_mirrorMode == mirrorMode) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateMirrorMode: %ld -> %ld", (long)_mirrorMode, (long)mirrorMode);
    _mirrorMode = mirrorMode;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateScaleMode:(ScaleMode)scaleMode {
    os_unfair_lock_lock(&_lock);
    if (_scaleMode == scaleMode) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateScaleMode: %ld -> %ld", (long)_scaleMode, (long)scaleMode);
    _scaleMode = scaleMode;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateRotateMode:(RotateMode)rotateMode {
    os_unfair_lock_lock(&_lock);
    if (_rotateMode == rotateMode) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateRotateMode: %ld -> %ld", (long)_rotateMode, (long)rotateMode);
    _rotateMode = rotateMode;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateVideoWidth:(NSInteger)width height:(NSInteger)height {
    os_unfair_lock_lock(&_lock);
    if (_videoWidth == width && _videoHeight == height) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateVideoSize: %ldx%ld -> %ldx%ld", (long)_videoWidth, (long)_videoHeight, (long)width, (long)height);
    _videoWidth = width;
    _videoHeight = height;
    os_unfair_lock_unlock(&_lock);
}

- (void)updateTrackQualityList:(nullable NSArray<TrackQuality *> *)list {
    os_unfair_lock_lock(&_lock);
    SLOGI(@"updateTrackQualityList: %lu tracks", (unsigned long)list.count);
    _trackQualityList = [list copy];
    os_unfair_lock_unlock(&_lock);
}

- (void)updateSelectedTrackQuality:(nullable TrackQuality *)quality {
    os_unfair_lock_lock(&_lock);
    if (_selectedTrackQuality == quality) {
        os_unfair_lock_unlock(&_lock);
        return;
    }
    SLOGI(@"updateSelectedTrackQuality: index=%ld", (long)(quality ? quality.index : -1));
    _selectedTrackQuality = quality;
    os_unfair_lock_unlock(&_lock);
}

@end
