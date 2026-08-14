//
//  AliPlayerController.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AliPlayerController.h"
#import "AliPlayerController+Private.h"
#import "AliPlayerModel.h"
#import "AliPlayerKit.h"
#import "AliPlayerView.h"
#import "DefaultLifecycleStrategy.h"
#import "FullscreenTransition.h"
#import "PlayerLifecycleStrategy.h"
#import "GlobalManager.h"
#import "PlayerNotificationDispatcher.h"
#import "PlayerStateStore.h"
#import "PlayerStateStore+Private.h"
#import "PlayerViewState.h"
#import "TrackQuality.h"
#import "StrategyManager.h"
#import "StrategyRegistry.h"
#import "VideoSource.h"
#import "Log.h"

@interface AliPlayerController ()

@property (nonatomic, strong, readwrite, nullable) AliPlayerModel *playerModel;
@property (nonatomic, strong, readwrite) id<PlayerLifecycleStrategy> lifecycleStrategy;
@property (nonatomic, strong, nullable) id<MediaPlayer> mediaPlayer;
@property (nonatomic, copy, nullable) NSString *currentUniqueId;
@property (nonatomic, assign) BOOL wasPlayingBeforePause;
@property (nonatomic, strong) PlayerNotificationDispatcher *notificationDispatcher;
@property (nonatomic, strong, readwrite) StrategyManager *strategyManager;
@property (nonatomic, weak, nullable) AliPlayerView *playerView;
@property (nonatomic, assign) BOOL lifecycleObserversRegistered;

@end

@implementation AliPlayerController

#pragma mark - Lifecycle

- (instancetype)init {
    return [self initWithLifecycleStrategy:[[DefaultLifecycleStrategy alloc] init]];
}

- (instancetype)initWithLifecycleStrategy:(id<PlayerLifecycleStrategy>)strategy {
    self = [super init];
    if (self) {
        // 防护：确保 SDK 全局初始化已执行，即使客户未调用 AliPlayerKit.setup
        [GlobalManager setup];

        _lifecycleStrategy = strategy;
        [_lifecycleStrategy setupWithFactory:[AliPlayerKit playerFactory]];

        _wasPlayingBeforePause = NO;
        _autoLifecycleManagement = YES;
        _lifecycleObserversRegistered = NO;
        _notificationDispatcher = [[PlayerNotificationDispatcher alloc] init];
        _strategyManager = [[StrategyManager alloc] init];
        [[StrategyRegistry sharedRegistry] applyToManager:_strategyManager];

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    [self destroy];

    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Public Methods

// 将 currentPosition 委托给底层媒体播放器
- (NSInteger)currentPosition {
    return self.mediaPlayer ? self.mediaPlayer.currentPosition : 0;
}

- (PlayerState)playerState {
    return self.stateStore.playState;
}

// 将 duration 委托给底层媒体播放器
- (NSInteger)duration {
    return self.mediaPlayer ? self.mediaPlayer.duration : 0;
}

// 将 stateStore 转发给底层媒体播放器
- (PlayerStateStore *)stateStore {
    return self.mediaPlayer.stateStore;
}

- (void)configure:(AliPlayerModel *)model {
    // 判断是否为重新配置（切换视频源）
    BOOL isReconfigure = (self.mediaPlayer != nil);

    // 回收已有播放器（非强制，由策略决定销毁或复用）
    if (self.mediaPlayer) {
        self.mediaPlayer.notificationDispatcher = nil;
        id<PlayerLifecycleStrategy> strategy = self.lifecycleStrategy;
        if (self.currentUniqueId && strategy && [strategy respondsToSelector:@selector(recyclePlayer:uniqueId:force:)]) {
            [strategy recyclePlayer:self.mediaPlayer uniqueId:self.currentUniqueId force:NO];
        } else if (strategy) {
            [strategy recyclePlayer:self.mediaPlayer force:NO];
        }
        self.mediaPlayer = nil;
    }

    self.playerModel = model;

    // 通过生命周期策略获取播放器（可能是新建或复用的实例）
    id<PlayerLifecycleStrategy> strategy = self.lifecycleStrategy;
    NSString *uniqueId = model.videoSource.uniqueId;
    if (uniqueId && strategy && [strategy respondsToSelector:@selector(acquirePlayerWithUniqueId:)]) {
        self.mediaPlayer = [strategy acquirePlayerWithUniqueId:uniqueId];
    } else if (strategy) {
        self.mediaPlayer = [strategy acquirePlayer];
    }
    self.currentUniqueId = uniqueId;

    // 设置事件分发器，确保在 prepare 之前不会错过早期事件
    self.notificationDispatcher.playerId = self.mediaPlayer.playerId;
    self.mediaPlayer.notificationDispatcher = self.notificationDispatcher;

    // 设置数据源
    [self.mediaPlayer setDataSource:model];

    // 在 prepare 前触发实例级自定义配置回调
    if (model.onPlayerConfigBlock) {
        model.onPlayerConfigBlock(self.mediaPlayer);
    }

    // 策略系统生命周期（必须在 prepare 之前启动，否则会错过 PlayerStatePreparing 事件）
    if (isReconfigure) {
        [self.strategyManager resetWithPlayerModel:model];
    } else {
        [self.strategyManager startWithController:self playerModel:model];
    }

    [self.mediaPlayer prepare];

    [self registerLifecycleObserversIfNeeded];
}

- (void)bindRenderView:(UIView *)renderView {
    if (self.mediaPlayer) {
        self.mediaPlayer.playerView = renderView;
    }
}

- (void)play {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer start];
}

- (void)pause {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer pause];
}

- (void)seekTo:(NSInteger)position {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer seekTo:position];
}

- (void)setRate:(float)rate {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setSpeed:rate];
}

