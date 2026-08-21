//
//  PlayerNotificationDispatcher.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerNotificationDispatcher.h"
#import "PlayerNotificationDelegate.h"
#import "TrackQuality.h"
#import "Log.h"
#import <os/lock.h>

@interface PlayerNotificationDispatcher ()

@property (nonatomic, strong) NSHashTable<id<PlayerNotificationDelegate>> *observers;

@end

@implementation PlayerNotificationDispatcher {
    os_unfair_lock _lock;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _lock = OS_UNFAIR_LOCK_INIT;

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Public Methods

- (void)addObserver:(id<PlayerNotificationDelegate>)observer {
    if (!observer) return;
    os_unfair_lock_lock(&_lock);
    if (![self.observers containsObject:observer]) {
        [self.observers addObject:observer];
    }
    os_unfair_lock_unlock(&_lock);
}

- (void)removeObserver:(id<PlayerNotificationDelegate>)observer {
    if (!observer) return;
    os_unfair_lock_lock(&_lock);
    [self.observers removeObject:observer];
    os_unfair_lock_unlock(&_lock);
}

- (void)removeAllObservers {
    os_unfair_lock_lock(&_lock);
    [self.observers removeAllObjects];
    os_unfair_lock_unlock(&_lock);
}

- (void)notifyObservers:(void(^)(id<PlayerNotificationDelegate> observer))block {
    if (!block) return;

    os_unfair_lock_lock(&_lock);
    NSArray<id<PlayerNotificationDelegate>> *snapshot = [self.observers allObjects];
    os_unfair_lock_unlock(&_lock);

    if (snapshot.count == 0) return;

    // Dispatch to main thread
    if ([NSThread isMainThread]) {
        for (id<PlayerNotificationDelegate> observer in snapshot) {
            @try {
                block(observer);
            } @catch (NSException *exception) {
                SLOGW(@"observer exception - %@", exception);
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<PlayerNotificationDelegate> observer in snapshot) {
                @try {
                    block(observer);
                } @catch (NSException *exception) {
                    SLOGW(@"observer exception - %@", exception);
                }
            }
        });
    }
}

- (void)notifyObservers:(SEL)selector withBlock:(void(^)(id<PlayerNotificationDelegate> observer))block {
    [self notifyObservers:^(id<PlayerNotificationDelegate> observer) {
        if ([observer respondsToSelector:selector]) {
            block(observer);
        }
    }];
}

- (NSUInteger)observerCount {
    os_unfair_lock_lock(&_lock);
    NSUInteger count = self.observers.count;
    os_unfair_lock_unlock(&_lock);
    return count;
}

#pragma mark - Event Dispatch

- (void)dispatchFullscreenChanged:(BOOL)isFullscreen {
    [self notifyObservers:^(id<PlayerNotificationDelegate> observer) {
        if (observer && [observer respondsToSelector:@selector(playerDidChangeFullscreen:)]) {
            [observer playerDidChangeFullscreen:isFullscreen];
        }
    }];
}

#pragma mark - MediaPlayer Event Dispatch

- (void)dispatchDidChangeState:(PlayerState)state {
    [self notifyObservers:@selector(playerDidChangeState:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidChangeState:state];
    }];
}

- (void)dispatchDidPreparedWithDuration:(NSInteger)duration {
    [self notifyObservers:@selector(playerDidPreparedWithDuration:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidPreparedWithDuration:duration];
    }];
}

- (void)dispatchDidRenderFirstFrame {
    [self notifyObservers:@selector(playerDidRenderFirstFrame)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidRenderFirstFrame];
    }];
}

- (void)dispatchDidCompletion {
    [self notifyObservers:@selector(playerDidCompletion)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidCompletion];
    }];
}

- (void)dispatchDidUpdatePosition:(NSInteger)position
                         duration:(NSInteger)duration
                 bufferedPosition:(NSInteger)bufferedPosition {
    [self notifyObservers:@selector(playerDidUpdateCurrentPosition:duration:bufferedPosition:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidUpdateCurrentPosition:position
                                        duration:duration
                                bufferedPosition:bufferedPosition];
    }];
}

- (void)dispatchDidEncounterError:(NSError *)error {
    [self notifyObservers:@selector(playerDidEncounterError:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidEncounterError:error];
    }];
}

- (void)dispatchDidCaptureScreenImage:(UIImage *)image {
    [self notifyObservers:@selector(playerDidCompleteSnapshot:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidCompleteSnapshot:image];
    }];
}

- (void)dispatchDidChangeVideoWidth:(NSInteger)width height:(NSInteger)height {
    [self notifyObservers:@selector(playerDidChangeVideoWidth:height:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidChangeVideoWidth:width height:height];
    }];
}

- (void)dispatchDidLoadingBegin {
    [self notifyObservers:@selector(playerDidLoadingBegin)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidLoadingBegin];
    }];
}

- (void)dispatchDidLoadingEnd {
    [self notifyObservers:@selector(playerDidLoadingEnd)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidLoadingEnd];
    }];
}

- (void)dispatchDidUpdateLoadingProgress:(float)progress {
    [self notifyObservers:@selector(playerDidUpdateLoadingProgress:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidUpdateLoadingProgress:progress];
    }];
}

- (void)dispatchDidTrackReady:(NSArray<TrackQuality *> *)tracks {
    [self notifyObservers:@selector(playerDidTrackReady:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidTrackReady:tracks];
    }];
}

- (void)dispatchDidTrackChanged:(TrackQuality *)quality {
    [self notifyObservers:@selector(playerDidTrackChanged:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidTrackChanged:quality];
    }];
}

#pragma mark - Display Mode Dispatch

- (void)dispatchDidChangeMirrorMode:(MirrorMode)mirrorMode {
    [self notifyObservers:@selector(playerDidChangeMirrorMode:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidChangeMirrorMode:mirrorMode];
    }];
}

- (void)dispatchDidChangeScaleMode:(ScaleMode)scaleMode {
    [self notifyObservers:@selector(playerDidChangeScaleMode:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidChangeScaleMode:scaleMode];
    }];
}

- (void)dispatchDidChangeRotateMode:(RotateMode)rotateMode {
    [self notifyObservers:@selector(playerDidChangeRotateMode:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidChangeRotateMode:rotateMode];
    }];
}

#pragma mark - Thumbnail Dispatch

- (void)dispatchDidReadyThumbnailUrl:(NSString *)thumbnailUrl {
    [self notifyObservers:@selector(playerDidReadyThumbnailUrl:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidReadyThumbnailUrl:thumbnailUrl];
    }];
}

- (void)dispatchDidRetrieveThumbnail:(int64_t)positionMs
                               image:(UIImage *)image {
    [self notifyObservers:@selector(playerDidRetrieveThumbnail:image:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidRetrieveThumbnail:positionMs
                                       image:image];
    }];
}

#pragma mark - Cover URL Dispatch

- (void)dispatchDidReadyCoverUrl:(NSString *)coverUrl {
    [self notifyObservers:@selector(playerDidReadyCoverUrl:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidReadyCoverUrl:coverUrl];
    }];
}

#pragma mark - Video Title Dispatch

- (void)dispatchDidReadyVideoTitle:(NSString *)videoTitle {
    [self notifyObservers:@selector(playerDidReadyVideoTitle:)
                withBlock:^(id<PlayerNotificationDelegate> observer) {
        [observer playerDidReadyVideoTitle:videoTitle];
    }];
}

@end
