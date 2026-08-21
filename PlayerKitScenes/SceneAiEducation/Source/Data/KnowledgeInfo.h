//
//  KnowledgeInfo.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/17.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief TextAnalysis TAB 每个章节的客户端展示模型。
 *
 * @discussion 由 AiContentAssembler 从 AiAnalysisResponse 组装，
 *             ChapterContentView 直接读取渲染，不做二次数据拼接。
 */
@interface KnowledgeInfo : NSObject

/// 章节标题
@property (nonatomic, copy, nullable) NSString *title;

/// 章节起始时间（毫秒）
@property (nonatomic, assign) NSInteger startMs;

/// 章节结束时间（毫秒）
@property (nonatomic, assign) NSInteger endMs;

/// 预渲染的内容文本（markdown 格式字符串，由 Assembler 组装好）
/// 可能是 "- **Point**: Description\n..." 或直接的 Summary 文本
@property (nonatomic, copy, nullable) NSString *contentMarkdown;

@end

NS_ASSUME_NONNULL_END
