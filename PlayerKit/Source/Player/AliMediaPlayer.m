//
//  AliMediaPlayer.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AliMediaPlayer.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "TrackQuality.h"
#import "PlayerStateStore+Private.h"
#import "PlayerNotificationDispatcher.h"
#import "ScenarioManager.h"
#import "Log.h"

#if __has_include(<AliVCSDK_Standard/AliVCSDK_Standard.h>)
#import <AliVCSDK_Standard/AliVCSDK_Standard.h>

#elif __has_include(<AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>)
#import <AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>

#elif __has_include(<AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>)
#import <AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>

#elif __has_include(<AliVCSDK_UGC/AliVCSDK_UGC.h>)
#import <AliVCSDK_UGC/AliVCSDK_UGC.h>

#endif

#if __has_include(<AliyunPlayer/AliyunPlayer.h>)
#import <AliyunPlayer/AliyunPlayer.h>
#endif

// ==================== 最佳实践参考 ====================
// 本文件中的播放器 API 调用流程参考自 API-Example 中的 BasicPlayback 示例代码，
// 符合阿里云播放器 SDK 的最佳实践。
//
// 参考代码路径：
// - API-Example/BasicPlayback/Source/BasicPlaybackViewController.h
// - API-Example/BasicPlayback/Source/BasicPlaybackViewController.m
//
// 播放器 API 调用步骤：
// Step 1: 创建播放器实例 — [[AliPlayer alloc] init]，设置 playerView、playerScene、traceId
// Step 2: 设置播放源 — setUrlSource / setStsSource / setAuthSource
// Step 3: 准备和播放 — prepare + start（prepare 后可同步调用 start，onPrepared 回调完成后自动起播）
// Step 4: 资源清理 — stop + destroy（通用场景）或 destroyAsync（短视频场景，异步释放，不阻塞线程）
// ==================== End ====================

#pragma mark - RTS 低延迟直播配置常量

/// RTS 流地址前缀
static NSString *const kRTSStreamURLPrefix = @"artc://";

/// 播放器允许的最大延迟时间，单位：毫秒
/// 超过该延迟会触发追帧/丢帧以降低整体延迟
static const int kRTSMaxDelayTimeMs = 1000;

/// 起播时的最小缓冲时长，单位：毫秒
/// 值越小，起播越快，但对网络抖动的容忍度越低
static const int kRTSStartBufferDurationMs = 10;

/// 卡顿恢复时的最大缓冲上限，单位：毫秒
/// 控制追帧时的缓冲大小，保证低延迟优先
static const int kRTSHighBufferDurationMs = 10;

@interface AliMediaPlayer () <AVPDelegate>

@property (nonatomic, assign, readwrite) PlayerState state;
@property (nonatomic, assign, readwrite) float speed;
@property (nonatomic, assign, readwrite, getter=isLoop) BOOL loop;
@property (nonatomic, assign, readwrite, getter=isMuted) BOOL muted;
@property (nonatomic, assign, readwrite) MirrorMode mirrorMode;
@property (nonatomic, assign, readwrite) ScaleMode scaleMode;
@property (nonatomic, assign, readwrite) RotateMode rotateMode;
@property (nonatomic, assign) NSInteger bufferedPosition;
@property (nonatomic, strong) PlayerStateStore *stateStoreInternal;

@end

@implementation AliMediaPlayer {
    AliPlayer *_aliPlayer;
    AliPlayerModel *_playerModel;
}

@synthesize playerId = _playerId;
@synthesize playerView = _playerView;
@synthesize notificationDispatcher = _notificationDispatcher;
@synthesize speed = _speed;
@synthesize loop = _loop;
@synthesize muted = _muted;
@synthesize mirrorMode = _mirrorMode;
@synthesize scaleMode = _scaleMode;
@synthesize rotateMode = _rotateMode;
@synthesize bufferedPosition = _bufferedPosition;

