//
//  DefaultPlayerPreloader.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "DefaultPlayerPreloader.h"
#import "PlayerPreloadTask.h"
#import "PlayerPreloadConfig.h"
#import "PreloadDelegate.h"
#import "VideoSource.h"
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

/**
 * @brief 预加载任务上下文（内部使用）。
 *
 * @discussion 跟踪已提交任务的代理与视频源信息，确保回调能正确分发。
 */
@interface _PreloadTaskContext : NSObject

@property (nonatomic, weak) id<PreloadDelegate> delegate;
@property (nonatomic, strong) VideoSource *videoSource;

@end

@implementation _PreloadTaskContext
@end

@interface DefaultPlayerPreloader () <OnPreloadListener>

@property (nonatomic, strong) AliMediaLoaderV2 *mediaLoader;
@property (nonatomic, strong) NSMutableDictionary<NSString *, _PreloadTaskContext *> *taskContexts;

@end

@implementation DefaultPlayerPreloader

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _mediaLoader = [AliMediaLoaderV2 shareInstance];
        _taskContexts = [NSMutableDictionary dictionary];

        SLOGI(@"[LC][init] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
    }
    return self;
}

- (void)dealloc {
    SLOGI(@"[LC][dealloc] ~~~ <%@: %p>", NSStringFromClass([self class]), self);
}

#pragma mark - PlayerPreloader

- (NSString *)addTask:(PlayerPreloadTask *)task delegate:(id<PreloadDelegate>)delegate {
    NSParameterAssert(task != nil);
    NSParameterAssert(delegate != nil);

    AVPPreloadConfig *sdkConfig = [self convertToSDKConfig:task.preloadConfig];
    AVPPreloadTask *sdkTask = [self convertToSDKTask:task.videoSource config:sdkConfig];
    if (!sdkTask) {
        SLOGE(@"failed to create SDK task for source: %@", task.videoSource);
        return nil;
    }

    NSString *taskId = [self.mediaLoader addTask:sdkTask listener:self];
    if (!taskId) {
        SLOGE(@"addTask failed, SDK returned nil taskId");
        return nil;
    }

    _PreloadTaskContext *context = [[_PreloadTaskContext alloc] init];
    context.delegate = delegate;
    context.videoSource = task.videoSource;
    @synchronized (self.taskContexts) {
        self.taskContexts[taskId] = context;
    }

    SLOGI(@"[preload][API][addTask], taskId=%@, source=%@", taskId, task.videoSource);
    return taskId;
}

- (void)cancelTask:(NSString *)taskId {
    NSParameterAssert(taskId != nil);

    SLOGI(@"[preload][API][cancelTask], taskId=%@", taskId);
    @synchronized (self.taskContexts) {
        [self.taskContexts removeObjectForKey:taskId];
    }
    [self.mediaLoader cancelTask:taskId];
}

- (void)pauseTask:(NSString *)taskId {
    NSParameterAssert(taskId != nil);

    SLOGI(@"[preload][API][pauseTask], taskId=%@", taskId);
    [self.mediaLoader pauseTask:taskId];
}

- (void)resumeTask:(NSString *)taskId {
    NSParameterAssert(taskId != nil);

    SLOGI(@"[preload][API][resumeTask], taskId=%@", taskId);
    [self.mediaLoader resumeTask:taskId];
}

- (void)cancelAll {
    NSArray<NSString *> *allTaskIds;
    @synchronized (self.taskContexts) {
        allTaskIds = self.taskContexts.allKeys;
        SLOGI(@"[preload][API][cancelAll], (%lu tasks)", (unsigned long)self.taskContexts.count);
        [self.taskContexts removeAllObjects];
    }

    for (NSString *taskId in allTaskIds) {
        [self.mediaLoader cancelTask:taskId];
    }
}

#pragma mark - OnPreloadListener

- (void)onCompleted:(NSString *)taskId urlOrVid:(NSString *)urlOrVid {
    _PreloadTaskContext *context;
    @synchronized (self.taskContexts) {
        context = self.taskContexts[taskId];
        if (!context) {
            return;
        }
        [self.taskContexts removeObjectForKey:taskId];
    }
    SLOGI(@"[preload][CBK][onCompleted], taskId=%@, urlOrVid=%@", taskId, urlOrVid);

    id<PreloadDelegate> delegate = context.delegate;
    if (delegate && [delegate respondsToSelector:@selector(preloadTaskDidComplete:source:)]) {
        [delegate preloadTaskDidComplete:taskId source:context.videoSource];
    }
}

