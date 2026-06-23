//
//  SceneShortVideoViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 短视频场景提示引导页。
 *
 * @discussion 展示短视频列表播放能力的提示引导信息。
 *             AliPlayerKit 在架构层面已完整支持 VIDEO_LIST 场景，
 *             列表播放的复杂性主要体现在业务编排，而非播放器技术实现。
 *             页面引导用户使用阿里云微短剧解决方案。
 *
 * @see SceneShortVideoModule
 */
@interface SceneShortVideoViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