// MediaPlayer 协议要求提供 stateStore getter
- (PlayerStateStore *)stateStore {
    return self.stateStoreInternal;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = PlayerStateIdle;
        _speed = 1.0f;
        _loop = NO;
        _muted = NO;
        _mirrorMode = MirrorModeNone;
        _scaleMode = ScaleModeFitCenter;
        _rotateMode = RotateModeDegree0;
        _stateStoreInternal = [[PlayerStateStore alloc] init];

        // 创建播放器实例
        _aliPlayer = [[AliPlayer alloc] init];
        _aliPlayer.delegate = self;

        _playerId = [NSString stringWithFormat:@"%@@%lx",
                     NSStringFromClass([_aliPlayer class]),
                     (unsigned long)_aliPlayer];
        SLOGI(@"Player created (%@), _playerId=%@", self, _playerId);
        
        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    [self destroy];
    
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - Getters & Setters

// 返回底层 SDK 当前播放位置（毫秒）
- (NSInteger)currentPosition {
    if (!_aliPlayer) return 0;
    return (NSInteger)_aliPlayer.currentPosition;
}

// 返回底层 SDK 总时长（毫秒）
- (NSInteger)duration {
    if (!_aliPlayer) return 0;
    return (NSInteger)_aliPlayer.duration;
}

// 外部设置时同步渲染视图到底层 SDK
- (void)setPlayerView:(UIView *)playerView {
    _playerView = playerView;
    if (!_aliPlayer) return;
    _aliPlayer.playerView = playerView;
    SLOGI(@"[player][API][setPlayerView], playerView=%@", playerView);
}

#pragma mark - MediaPlayer

- (void)setDataSource:(AliPlayerModel *)model {
    if (!_aliPlayer) return;

    SLOGI(@"setDataSource, %@", model ?: @"");

    _playerModel = model;

    // 设置播放场景，用于播放器内部的场景化优化
    AVPScene playerScene = [self playerSceneFromSceneType:model.sceneType];
    [_aliPlayer setPlayerScene:playerScene];
    SLOGI(@"[player][API][setPlayerScene], scene=%ld", (long)playerScene);

    // 配置 autoPlay
    [_aliPlayer setAutoPlay:model.autoPlay];
    SLOGI(@"[player][API][setAutoPlay], autoPlay=%@", model.autoPlay ? @"YES" : @"NO");

    // 配置硬解
    [_aliPlayer setEnableHardwareDecoder:model.hardwareDecode];
    SLOGI(@"[player][API][setEnableHardwareDecoder], enable=%@", model.hardwareDecode ? @"YES" : @"NO");

    // 配置 traceId（单点追查）
    // 推荐使用`播放器单点追查`功能，当使用阿里云播放器 SDK 播放视频发生异常时，
    // 可借助单点追查功能针对具体某个用户或某次播放会话的异常播放行为进行全链路追踪，
    // 以便您能快速诊断问题原因，可有效改善播放体验治理效率。
    // traceId 值由您自行定义，需为您的用户或用户设备的唯一标识符，
    // 例如传入您业务的 userid 或者 IMEI、IDFA 等您业务用户的设备 ID。
    // 传入 traceId 后，埋点日志上报功能开启，后续可以使用播放质量监控、单点追查和视频播放统计功能。
    // 文档：https://help.aliyun.com/zh/vod/developer-reference/single-point-tracing
    if (model.traceId && model.traceId.length > 0) {
        [_aliPlayer setTraceID:model.traceId];
        SLOGI(@"[player][API][setTraceID], traceId=%@", model.traceId);
    }

    // 根据视频源类型设置不同的播放源
    VideoSource *source = model.videoSource;
    switch (source.sourceType) {
        case VideoSourceTypeUrl: {
            AVPUrlSource *urlSource = [[AVPUrlSource alloc] urlWithString:source.url];
            [_aliPlayer setUrlSource:urlSource];
            SLOGI(@"[player][API][setUrlSource], url=%@", source.url);

            // RTS 超低延迟直播相关的特殊配置
            if ([source.url hasPrefix:kRTSStreamURLPrefix]) {
                AVPConfig *config = [_aliPlayer getConfig];
                config.maxDelayTime = kRTSMaxDelayTimeMs;
                config.startBufferDuration = kRTSStartBufferDurationMs;
                config.highBufferDuration = kRTSHighBufferDurationMs;
                [_aliPlayer setConfig:config];
                SLOGI(@"[player][API][setConfig], RTS config applied");

                // 全局设置：启用 RTS 自动降级功能（默认已开启）
                // 当网络不佳时，自动切换至普通直播流保障连续性
                [AliPlayerGlobalSettings setOption:ALLOW_RTS_DEGRADE valueInt:1];
                SLOGI(@"[player][API][setGlobalOption], ALLOW_RTS_DEGRADE=1");

                SLOGI(@"RTS low-latency live streaming optimization has been enabled.");
            }
            break;
        }
        case VideoSourceTypeVidSts: {
            AVPVidStsSource *stsSource = [[AVPVidStsSource alloc] init];
            stsSource.vid = source.vid;
            stsSource.accessKeyId = source.accessKeyId;
            stsSource.accessKeySecret = source.accessKeySecret;
            stsSource.securityToken = source.securityToken;
            [_aliPlayer setStsSource:stsSource];
            SLOGI(@"[player][API][setStsSource], vid=%@", source.vid);
            break;
        }
        case VideoSourceTypeVidAuth: {
            AVPVidAuthSource *authSource = [[AVPVidAuthSource alloc] init];
            authSource.vid = source.vid;
            authSource.playAuth = source.playAuth;
            [_aliPlayer setAuthSource:authSource];
            SLOGI(@"[player][API][setAuthSource], vid=%@", source.vid);
            break;
        }
    }

    // 应用 SDK 内部能力识别数据，用于播放体验优化与问题诊断
    NSString *scenarioFlag = [ScenarioManager buildScenarioFlagWithSceneType:model.sceneType
                                                                  sourceType:source.sourceType];
    [_aliPlayer setOption:SCENARIO_FLAG value:scenarioFlag];
    SLOGI(@"[player][API][setOption], SCENARIO_FLAG=%@", scenarioFlag);

    // VideoList 场景启用预渲染以加速首帧显示
    if (model.sceneType == SceneTypeVideoList) {
        [_aliPlayer setOption:ALLOW_PRE_RENDER valueInt:1];
        SLOGI(@"[player][API][setOption], ALLOW_PRE_RENDER=1");
    }

    // 在 prepare 前设置起播位置
    if (model.startTime > 0) {
        [_aliPlayer setStartTime:model.startTime seekMode:AVP_SEEKMODE_ACCURATE];
        SLOGI(@"[player][API][setStartTime], startTime=%ldms", (long)model.startTime);
    }
}

- (void)prepare {
    if (!_aliPlayer) return;
    [self transitionToState:PlayerStatePreparing];
    // 调用 prepare 准备播放
    [_aliPlayer prepare];
    SLOGI(@"[player][API][prepare]");
}

- (void)start {
    if (!_aliPlayer) return;
    [_aliPlayer start];
    SLOGI(@"[player][API][start]");
}

- (void)pause {
    if (!_aliPlayer) return;
    [_aliPlayer pause];
    SLOGI(@"[player][API][pause]");
}

- (void)seekTo:(NSInteger)position {
    if (!_aliPlayer) return;
    [_aliPlayer seekToTime:position seekMode:AVP_SEEKMODE_ACCURATE];
    SLOGI(@"[player][API][seekToTime], position=%ldms", (long)position);
}

- (void)setSpeed:(float)speed {
    if (_speed == speed) {
        return;
    }
    _speed = speed;
    if (_aliPlayer) {
        [_aliPlayer setRate:speed];
        SLOGI(@"[player][API][setRate], rate=%.2f", speed);
    }
    [self.stateStoreInternal updateSpeed:speed];
}

- (void)setLoop:(BOOL)loop {
    if (_loop == loop) {
        return;
    }
    _loop = loop;
    if (_aliPlayer) {
        [_aliPlayer setLoop:loop];
        SLOGI(@"[player][API][setLoop], loop=%@", loop ? @"YES" : @"NO");
    }
    [self.stateStoreInternal updateLoop:loop];
}

- (void)setMuted:(BOOL)muted {
    if (_muted == muted) {
        return;
    }
    _muted = muted;
    if (_aliPlayer) {
        [_aliPlayer setMuted:muted];
        SLOGI(@"[player][API][setMuted], muted=%@", muted ? @"YES" : @"NO");
    }
    [self.stateStoreInternal updateMuted:muted];
}

- (void)setMirrorMode:(MirrorMode)mirrorMode {
    if (_mirrorMode == mirrorMode) {
        return;
    }
    _mirrorMode = mirrorMode;
    if (_aliPlayer) {
        [_aliPlayer setMirrorMode:(int)mirrorMode];
        SLOGI(@"[player][API][setMirrorMode], mode=%ld", (long)mirrorMode);
    }
    [self.stateStoreInternal updateMirrorMode:mirrorMode];
    [self.notificationDispatcher dispatchDidChangeMirrorMode:mirrorMode];
}

- (void)setScaleMode:(ScaleMode)scaleMode {
    if (_scaleMode == scaleMode) {
        return;
    }
    _scaleMode = scaleMode;
    if (_aliPlayer) {
        [_aliPlayer setScalingMode:(int)scaleMode];
        SLOGI(@"[player][API][setScalingMode], mode=%ld", (long)scaleMode);
    }
    [self.stateStoreInternal updateScaleMode:scaleMode];
    [self.notificationDispatcher dispatchDidChangeScaleMode:scaleMode];
}

- (void)setRotateMode:(RotateMode)rotateMode {
    if (_rotateMode == rotateMode) {
        return;
    }
    _rotateMode = rotateMode;
    if (_aliPlayer) {
        [_aliPlayer setRotateMode:(int)rotateMode];
        SLOGI(@"[player][API][setRotateMode], mode=%ld", (long)rotateMode);
    }
    [self.stateStoreInternal updateRotateMode:rotateMode];
    [self.notificationDispatcher dispatchDidChangeRotateMode:rotateMode];
}

- (void)selectTrack:(TrackQuality *)quality {
    if (!quality || !_aliPlayer) {
        return;
    }
    [_aliPlayer selectTrack:(int)quality.index accurate:YES];
    SLOGI(@"[player][API][selectTrack], index=%ld", (long)quality.index);
}

- (void)snapshot {
    if (!_aliPlayer) return;
    [_aliPlayer snapShot];
    SLOGI(@"[player][API][snapShot]");
}

- (void)setThumbnailUrl:(NSString *)url {
    if (!_aliPlayer) return;
    [_aliPlayer setThumbnailUrl:url];
    SLOGI(@"[player][API][setThumbnailUrl], url=%@", url);
}

- (void)requestThumbnailAtPosition:(int64_t)positionMs {
    if (!_aliPlayer) return;
    [_aliPlayer getThumbnail:positionMs];
}

- (void)toggle {
    SLOGI(@"toggle");
    switch (self.state) {
        case PlayerStatePlaying:
            [self pause];
            break;
        case PlayerStatePaused:
        case PlayerStatePrepared:
            [self start];
            break;
        case PlayerStateCompleted:
        case PlayerStateStopped:
            [self replay];
            break;
        default:
            break;
    }
}

- (void)replay {
    SLOGI(@"replay");
    // prepare 后可同步调用 start，onPrepared 回调完成后会自动起播
    [self prepare];
    [self start];
}

- (void)stop {
    if (!_aliPlayer) return;
    [_aliPlayer stop];
    SLOGI(@"[player][API][stop]");
    [self transitionToState:PlayerStateStopped];
}

- (void)destroy {
    if (!_aliPlayer) {
        SLOGW(@"Player already destroyed");
        return;
    }

    /**
     * 资源清理
     *
     * 方案1：stop + destroy，适用于通用场景；释放操作有耗时，会阻塞当前线程，直到资源完全释放。
     * 方案2：destroyAsync，无需手动 stop，适用于短剧等场景；异步释放资源，不阻塞线程，内部已自动调用 stop。
     * 注意：执行 destroy 或 destroyAsync 后，请不要再对播放器实例进行任何操作。
     */
    // 先清除代理，防止 stop/destroy 过程中收到残留回调
    _aliPlayer.delegate = nil;
    
    // destroy 前必须先清除渲染视图，避免 SDK 内部渲染视图未释放。
    // 否则 GPU / Metal 资源会随着播放器重复创建持续累积，导致 prepare 耗时递增。
    _aliPlayer.playerView = nil;
    SLOGI(@"[player][API][setPlayerView], playerView=(nil)");
    
    [_aliPlayer stop];
    SLOGI(@"[player][API][stop]");
    [_aliPlayer destroy];
    SLOGI(@"[player][API][destroy]");

    _aliPlayer = nil;
    _playerId = nil;
    _playerModel = nil;
    _playerView = nil;
    _bufferedPosition = 0;
    _speed = 1.0f;
    _loop = NO;
    _muted = NO;
    _mirrorMode = MirrorModeNone;
    _scaleMode = ScaleModeFitCenter;
    _rotateMode = RotateModeDegree0;
    [self.stateStoreInternal reset];
    _stateStoreInternal = nil;
    // 防御性清理：避免销毁后仍持有 dispatcher。外部 controller 路径已在回收前解绑，
    // 这里作为底层销毁的统一收尾，保证任意调用路径（如 dealloc）下都不会遗留引用
    self.notificationDispatcher = nil;
    self.state = PlayerStateIdle;
    
    SLOGI(@"Player destroyed (%@)", self);
}

#pragma mark - AVPDelegate

- (void)onPlayerEvent:(AliPlayer *)player eventType:(AVPEventType)eventType {
    switch (eventType) {
        case AVPEventPrepareDone:
            SLOGI(@"[player][CBK][PrepareDone]");
            [self transitionToState:PlayerStatePrepared];
            [self.stateStoreInternal updateDuration:(NSInteger)_aliPlayer.duration];
            [self.notificationDispatcher dispatchDidPreparedWithDuration:(NSInteger)_aliPlayer.duration];
            // 从媒体信息中提取缩略图 URL（Vid 播放时由控制台雪碧图自动提供），
            // 始终派发，去重由 Slot 侧完成
            [self dispatchThumbnailUrlIfAvailable];
            // 从媒体信息中提取封面图 URL 和视频标题（Vid 播放时由服务端自动提供）
            [self dispatchCoverUrlIfAvailable];
            [self dispatchVideoTitleIfAvailable];
            break;
        case AVPEventFirstRenderedStart:
            SLOGI(@"[player][CBK][FirstRenderedStart]");
            [self.notificationDispatcher dispatchDidRenderFirstFrame];
            break;
        case AVPEventCompletion:
            SLOGI(@"[player][CBK][Completion]");
            [self transitionToState:PlayerStateCompleted];
            [self.notificationDispatcher dispatchDidCompletion];
            break;
        case AVPEventLoadingStart:
            SLOGI(@"[player][CBK][LoadingStart]");
            [self.notificationDispatcher dispatchDidLoadingBegin];
            break;
        case AVPEventLoadingEnd:
            SLOGI(@"[player][CBK][LoadingEnd]");
            [self.notificationDispatcher dispatchDidLoadingEnd];
            break;
        default:
            break;
    }
}

- (void)onCurrentPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    // SDK 返回的 position 单位为毫秒
    [self.stateStoreInternal updateCurrentPosition:(NSInteger)position];
    [self.notificationDispatcher dispatchDidUpdatePosition:(NSInteger)position
                                                  duration:self.stateStoreInternal.duration
                                          bufferedPosition:self.bufferedPosition];
}

