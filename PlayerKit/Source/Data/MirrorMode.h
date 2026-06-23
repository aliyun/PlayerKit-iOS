//
//  MirrorMode.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频镜像模式枚举。
 *
 * @discussion 控制视频画面的镜像翻转方向。
 *
 * @see MediaPlayer
 */
typedef NS_ENUM(NSInteger, MirrorMode) {
    /** 无镜像 */
    MirrorModeNone = 0,

    /** 水平镜像 */
    MirrorModeHorizontal = 1,

    /** 垂直镜像 */
    MirrorModeVertical = 2,
};

NS_ASSUME_NONNULL_END
