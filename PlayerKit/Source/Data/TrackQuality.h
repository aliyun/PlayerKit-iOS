//
//  TrackQuality.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 轨道类型枚举。
 */
typedef NS_ENUM(NSInteger, TrackType) {
    TrackTypeUnknown = 0,
    TrackTypeVideo = 1,
    TrackTypeAudio = 2,
    TrackTypeSubtitle = 3,
    TrackTypeVOD = 4,
};

/**
 * @brief 通用清晰度数据模型。
 *
 * @discussion 屏蔽底层播放器 SDK 的具体实现，提供统一的清晰度信息描述。
 */
@interface TrackQuality : NSObject

/** @brief 轨道索引。 */
@property (nonatomic, assign, readonly) NSInteger index;

/** @brief 轨道类型。 */
@property (nonatomic, assign, readonly) TrackType type;

/** @brief 视频宽度（像素）。 */
@property (nonatomic, assign, readonly) NSInteger width;

/** @brief 视频高度（像素）。 */
@property (nonatomic, assign, readonly) NSInteger height;

- (instancetype)initWithIndex:(NSInteger)index
                         type:(TrackType)type
                        width:(NSInteger)width
                       height:(NSInteger)height NS_DESIGNATED_INITIALIZER;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