- (void)onBufferedPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    // 存储缓冲位置以供外部读取
    self.bufferedPosition = (NSInteger)position;
    [self.stateStoreInternal updateBufferedPosition:(NSInteger)position];
    [self.notificationDispatcher dispatchDidUpdatePosition:self.stateStoreInternal.currentPosition
                                                  duration:self.stateStoreInternal.duration
                                          bufferedPosition:(NSInteger)position];
}

- (void)onError:(AliPlayer *)player errorModel:(AVPErrorModel *)errorModel {
    SLOGE(@"[player][CBK][Error][%ld], %@", (long)errorModel.code, errorModel.message ?: @"unknown");
    [self transitionToState:PlayerStateError];

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (errorModel.message) {
        userInfo[NSLocalizedDescriptionKey] = errorModel.message;
    }
    if (errorModel.requestId) {
        userInfo[@"requestId"] = errorModel.requestId;
    }
    if (errorModel.videoId) {
        userInfo[@"videoId"] = errorModel.videoId;
    }
    if (errorModel.extra) {
        userInfo[@"extra"] = errorModel.extra;
    }
    NSError *error = [NSError errorWithDomain:@"com.aliyun.playerkit.player"
                                         code:errorModel.code
                                     userInfo:userInfo];
    [self.notificationDispatcher dispatchDidEncounterError:error];
}

