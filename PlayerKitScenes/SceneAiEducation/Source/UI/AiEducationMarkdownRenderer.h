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
 * @discussion Markdown 渲染门面，实际渲染由 Swift 侧基于 GMarkdown
 *             （swift-markdown + MPITextKit）的 AiEducationMarkdownView 提供，
 *             支持标准 CommonMark 语法（标题、列表、加粗、代码块、表格等）。
 *
 *             与旧的 Down 方案不同，GMarkdown 输出的是「可嵌入的 UIView 组件」
 *             而非 NSAttributedString，故门面改为：先创建可复用的渲染视图，
 *             再按内容宽度渲染并返回内容高度，由调用方据此约束视图高度。
 *             引擎不可用时降级为 UILabel 渲染原文。
 */
@interface AiEducationMarkdownRenderer : NSObject

/**
 * @brief 获取渲染器单例。
 *
 * @return 渲染器共享实例。
 */
+ (instancetype)sharedRenderer;

/**
 * @brief 创建一个可嵌入的 Markdown 渲染视图。
 *
 * @discussion 返回的视图内部滚动已关闭，需配合 renderMarkdown:intoView:width:
 *             渲染内容并按返回高度约束其高度。可在 cell 中创建一次后复用。
 *
 * @return 可嵌入的渲染视图；引擎不可用时返回降级的 UILabel。
 */
- (UIView *)createMarkdownView;

/**
 * @brief 将 Markdown 文本渲染进指定视图，并返回内容高度。
 *
 * @param markdown Markdown 文本，nil 或空串时渲染为空并返回 0。
 * @param view     由 createMarkdownView 创建的渲染视图。
 * @param width    渲染内容宽度。
 *
 * @return 渲染后的内容高度，供调用方约束视图 / cell 高度。
 */
- (CGFloat)renderMarkdown:(nullable NSString *)markdown
                 intoView:(UIView *)view
                    width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
