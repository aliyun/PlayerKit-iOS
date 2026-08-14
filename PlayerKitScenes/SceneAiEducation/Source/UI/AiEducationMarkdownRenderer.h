//
//  AiEducationMarkdownRenderer.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 教育场景 Markdown 渲染器。
 *
 * @discussion Markdown → NSAttributedString 渲染门面，实际渲染由 Swift 侧
 *             基于 Down（cmark）的 AiEducationMarkdownEngine 提供，
 *             支持标准 CommonMark 语法（标题、列表、加粗、代码块等）。
 *             渲染结果通过 NSCache 缓存；引擎不可用或渲染异常时降级返回原文。
 */
@interface AiEducationMarkdownRenderer : NSObject

/**
 * @brief 获取渲染器单例。
 *
 * @return 渲染器共享实例。
 */
+ (instancetype)sharedRenderer;

/**
 * @brief 将 Markdown 文本渲染为富文本。
 *
 * @discussion 相同文本的渲染结果会被缓存；渲染异常时降级返回原文富文本。
 *
 * @param markdown Markdown 文本，nil 或空串时返回空富文本。
 *
 * @return 渲染后的富文本。
 */
- (NSAttributedString *)renderMarkdown:(nullable NSString *)markdown;

@end

NS_ASSUME_NONNULL_END