- (void)onCaptureScreen:(AliPlayer *)player image:(UIImage *)image {
    SLOGI(@"[player][CBK][CaptureScreen]");
    [self.notificationDispatcher dispatchDidCaptureScreenImage:image];
}

- (void)onVideoSizeChanged:(AliPlayer *)player width:(int)width height:(int)height rotation:(int)rotation {
    SLOGI(@"[player][CBK][VideoSizeChanged], %dx%d, rotation=%d", width, height, rotation);
    [self.stateStoreInternal updateVideoWidth:width height:height];
    [self.notificationDispatcher dispatchDidChangeVideoWidth:width height:height];
}

- (void)onLoadingProgress:(AliPlayer *)player progress:(float)progress {
    [self.notificationDispatcher dispatchDidUpdateLoadingProgress:progress];
}

- (void)onTrackReady:(AliPlayer *)player info:(NSArray<AVPTrackInfo *> *)info {
    SLOGI(@"[player][CBK][TrackReady], tracks=%lu", (unsigned long)info.count);
    NSMutableArray<TrackQuality *> *tracks = [NSMutableArray array];
    for (AVPTrackInfo *trackInfo in info) {
        TrackType type;
        switch (trackInfo.trackType) {
            case AVPTRACK_TYPE_VIDEO:    type = TrackTypeVideo; break;
            case AVPTRACK_TYPE_AUDIO:    type = TrackTypeAudio; break;
            case AVPTRACK_TYPE_SUBTITLE: type = TrackTypeSubtitle; break;
            case AVPTRACK_TYPE_SAAS_VOD: type = TrackTypeVOD; break;
            default:                     type = TrackTypeUnknown; break;
        }
        TrackQuality *quality = [[TrackQuality alloc] initWithIndex:trackInfo.trackIndex
                                                               type:type
                                                              width:trackInfo.videoWidth
                                                             height:trackInfo.videoHeight];
        [tracks addObject:quality];
    }
    NSArray<TrackQuality *> *result = [tracks copy];
    [self.stateStoreInternal updateTrackQualityList:result];
    [self.notificationDispatcher dispatchDidTrackReady:result];
}

