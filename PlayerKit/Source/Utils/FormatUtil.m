//
//  FormatUtil.m
//  AliPlayerKit
//
//  Created by keria on 2026/07/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "FormatUtil.h"

#pragma mark - Constants

static const int64_t kMillisecondsPerSecond = 1000;
static const int64_t kSecondsPerHour = 3600;
static const int64_t kSecondsPerMinute = 60;

@implementation FormatUtil

#pragma mark - Public Methods

+ (NSString *)formatTime:(int64_t)timeMs {
    int64_t totalSeconds = MAX(timeMs, 0) / kMillisecondsPerSecond;
    int64_t hours = totalSeconds / kSecondsPerHour;
    int64_t minutes = (totalSeconds % kSecondsPerHour) / kSecondsPerMinute;
    int64_t seconds = totalSeconds % kSecondsPerMinute;

    if (hours > 0) {
        return [NSString stringWithFormat:@"%02lld:%02lld:%02lld", hours, minutes, seconds];
    }
    return [NSString stringWithFormat:@"%02lld:%02lld", minutes, seconds];
}

+ (NSString *)formatTimeString:(NSInteger)currentMs
                      duration:(NSInteger)durationMs
                        format:(NSString *)format {
    NSInteger currentSeconds = currentMs / (NSInteger)kMillisecondsPerSecond;
    NSInteger durationSeconds = durationMs / (NSInteger)kMillisecondsPerSecond;
    return [NSString stringWithFormat:format,
            (long)(currentSeconds / kSecondsPerMinute), (long)(currentSeconds % kSecondsPerMinute),
            (long)(durationSeconds / kSecondsPerMinute), (long)(durationSeconds % kSecondsPerMinute)];
}

@end