- (void)onError:(NSString *)taskId urlOrVid:(NSString *)urlOrVid errorModel:(AVPErrorModel *)errorModel {
    _PreloadTaskContext *context;
    @synchronized (self.taskContexts) {
        context = self.taskContexts[taskId];
        if (!context) {
            return;
        }
        [self.taskContexts removeObjectForKey:taskId];
    }

    NSError *error = [NSError errorWithDomain:@"com.alibaba.playerkit.preload"
                                         code:errorModel.code
                                     userInfo:@{
        NSLocalizedDescriptionKey: errorModel.message ?: @"Unknown preload error"
    }];
    SLOGE(@"[preload][CBK][onError], taskId=%@, code=%ld, message=%@",
           taskId, (long)errorModel.code, errorModel.message);

    id<PreloadDelegate> delegate = context.delegate;
    if (delegate && [delegate respondsToSelector:@selector(preloadTaskDidFail:source:error:)]) {
        [delegate preloadTaskDidFail:taskId source:context.videoSource error:error];
    }
}

- (void)onCanceled:(NSString *)taskId urlOrVid:(NSString *)urlOrVid {
    _PreloadTaskContext *context;
    @synchronized (self.taskContexts) {
        context = self.taskContexts[taskId];
        if (!context) {
            return;
        }
        [self.taskContexts removeObjectForKey:taskId];
    }
    SLOGI(@"[preload][CBK][onCanceled], taskId=%@, urlOrVid=%@", taskId, urlOrVid);

    id<PreloadDelegate> delegate = context.delegate;
    if (delegate && [delegate respondsToSelector:@selector(preloadTaskDidCancel:source:)]) {
        [delegate preloadTaskDidCancel:taskId source:context.videoSource];
    }
}

#pragma mark - Private Methods

- (AVPPreloadConfig *)convertToSDKConfig:(PlayerPreloadConfig *)config {
    AVPPreloadConfig *sdkConfig = [[AVPPreloadConfig alloc] init];
    [sdkConfig setDuration:(int)config.preloadDuration];

    if (config.loadStartPositionMs > 0) {
        [sdkConfig setLoadStartPositionMs:(int)config.loadStartPositionMs];
    }
    if (config.defaultResolution > 0) {
        [sdkConfig setDefaultResolution:(int)config.defaultResolution];
    }
    if (config.defaultBandWidth > 0) {
        [sdkConfig setDefaultBandWidth:(int)config.defaultBandWidth];
    }
    if (config.defaultQuality.length > 0) {
        [sdkConfig setDefaultQuality:config.defaultQuality];
    }
    if (config.networkTimeout > 0) {
        [sdkConfig setNetworkTimeout:(int)config.networkTimeout];
    }
    if (config.networkRetryCount > 0) {
        [sdkConfig setNetworkRetryCount:(int)config.networkRetryCount];
    }
    if (config.referrer.length > 0) {
        [sdkConfig setReferrer:config.referrer];
    }
    if (config.customHeaders.count > 0) {
        [sdkConfig setCustomHeaders:config.customHeaders];
    }

    return sdkConfig;
}

- (AVPPreloadTask *)convertToSDKTask:(VideoSource *)source config:(AVPPreloadConfig *)sdkConfig {
    switch (source.sourceType) {
        case VideoSourceTypeUrl: {
            AVPUrlSource *urlSource = [[AVPUrlSource alloc] urlWithString:source.url];
            return [[AVPPreloadTask alloc] initWithUrlSource:urlSource preloadConfig:sdkConfig];
        }
        case VideoSourceTypeVidAuth: {
            AVPVidAuthSource *authSource = [[AVPVidAuthSource alloc] init];
            authSource.vid = source.vid;
            authSource.playAuth = source.playAuth;
            return [[AVPPreloadTask alloc] initWithVidAuthSource:authSource preloadConfig:sdkConfig];
        }
        case VideoSourceTypeVidSts: {
            AVPVidStsSource *stsSource = [[AVPVidStsSource alloc] init];
            stsSource.vid = source.vid;
            stsSource.accessKeyId = source.accessKeyId;
            stsSource.accessKeySecret = source.accessKeySecret;
            stsSource.securityToken = source.securityToken;
            return [[AVPPreloadTask alloc] initWithVidStsSource:stsSource preloadConfig:sdkConfig];
        }
    }
    return nil;
}

@end
