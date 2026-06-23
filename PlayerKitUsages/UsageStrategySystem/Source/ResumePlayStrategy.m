//
//  ResumePlayStrategy.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "ResumePlayStrategy.h"
#import "StrategyContext.h"
#import "AliPlayerController.h"
#import "AliPlayerModel.h"
#import "VideoSource.h"
#import "Log.h"

// 保存间隔（秒）
static const NSTimeInterval kSaveInterval = 5.0;

// 距结尾阈值（毫秒），小于此值清除存储
static const NSInteger kNearEndThresholdMs = 10000;

// 存储键前缀
static NSString * const kStorageKeyPrefix = @"com.aliyun.playerkit.resume_position_";

@interface ResumePlayStrategy ()

@property (nonatomic, assign) CFAbsoluteTime lastSaveTime;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, copy, nullable) NSString *mediaId;

@end

@implementation ResumePlayStrategy

#pragma mark - StrategyProtocol

- (NSString *)strategyName {
    return @"ResumePlayStrategy";
}

- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    self.mediaId = [ResumePlayStrategy mediaIdFromSource:context.playerModel.videoSource];
    self.duration = 0;
    self.lastSaveTime = 0;
}

#pragma mark - Subclass Hooks

- (void)resetInternalState {
    self.lastSaveTime = 0;
    self.duration = 0;
    self.mediaId = [ResumePlayStrategy mediaIdFromSource:self.context.playerModel.videoSource];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    self.duration = duration;

    // 查询续播位置并跳转
    NSInteger resumePosition = [ResumePlayStrategy resumePositionForMediaId:self.mediaId];
    if (resumePosition > 0 && resumePosition < duration - kNearEndThresholdMs) {
        [self.context.controller seekTo:resumePosition];
        SLOGI(@"恢复播放位置: %ldms", (long)resumePosition);
    }
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    self.duration = duration;

    // 节流：每 kSaveInterval 秒保存一次
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - self.lastSaveTime < kSaveInterval) return;
    self.lastSaveTime = now;

    // 距结尾过近则清除存储
    if (duration > 0 && position > duration - kNearEndThresholdMs) {
        [ResumePlayStrategy clearResumePositionForMediaId:self.mediaId];
        return;
    }

    [ResumePlayStrategy saveResumePosition:position forMediaId:self.mediaId];
}

- (void)playerDidCompletion {
    // 播放完毕，清除存储
    [ResumePlayStrategy clearResumePositionForMediaId:self.mediaId];
    SLOGI(@"播放完毕，清除续播记录");
}

#pragma mark - Public Methods

+ (NSInteger)resumePositionForSource:(VideoSource *)source {
    NSString *mediaId = [self mediaIdFromSource:source];
    return [self resumePositionForMediaId:mediaId];
}

+ (void)clearResumePositionForSource:(VideoSource *)source {
    NSString *mediaId = [self mediaIdFromSource:source];
    [self clearResumePositionForMediaId:mediaId];
}

#pragma mark - Private Methods

// 从视频源提取媒体标识符
+ (nullable NSString *)mediaIdFromSource:(VideoSource *)source {
    if (!source) return nil;

    // 优先使用 vid，其次使用 URL
    if (source.vid.length > 0) {
        return source.vid;
    }
    if (source.url.length > 0) {
        return source.url;
    }
    return nil;
}

// 构建存储键
+ (NSString *)storageKeyForMediaId:(NSString *)mediaId {
    return [kStorageKeyPrefix stringByAppendingString:mediaId];
}

// 查询续播位置
+ (NSInteger)resumePositionForMediaId:(NSString *)mediaId {
    if (!mediaId || mediaId.length == 0) return 0;
    NSString *key = [self storageKeyForMediaId:mediaId];
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

// 保存续播位置
+ (void)saveResumePosition:(NSInteger)position forMediaId:(NSString *)mediaId {
    if (!mediaId || mediaId.length == 0) return;
    NSString *key = [self storageKeyForMediaId:mediaId];
    [[NSUserDefaults standardUserDefaults] setInteger:position forKey:key];
}

// 清除续播位置
+ (void)clearResumePositionForMediaId:(NSString *)mediaId {
    if (!mediaId || mediaId.length == 0) return;
    NSString *key = [self storageKeyForMediaId:mediaId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

@end