- (void)onTrackChanged:(AliPlayer *)player info:(AVPTrackInfo *)info {
    SLOGI(@"[player][CBK][TrackChanged], index=%d", info.trackIndex);
    TrackType type;
    switch (info.trackType) {
        case AVPTRACK_TYPE_VIDEO:    type = TrackTypeVideo; break;
        case AVPTRACK_TYPE_AUDIO:    type = TrackTypeAudio; break;
        case AVPTRACK_TYPE_SUBTITLE: type = TrackTypeSubtitle; break;
        case AVPTRACK_TYPE_SAAS_VOD: type = TrackTypeVOD; break;
        default:                     type = TrackTypeUnknown; break;
    }
    TrackQuality *quality = [[TrackQuality alloc] initWithIndex:info.trackIndex
                                                           type:type
                                                          width:info.videoWidth
                                                         height:info.videoHeight];
    [self.stateStoreInternal updateSelectedTrackQuality:quality];
    [self.notificationDispatcher dispatchDidTrackChanged:quality];
}

- (void)onPlayerStatusChanged:(AliPlayer *)player oldStatus:(AVPStatus)oldStatus newStatus:(AVPStatus)newStatus {
//    SLOGI(@"[player][CBK][StatusChanged][%lu->%lu]", (unsigned long)oldStatus, (unsigned long)newStatus);
    if (newStatus == AVPStatusInitialzed || newStatus == AVPStatusIdle) return;

    PlayerState mappedState = [self playerStateFromAVPStatus:newStatus];
    [self transitionToState:mappedState];
}

