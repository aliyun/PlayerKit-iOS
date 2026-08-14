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
 * @brief AI 内容类型枚举
 *
 * @discussion 标识 AI 内容理解结果的展示形态，决定面板如何渲染内容。
 *
 * @see AiVideoContent
 */
typedef NS_ENUM(NSInteger, AiContentType) {
    /** 仅章节划分，无 AI 解析内容 */
    AiContentTypeChaptersOnly = 0,

    /** 文字解析（含摘要或知识点文本） */
    AiContentTypeTextAnalysis = 1,

    /** Markdown 图解解析 */
    AiContentTypeGraphicAnalysis = 2,
};

NS_ASSUME_NONNULL_END
