//
//  AiSegment.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiSegment.h"

@implementation AiSegment

#pragma mark - Lifecycle

- (instancetype)initWithSegmentId:(nullable NSString *)segmentId
                          startMs:(NSInteger)startMs
                            endMs:(NSInteger)endMs
                            title:(nullable NSString *)title
                          summary:(nullable NSString *)summary
                         markdown:(nullable NSString *)markdown {
    NSAssert(startMs < endMs, @"AiSegment: startMs (%ld) must be less than endMs (%ld)", (long)startMs, (long)endMs);
    self = [super init];
    if (self) {
        _segmentId = [segmentId copy];
        _startMs = startMs;
        _endMs = endMs;
        _title = [title copy];
        _summary = [summary copy];
        _markdown = [markdown copy];
    }
    return self;
}

@end
