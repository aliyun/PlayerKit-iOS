//
//  ScaleMode.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频缩放模式枚举。
 *
 * @discussion 控制视频内容如何适配并渲染到显示视图中。
 *
 * @see MediaPlayer
 */
typedef NS_ENUM(NSInteger, ScaleMode) {
    /** 拉伸填充视图 */
    ScaleModeFitXY = 0,

    /** 等比缩放适应视图 */
    ScaleModeFitCenter = 1,

    /** 等比缩放裁剪填充 */
    ScaleModeCenterCrop = 2,
};

NS_ASSUME_NONNULL_END
