//
//  ChapterInfo.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "ChapterInfo.h"

@implementation ChapterInfo

#pragma mark - Lifecycle

- (instancetype)initWithChapterId:(NSString *)chapterId
                          startMs:(NSInteger)startMs
                            endMs:(NSInteger)endMs
                            title:(NSString *)title
                     thumbnailUrl:(nullable NSString *)thumbnailUrl {
    self = [super init];
    if (self) {
        _chapterId = [chapterId copy];
        _startMs = startMs;
        _endMs = endMs;
        _title = [title copy];
        _thumbnailUrl = [thumbnailUrl copy];
    }
    return self;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:
            @"<ChapterInfo: %p, chapterId=%@, title=%@, startMs=%ld, endMs=%ld, thumbnailUrl=%@>",
            self, self.chapterId, self.title, (long)self.startMs, (long)self.endMs, self.thumbnailUrl];
}

#pragma mark - Public Methods

+ (NSInteger)findIndexByPosition:(nullable NSArray<ChapterInfo *> *)chapters
                      positionMs:(NSInteger)positionMs {
    // 二分查找，区间为 [startMs, endMs)
    if (chapters == nil || chapters.count == 0) {
        return -1;
    }
    NSInteger low = 0;
    NSInteger high = (NSInteger)chapters.count - 1;
    while (low <= high) {
        NSInteger mid = low + ((high - low) >> 1);
        ChapterInfo *chapter = chapters[mid];
        if (positionMs < chapter.startMs) {
            high = mid - 1;
        } else if (positionMs >= chapter.endMs) {
            low = mid + 1;
        } else {
            return mid;
        }
    }
    return -1;
}

@end
