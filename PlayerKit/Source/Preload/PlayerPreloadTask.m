//
//  PlayerPreloadTask.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerPreloadTask.h"
#import "VideoSource.h"
#import "PlayerPreloadConfig.h"

@implementation PlayerPreloadTask

#pragma mark - Lifecycle

- (instancetype)initWithVideoSource:(VideoSource *)videoSource
                      preloadConfig:(PlayerPreloadConfig *)preloadConfig {
    NSParameterAssert(videoSource != nil);
    NSParameterAssert(preloadConfig != nil);

    self = [super init];
    if (self) {
        _videoSource = videoSource;
        _preloadConfig = preloadConfig;
    }
    return self;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, videoSource=%@, preloadConfig=%@>",
            NSStringFromClass([self class]), self,
            self.videoSource, self.preloadConfig];
}

@end
