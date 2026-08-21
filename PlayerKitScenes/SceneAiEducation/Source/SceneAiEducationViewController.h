//
//  SceneAiEducationViewController.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 教育场景播放页。
 *
 * @discussion 进入页面后先向 App Server 获取播放凭证（PlayAuth）起播，
 *             再获取该视频的 AI 内容理解结果（章节划分 + 摘要 + 知识点），
 *             在播放器上提供「章节」入口按钮与章节 / AI 解析面板。
 *
 *             错误降级策略：
 *             - 播放凭证获取失败：Toast 提示后关闭页面；
 *             - AI 内容获取失败：Toast 提示后仅用播放凭证正常起播。
 */
@interface SceneAiEducationViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
