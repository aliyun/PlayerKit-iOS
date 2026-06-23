//
//  PlayerPreloadConfig.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerPreloadConfig.h"

// 预加载缓冲时长（毫秒）
static const NSInteger kPreloadBufferDuration = 3 * 1000;

static NSString * const kDefaultQuality = @"AUTO";

@implementation PlayerPreloadConfig

#pragma mark - Lifecycle

- (instancetype)init {
    return [self initWithPreloadDuration:kPreloadBufferDuration defaultQuality:kDefaultQuality];
}

- (instancetype)initWithPreloadDuration:(NSInteger)preloadDuration
                         defaultQuality:(nullable NSString *)defaultQuality {
    self = [super init];
    if (self) {
        _preloadDuration = MAX(0, preloadDuration);
        _defaultQuality = (defaultQuality.length > 0) ? [defaultQuality copy] : kDefaultQuality;
        _loadStartPositionMs = 0;
        _defaultResolution = 0;
        _defaultBandWidth = 0;
        _networkTimeout = 0;
        _networkRetryCount = 0;
    }
    return self;
}

#pragma mark - Setters

- (void)setPreloadDuration:(NSInteger)preloadDuration {
    _preloadDuration = MAX(0, preloadDuration);
}

- (void)setDefaultQuality:(NSString *)defaultQuality {
    _defaultQuality = (defaultQuality.length > 0) ? [defaultQuality copy] : kDefaultQuality;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, preloadDuration=%ld, defaultQuality=%@, "
            @"loadStartPositionMs=%ld, defaultResolution=%ld, defaultBandWidth=%ld>",
            NSStringFromClass([self class]), self,
            (long)self.preloadDuration, self.defaultQuality,
            (long)self.loadStartPositionMs, (long)self.defaultResolution, (long)self.defaultBandWidth];
}

@end
