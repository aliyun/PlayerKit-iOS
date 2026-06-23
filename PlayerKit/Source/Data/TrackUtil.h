//
//  TrackUtil.h
//  AliPlayerKit
//
//  Created by keria on 2024/11/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TrackQuality;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频轨道工具类。
 *
 * @discussion 提供视频清晰度轨道相关的工具方法，包括过滤视频轨道和查找最接近的标准分辨率。
 *             支持多视频轨播放（可变清晰度）场景。
 *
 * @see TrackQuality
 */
@interface TrackUtil : NSObject

/**
 * @brief 过滤视频清晰度轨道列表。
 *
 * @discussion 从音视频轨道列表中筛选出有效的视频轨道（type 为 Video/VOD 且 width/height > 0）。
 *
 * @param trackQualityList 音视频轨道列表，可能为 nil 或空列表。
 *
 * @return 过滤后的视频清晰度轨道列表，不会为 nil。
 */
+ (NSArray<TrackQuality *> *)filterVideoTrackQualityList:(nullable NSArray<TrackQuality *> *)trackQualityList;

/**
 * @brief 查找最接近的标准分辨率。
 *
 * @discussion 根据视频轨道的宽度和高度，从标准分辨率列表（144P~4320P）中
 *             查找最接近的分辨率。使用曼哈顿距离计算，同时考虑旋转方向。
 *
 * @param trackQuality 视频轨道，可能为 nil。
 *
 * @return 最接近的标准分辨率标识（如 "720P"、"1080P"），无法匹配时返回 "Unknown"。
 */
+ (NSString *)findNearestResolution:(nullable TrackQuality *)trackQuality;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
