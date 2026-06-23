//
//  DefaultPlayerPreloader.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerPreloader.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 默认预加载器实现。
 *
 * @discussion 基于播放器 SDK 的 AliMediaLoader 实现全局预加载功能。
 *             封装底层 SDK 预加载 API，将视频源和配置转换为 SDK 原生格式。
 *
 * @see PlayerPreloader
 * @see PlayerPreloadTask
 * @see PreloadDelegate
 */
@interface DefaultPlayerPreloader : NSObject <PlayerPreloader>

@end

NS_ASSUME_NONNULL_END
