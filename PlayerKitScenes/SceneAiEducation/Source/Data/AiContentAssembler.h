//
//  AiContentAssembler.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/17.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AiAnalysisResponse, AiContentViewModel, ChapterInfo, KnowledgeInfo, SummaryInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 内容数据组装器。
 *
 * @discussion 将服务端 DTO（AiAnalysisResponse）转换为面向展示的客户端模型
 *             （ChapterInfo / KnowledgeInfo / SummaryInfo），是数据层与
 *             UI 层的唯一桥梁。ChapterContentView 只消费 AiContentViewModel，
 *             不再感知 AiAnalysisResponse 的存在。
 */
@interface AiContentAssembler : NSObject

/**
 * @brief 从 chapterResult.chapterContentItems 组装章节列表（ChaptersOnly 用）。
 *
 * @param response AI 分析响应；为 nil 时返回空数组。
 *
 * @return 章节信息数组，永不为 nil。
 */
+ (NSArray<ChapterInfo *> *)buildChaptersFromResponse:(nullable AiAnalysisResponse *)response;

/**
 * @brief 从 chapterResult.chapterContentItems 组装知识点列表（TextAnalysis 用）。
 *
 * @discussion 每个 item 的 contentMarkdown 按以下优先级组装：
 *             - knowledgePoints.count > 0：拼接为 `- **{point}**：{description}\n`（中文冒号）
 *             - 否则 summary.length > 0：直接用 summary 作为 markdown
 *             - 否则：nil
 *
 * @param response AI 分析响应；为 nil 时返回空数组。
 *
 * @return 知识点信息数组，永不为 nil。
 */
+ (NSArray<KnowledgeInfo *> *)buildKnowledgeItemsFromResponse:(nullable AiAnalysisResponse *)response;

/**
 * @brief 从 summaryResult 组装摘要信息（GraphicAnalysis 用）。
 *
 * @param response AI 分析响应；无 summaryResult 时返回 nil。
 *
 * @return 摘要信息实例；无摘要时返回 nil。
 */
+ (nullable SummaryInfo *)buildSummaryInfoFromResponse:(nullable AiAnalysisResponse *)response;

/**
 * @brief 从响应一次性组装完整视图模型。
 *
 * @param response AI 分析响应；为 nil 时返回空视图模型。
 *
 * @return 已填充所有字段的视图模型实例。
 */
+ (AiContentViewModel *)buildViewModelFromResponse:(nullable AiAnalysisResponse *)response;

@end

NS_ASSUME_NONNULL_END