- (void)onGetThumbnailSuc:(int64_t)positionMs fromPos:(int64_t)fromPos toPos:(int64_t)toPos image:(id)image {
//    SLOGI(@"[player][CBK][GetThumbnailSuc], position=%lldms", positionMs);
    // iOS 平台 image 实际类型为 UIImage；dispatcher 内部保证主线程派发
    [self.notificationDispatcher dispatchDidRetrieveThumbnail:positionMs
                                                        image:(UIImage *)image];
}

#pragma mark - Private Methods

/**
 * 提取缩略图 URL
 *
 * 从 MediaInfo 中提取缩略图 URL，用于 Seek 时的缩略图预览。
 * 提取成功后通过 dispatcher 通知相关 Slot 初始化缩略图能力。
 *
 * SDK 版本要求：通过 getMediaInfo.thumbnails 获取缩略图 URL
 * 需要阿里云播放器 SDK 版本 ≥ 7.16.0，低版本 SDK 该接口可能返回 nil。
 */
- (void)dispatchThumbnailUrlIfAvailable {
    if (!_aliPlayer) return;
    AVPMediaInfo *mediaInfo = [_aliPlayer getMediaInfo];
    AVPThumbnailInfo *thumbnailInfo = mediaInfo.thumbnails.firstObject;
    if (thumbnailInfo && thumbnailInfo.URL && thumbnailInfo.URL.length > 0) {
        SLOGI(@"[player][CBK][ThumbnailUrlReady], url=%@", thumbnailInfo.URL);
        [self.notificationDispatcher dispatchDidReadyThumbnailUrl:thumbnailInfo.URL];
    }
}

