//
//  StutterDetectStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "StutterDetectStrategy.h"
#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "Log.h"

@interface StutterDetectStrategy ()

@property (nonatomic, assign, readwrite) NSInteger stutterCount;
@property (nonatomic, assign, readwrite) NSInteger totalStutterDurationMs;
@property (nonatomic, assign, readwrite) NSInteger stutterThresholdMs;
@property (nonatomic, assign) BOOL firstFrameRendered;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL sessionReported;
@property (nonatomic, assign) CFAbsoluteTime loadingStartTime;
@property (nonatomic, assign) CFAbsoluteTime sessionStartTime;
@property (nonatomic, assign) CFAbsoluteTime effectivePlayStartTime;
@property (nonatomic, assign) NSInteger effectivePlayDurationMs;

@end

@implementation StutterDetectStrategy

#pragma mark - Init

- (instancetype)initWithThreshold:(NSInteger)thresholdMs {
    self = [super init];
    if (self) {
        _stutterThresholdMs = thresholdMs;
    }
    return self;
}

#pragma mark - StrategyProtocol

- (NSString *)strategyName {
    return @"StutterDetectStrategy";
}

- (void)strategyDidStop {
    // 在取消订阅前输出会话分析报告
    [self reportSessionAnalysis];
    [super strategyDidStop];
}

#pragma mark - Subclass Hooks

- (void)resetInternalState {
    self.stutterCount = 0;
    self.totalStutterDurationMs = 0;
    self.firstFrameRendered = NO;
    self.isPlaying = NO;
    self.isLoading = NO;
    self.sessionReported = NO;
    self.loadingStartTime = 0;
    self.sessionStartTime = 0;
    self.effectivePlayStartTime = 0;
    self.effectivePlayDurationMs = 0;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    [self resetInternalState];
    self.sessionStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)playerDidRenderFirstFrame {
    self.firstFrameRendered = YES;
    if (self.sessionStartTime <= 0) {
        self.sessionStartTime = CFAbsoluteTimeGetCurrent();
    }
    // 首帧后，如果已满足有效播放条件，开始累计
    [self maybeStartEffectivePlay];
}

- (void)playerDidLoadingBegin {
    // 首帧渲染前的 loading 不计入卡顿
    if (!self.firstFrameRendered) return;

    // 记录 loading 起点（防重复 begin 覆盖）
    if (self.loadingStartTime <= 0) {
        self.loadingStartTime = CFAbsoluteTimeGetCurrent();
    }
    SLOGW(@"Loading started (Stutter begin)");

    // 进入 loading：有效播放段停止
    BOOL oldIsLoading = self.isLoading;
    self.isLoading = YES;
    SLOGD(@"State transition: isLoading %@ -> YES", oldIsLoading ? @"YES" : @"NO");
    [self stopEffectivePlay];
}

- (void)playerDidLoadingEnd {
    if (!self.firstFrameRendered) return;

    BOOL oldIsLoading = self.isLoading;
    self.isLoading = NO;
    SLOGD(@"State transition: isLoading %@ -> NO", oldIsLoading ? @"YES" : @"NO");

    // 统计卡顿时长
    if (self.loadingStartTime > 0) {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        NSInteger duration = (NSInteger)((now - self.loadingStartTime) * 1000);
        self.loadingStartTime = 0;

        if (duration >= self.stutterThresholdMs) {
            self.stutterCount++;
            self.totalStutterDurationMs += duration;

            SLOGI(@"卡顿恢复 - 本次卡顿时长: %ldms, 累计次数: %ld",
                  (long)duration, (long)self.stutterCount);

            // 单次卡顿回调
            if (self.delegate && [self.delegate respondsToSelector:@selector(stutterDetectStrategy:didStutter:)]) {
                [self.delegate stutterDetectStrategy:self didStutter:duration];
            }
        }
    }

    // loading 结束：如果满足条件，恢复有效播放累计
    [self maybeStartEffectivePlay];
}

- (void)playerDidChangeState:(PlayerState)state {
    BOOL willBePlaying = (state == PlayerStatePlaying);
    SLOGD(@"State transition: isPlaying %@ -> %@", self.isPlaying ? @"YES" : @"NO", willBePlaying ? @"YES" : @"NO");

    if (self.isPlaying && !willBePlaying) {
        // 离开 Playing（暂停/停止/完成/错误等）：停止累计
        [self stopEffectivePlay];
    }

    self.isPlaying = willBePlaying;

    if (self.isPlaying) {
        // 进入 Playing：如果满足条件（首帧后且非 loading）则开始累计
        [self maybeStartEffectivePlay];
    }

    switch (state) {
        case PlayerStateStopped:
        case PlayerStateError:
        case PlayerStateIdle:
        case PlayerStateCompleted: {
            [self reportSessionAnalysis];
            [self resetInternalState];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Private Methods

// 开始有效播放累计（仅当：首帧后 + Playing + 非 Loading）
- (void)maybeStartEffectivePlay {
    if (self.firstFrameRendered && self.isPlaying && !self.isLoading) {
        if (self.effectivePlayStartTime <= 0) {
            self.effectivePlayStartTime = CFAbsoluteTimeGetCurrent();
        }
    }
}

// 停止有效播放累计
- (void)stopEffectivePlay {
    if (self.effectivePlayStartTime > 0) {
        NSInteger delta = (NSInteger)((CFAbsoluteTimeGetCurrent() - self.effectivePlayStartTime) * 1000);
        if (delta > 0) {
            self.effectivePlayDurationMs += delta;
        }
        self.effectivePlayStartTime = 0;
    }
}

// 输出会话分析报告
- (void)reportSessionAnalysis {
    if (self.sessionStartTime <= 0) return;
    if (self.sessionReported) return;
    self.sessionReported = YES;

    // 会话结束前，停止有效播放段
    [self stopEffectivePlay];

    // 如果正在 Loading 中退出，把这段算进卡顿（遵守阈值）
    if (self.loadingStartTime > 0) {
        NSInteger duration = (NSInteger)((CFAbsoluteTimeGetCurrent() - self.loadingStartTime) * 1000);
        self.loadingStartTime = 0;

        if (duration >= self.stutterThresholdMs) {
            self.totalStutterDurationMs += duration;
            self.stutterCount++;
            SLOGI(@"Session ended during loading, added stutter duration: %ldms", (long)duration);
        }
    }

    NSInteger sessionDuration = (NSInteger)((CFAbsoluteTimeGetCurrent() - self.sessionStartTime) * 1000);

    SLOGI(@"会话分析 - 会话时长: %ldms, 有效播放: %ldms, 卡顿总时长: %ldms, 卡顿次数: %ld",
          (long)sessionDuration,
          (long)self.effectivePlayDurationMs,
          (long)self.totalStutterDurationMs,
          (long)self.stutterCount);
    
    // 会话分析回调
    if (sessionDuration > 0 && self.delegate && [self.delegate respondsToSelector:@selector(stutterDetectStrategy:didAnalyzeSession:validPlayDuration:totalStutterDuration:stutterCount:)]) {
        [self.delegate stutterDetectStrategy:self
                           didAnalyzeSession:sessionDuration
                           validPlayDuration:self.effectivePlayDurationMs
                        totalStutterDuration:self.totalStutterDurationMs
                                stutterCount:self.stutterCount];
    }
    
    self.sessionStartTime = 0;
}

@end
