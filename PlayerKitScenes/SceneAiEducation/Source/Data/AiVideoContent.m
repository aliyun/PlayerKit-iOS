//
//  AiVideoContent.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiVideoContent.h"
#import "AiSegment.h"

@implementation AiVideoContent

#pragma mark - Lifecycle

- (instancetype)initWithVideoId:(NSString *)videoId
                           type:(AiContentType)type
                        summary:(nullable AiSummary *)summary
                       chapters:(nullable NSArray<ChapterInfo *> *)chapters
                       segments:(nullable NSArray<AiSegment *> *)segments {
    self = [super init];
    if (self) {
        _videoId = [videoId copy];
        _type = type;
        _summary = summary;
        _chapters = chapters ? [chapters copy] : @[];
        _segments = segments ? [[segments sortedArrayUsingComparator:^NSComparisonResult(AiSegment *a, AiSegment *b) {
            if (a.startMs < b.startMs) return NSOrderedAscending;
            if (a.startMs > b.startMs) return NSOrderedDescending;
            return NSOrderedSame;
        }] copy] : @[];
    }
    return self;
}

#pragma mark - Public Methods

- (NSInteger)findSegmentIndexByPosition:(NSInteger)positionMs {
    // 二分查找，区间为 [startMs, endMs)
    if (self.segments.count == 0) {
        return -1;
    }
    NSInteger low = 0;
    NSInteger high = (NSInteger)self.segments.count - 1;
    while (low <= high) {
        NSInteger mid = low + ((high - low) >> 1);
        AiSegment *segment = self.segments[mid];
        if (positionMs < segment.startMs) {
            high = mid - 1;
        } else if (positionMs >= segment.endMs) {
            low = mid + 1;
        } else {
            return mid;
        }
    }
    return -1;
}

@end