/**
 * 提取封面图 URL
 *
 * 从 MediaInfo 中提取封面图 URL，用于播放前的封面图展示。
 * 提取成功后通过 dispatcher 通知相关 Slot 初始化封面图能力。
 *
 * SDK 版本要求：通过 getMediaInfo.coverURL 获取封面图 URL
 * 需要阿里云播放器 SDK 版本 ≥ 7.16.0，低版本 SDK 该接口可能返回 nil。
 */
- (void)dispatchCoverUrlIfAvailable {
    if (!_aliPlayer) return;
    AVPMediaInfo *mediaInfo = [_aliPlayer getMediaInfo];
    NSString *coverURL = mediaInfo.coverURL;
    if (coverURL.length > 0) {
        SLOGI(@"[player][CBK][CoverUrlReady], url=%@", coverURL);
        [self.notificationDispatcher dispatchDidReadyCoverUrl:coverURL];
    }
}

/**
 * 提取视频标题
 *
 * 从 MediaInfo 中提取视频标题，用于显示视频标题。
 * 提取成功后通过 dispatcher 通知相关 Slot 初始化视频标题能力。
 *
 * SDK 版本要求：通过 getMediaInfo.title 获取视频标题
 * 需要阿里云播放器 SDK 版本 ≥ 7.16.0，低版本 SDK 该接口可能返回 nil。
 */
- (void)dispatchVideoTitleIfAvailable {
    if (!_aliPlayer) return;
    AVPMediaInfo *mediaInfo = [_aliPlayer getMediaInfo];
    NSString *title = mediaInfo.title;
    if (title.length > 0) {
        SLOGI(@"[player][CBK][VideoTitleReady], title=%@", title);
        [self.notificationDispatcher dispatchDidReadyVideoTitle:title];
    }
}

- (void)transitionToState:(PlayerState)newState {
    if (self.state == newState) return;
    self.state = newState;
    [self.stateStoreInternal updatePlayState:newState];
    [self.notificationDispatcher dispatchDidChangeState:newState];
}

- (PlayerState)playerStateFromAVPStatus:(AVPStatus)status {
    switch (status) {
        case AVPStatusIdle:         return PlayerStateIdle;
        case AVPStatusInitialzed:   return PlayerStateIdle;
        case AVPStatusPrepared:     return PlayerStatePrepared;
        case AVPStatusStarted:      return PlayerStatePlaying;
        case AVPStatusPaused:       return PlayerStatePaused;
        case AVPStatusStopped:      return PlayerStateStopped;
        case AVPStatusCompletion:   return PlayerStateCompleted;
        case AVPStatusError:        return PlayerStateError;
        default:                    return PlayerStateIdle;
    }
}

- (AVPScene)playerSceneFromSceneType:(SceneType)sceneType {
    switch (sceneType) {
        case SceneTypeVOD:          return SceneLong;
        case SceneTypeLive:         return SceneLive;
        case SceneTypeVideoList:    return SceneShort;
        default:                    return SceneLong;
    }
}

@end
