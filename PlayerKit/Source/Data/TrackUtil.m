//
//  TrackUtil.m
//  AliPlayerKit
//
//  Created by keria on 2024/11/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "TrackUtil.h"
#import "TrackQuality.h"

/// 有效的视频轨道类型集合（Video 和 VOD）
static NSSet<NSNumber *> *sValidTrackTypes;

/// 标准分辨率与对应宽高的映射表
static NSDictionary<NSString *, NSArray<NSNumber *> *> *sTrackQualityResolutions;

/// 无法匹配到标准分辨率时返回此值
static NSString *const kUnknownResolution = @"Unknown";

@implementation TrackUtil

+ (void)initialize {
    if (self == [TrackUtil self]) {
        sValidTrackTypes = [NSSet setWithArray:@[
            @(TrackTypeVideo),
            @(TrackTypeVOD),
        ]];

        sTrackQualityResolutions = @{
            @"144P"  : @[@144,  @256],
            @"240P"  : @[@240,  @426],
            @"360P"  : @[@360,  @640],
            @"480P"  : @[@480,  @854],
            @"540P"  : @[@540,  @960],
            @"720P"  : @[@720,  @1280],
            @"1080P" : @[@1080, @1920],
            @"1440P" : @[@1440, @2560],
            @"2160P" : @[@2160, @3840],
            @"4320P" : @[@4320, @7680],
        };
    }
}

+ (NSArray<TrackQuality *> *)filterVideoTrackQualityList:(nullable NSArray<TrackQuality *> *)trackQualityList {
    if (!trackQualityList || trackQualityList.count == 0) {
        return @[];
    }

    NSMutableArray<TrackQuality *> *result = [NSMutableArray arrayWithCapacity:4];
    for (TrackQuality *quality in trackQualityList) {
        if (!quality) continue;
        if (quality.width <= 0 || quality.height <= 0) continue;
        if (![sValidTrackTypes containsObject:@(quality.type)]) continue;
        [result addObject:quality];
    }
    return [result copy];
}

+ (NSString *)findNearestResolution:(nullable TrackQuality *)trackQuality {
    if (!trackQuality || ![sValidTrackTypes containsObject:@(trackQuality.type)]) {
        return kUnknownResolution;
    }

    NSInteger width = trackQuality.width;
    NSInteger height = trackQuality.height;
    if (width <= 0 || height <= 0) {
        return kUnknownResolution;
    }

    NSString *nearestResolution = kUnknownResolution;
    NSInteger minDifference = NSIntegerMax;

    for (NSString *resolutionKey in sTrackQualityResolutions) {
        NSArray<NSNumber *> *values = sTrackQualityResolutions[resolutionKey];
        NSInteger resWidth = values[0].integerValue;
        NSInteger resHeight = values[1].integerValue;

        // 曼哈顿距离，同时考虑旋转方向
        NSInteger d1 = labs(resWidth - width) + labs(resHeight - height);
        NSInteger d2 = labs(resWidth - height) + labs(resHeight - width);
        NSInteger difference = MIN(d1, d2);

        if (difference < minDifference) {
            minDifference = difference;
            nearestResolution = resolutionKey;
        }
    }

    return nearestResolution;
}

@end
