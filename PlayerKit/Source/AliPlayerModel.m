//
//  AliPlayerModel.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AliPlayerModel.h"
#import "VideoSource.h"

@interface AliPlayerModel ()

@property (nonatomic, strong, readwrite) VideoSource *videoSource;

@end

@implementation AliPlayerModel

#pragma mark - Lifecycle

- (nullable instancetype)initWithVideoSource:(VideoSource *)videoSource {
    NSParameterAssert(videoSource != nil);
    NSAssert([videoSource isValid], @"VideoSource must be valid");

    if (!videoSource || ![videoSource isValid]) {
        return nil;
    }

    self = [super init];
    if (self) {
        // 必填字段
        _videoSource = videoSource;

        // 可选字段：与 Android Builder 默认值对齐
        _sceneType = SceneTypeVOD;
        _coverUrl = nil;
        _thumbnailUrl = nil;
        _videoTitle = nil;
        _autoPlay = YES;
        _traceId = nil;
        _startTime = 0;
        _hardwareDecode = YES;
        _allowScreenSleep = NO;
        _disableScreenshot = NO;  // iOS 特有
        _onPlayerConfigBlock = nil;
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)description {
    return [NSString stringWithFormat:
            @"<%@: %p, videoSource=%@, sceneType=%ld, coverUrl=%@, thumbnailUrl=%@, videoTitle=%@, "
            @"autoPlay=%@, traceId=%@, startTime=%ld, hardwareDecode=%@, "
            @"allowScreenSleep=%@, disableScreenshot=%@, onPlayerConfigBlock=%@, chapters=%@>",
            NSStringFromClass([self class]), self,
            self.videoSource,
            (long)self.sceneType,
            self.coverUrl ?: @"(nil)",
            _thumbnailUrl ?: @"(nil)",
            self.videoTitle ?: @"(nil)",
            self.autoPlay ? @"YES" : @"NO",
            self.traceId ?: @"(nil)",
            (long)self.startTime,
            self.hardwareDecode ? @"YES" : @"NO",
            self.allowScreenSleep ? @"YES" : @"NO",
            self.disableScreenshot ? @"YES" : @"NO",
            self.onPlayerConfigBlock ? @"<set>" : @"(nil)",
            self.chapters];
}

@end
