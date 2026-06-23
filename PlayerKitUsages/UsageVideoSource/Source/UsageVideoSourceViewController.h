//
//  UsageVideoSourceViewController.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频源使用示例页面。
 *
 * @discussion 演示 PlayerKit 支持的三种视频源类型的接入方式：
 *             - URL 直接播放源
 *             - VID + PlayAuth 播放凭证（推荐）
 *             - VID + STS 临时凭证
 *
 *             用户选择某种视频源类型后，从 DemoSettings 读取对应配置参数。
 *             配置完整时直接播放，配置缺失时引导用户跳转到链接配置页面。
 *
 * @see VideoSource
 * @see LinkViewController
 */
@interface UsageVideoSourceViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