- (void)setLoop:(BOOL)loop {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setLoop:loop];
}

- (void)setMuted:(BOOL)muted {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setMuted:muted];
}

- (void)setMirrorMode:(MirrorMode)mirrorMode {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setMirrorMode:mirrorMode];
}

- (void)setScaleMode:(ScaleMode)scaleMode {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setScaleMode:scaleMode];
}

- (void)setRotateMode:(RotateMode)rotateMode {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setRotateMode:rotateMode];
}

- (void)setControlsVisible:(BOOL)visible {
    if (!visible && self.controlsVisibilityLocked) {
        return;
    }
    if (self.playerView.viewState.controlsVisible == visible) {
        return;
    }
    [self.playerView.viewState updateControlsVisible:visible];
    [self.notificationDispatcher notifyObservers:^(id<PlayerNotificationDelegate> observer) {
        if (observer && [observer respondsToSelector:@selector(playerDidChangeControlsVisible:)]) {
            [observer playerDidChangeControlsVisible:visible];
        }
    }];
}

- (void)setFullscreen:(BOOL)fullscreen {
    [self setFullscreen:fullscreen animated:YES];
}

- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated {
    // 状态相同则直接返回，避免重复过渡
    if (self.playerView.viewState.isFullscreen == fullscreen) {
        return;
    }

    // 状态先更新，保证 UI 层及记录者可立即读取最新全屏状态
    [self.playerView.viewState updateFullscreen:fullscreen];

    AliPlayerView *playerView = self.playerView;
    id<FullscreenTransition> transition = playerView.fullscreenTransition;

    // 过渡完成后统一分发通知，确保状态与视觉同步
    __weak typeof(self) weakSelf = self;
    void (^completion)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.notificationDispatcher dispatchFullscreenChanged:fullscreen];
    };

    // 未关联 view 或过渡实现不可用时，仅更新状态并分发通知
    if (!playerView || !transition) {
        completion();
        return;
    }

    if (fullscreen) {
        [transition enterFullscreenWithPlayerView:playerView
                                         animated:animated
                                       completion:completion];
    } else {
        [transition exitFullscreenWithPlayerView:playerView
                                        animated:animated
                                      completion:completion];
    }
}

- (void)selectTrack:(TrackQuality *)quality {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer selectTrack:quality];
}

- (void)snapshot {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer snapshot];
}

- (void)setThumbnailUrl:(NSString *)url {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer setThumbnailUrl:url];
}

- (void)requestThumbnailAtPosition:(int64_t)positionMs {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer requestThumbnailAtPosition:positionMs];
}

- (void)toggle {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer toggle];
}

- (void)replay {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer replay];
}

- (void)stop {
    if (!self.mediaPlayer) return;
    [self.mediaPlayer stop];
}

- (void)onResume {
    if (self.wasPlayingBeforePause) {
        [self play];
    }
    self.wasPlayingBeforePause = NO;
}

- (void)onPause {
    if (self.mediaPlayer && self.mediaPlayer.state == PlayerStatePlaying) {
        self.wasPlayingBeforePause = YES;
        [self pause];
    } else {
        self.wasPlayingBeforePause = NO;
    }
}

- (void)destroy {
    // 根据 playerView 生命周期自动解绑，确保 slot 插槽系统正确清理。
    // 即使外部未主动调用 detach，内部也会回收渲染视图等相关资源。
    [self.playerView detach];

    [self unregisterLifecycleObservers];
    [self.strategyManager destroy];

    if (self.mediaPlayer) {
        // 与 configure: 中回收旧 player 前的处理保持一致：先解绑 dispatcher，避免被回收/复用的 player 仍持有当前 controller 的 dispatcher
        self.mediaPlayer.notificationDispatcher = nil;
        id<PlayerLifecycleStrategy> strategy = self.lifecycleStrategy;
        if (self.currentUniqueId && strategy && [strategy respondsToSelector:@selector(recyclePlayer:uniqueId:force:)]) {
            [strategy recyclePlayer:self.mediaPlayer uniqueId:self.currentUniqueId force:YES];
        } else if (strategy) {
            [strategy recyclePlayer:self.mediaPlayer force:YES];
        }
        self.mediaPlayer = nil;
        self.currentUniqueId = nil;
    }
    self.playerModel = nil;
    self.wasPlayingBeforePause = NO;
    [self.notificationDispatcher removeAllObservers];
}

#pragma mark - Auto Lifecycle Management

- (void)setAutoLifecycleManagement:(BOOL)autoLifecycleManagement {
    if (_autoLifecycleManagement == autoLifecycleManagement) return;
    _autoLifecycleManagement = autoLifecycleManagement;

    if (autoLifecycleManagement) {
        [self registerLifecycleObserversIfNeeded];
    } else {
        [self unregisterLifecycleObservers];
    }
}

- (void)registerLifecycleObserversIfNeeded {
    if (!self.autoLifecycleManagement || self.lifecycleObserversRegistered) return;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    self.lifecycleObserversRegistered = YES;
}

- (void)unregisterLifecycleObservers {
    if (!self.lifecycleObserversRegistered) return;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self
                      name:UIApplicationWillResignActiveNotification
                    object:nil];
    [center removeObserver:self
                      name:UIApplicationDidBecomeActiveNotification
                    object:nil];
    self.lifecycleObserversRegistered = NO;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self onPause];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self onResume];
}

#pragma mark - Notification

- (void)addNotificationDelegate:(id<PlayerNotificationDelegate>)delegate {
    [self.notificationDispatcher addObserver:delegate];
}

- (void)removeNotificationDelegate:(id<PlayerNotificationDelegate>)delegate {
    [self.notificationDispatcher removeObserver:delegate];
}

@end
