//
//  RotateMode.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频旋转角度枚举。
 *
 * @discussion 控制视频画面的顺时针旋转角度。
 *
 * @see MediaPlayer
 */
typedef NS_ENUM(NSInteger, RotateMode) {
    /** 0 度 */
    RotateModeDegree0 = 0,

    /** 90 度 */
    RotateModeDegree90 = 90,

    /** 180 度 */
    RotateModeDegree180 = 180,

    /** 270 度 */
    RotateModeDegree270 = 270,
};

NS_ASSUME_NONNULL_END
