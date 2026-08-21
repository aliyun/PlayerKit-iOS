//
//  AiContentType.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 内容展示样式枚举
 *
 * @discussion 定义面板内三种渲染模式，由 TAB 组合逻辑决定实际展示方式：
 *             - 仅 chapterResult：双 TAB（ChaptersOnly + TextAnalysis）
 *             - 仅 summaryResult：无 TAB（GraphicAnalysis 直接展示）
 *             - 两者都有：双 TAB（TextAnalysis + GraphicAnalysis）
 */
typedef NS_ENUM(NSInteger, AiContentType) {
    /// 章节列表：缩略图 + 标题 + 时间
    AiContentTypeChaptersOnly = 0,
    /// 文字解析：知识点格式化列表或 Summary markdown
    AiContentTypeTextAnalysis = 1,
    /// 图解分析：ParagraphSummary + Tags 徽章 + MarkdownContent
    AiContentTypeGraphicAnalysis = 2,
};

NS_ASSUME_NONNULL_END
