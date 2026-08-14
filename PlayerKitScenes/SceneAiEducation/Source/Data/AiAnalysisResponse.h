//
//  AiAnalysisResponse.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 知识点条目 DTO
 *
 * @discussion 对应 chapterContentItems[].KnowledgePoints[] 节点。
 */
@interface KnowledgePointItem : NSObject

/// 知识点 ID
@property (nonatomic, copy, nullable) NSString *pointId;

/// 知识点名称
@property (nonatomic, copy, nullable) NSString *point;

/// 知识点描述
@property (nonatomic, copy, nullable) NSString *pointDescription;

/**
 * @brief 从 JSON 字典解析知识点条目
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary;

@end

/**
 * @brief 章节内容条目 DTO
 *
 * @discussion 对应 AiAnalysisResult[].chapterContentItems[] 节点，
 *             包含章节时间范围、标题、摘要、缩略图和知识点列表，时间单位为毫秒。
 */
@interface ChapterContentItem : NSObject

/// 章节 ID
@property (nonatomic, copy, nullable) NSString *chapterId;

/// 章节起始时间（毫秒）
@property (nonatomic, assign) NSInteger startTime;

/// 章节结束时间（毫秒）
@property (nonatomic, assign) NSInteger endTime;

/// 章节标题
@property (nonatomic, copy, nullable) NSString *chapterTitle;

/// 章节摘要
@property (nonatomic, copy, nullable) NSString *summary;

/// 章节缩略图 URL
@property (nonatomic, copy, nullable) NSString *thumbnailUrl;

/// 知识点列表
@property (nonatomic, copy, nullable) NSArray<KnowledgePointItem *> *knowledgePoints;

/**
 * @brief 从 JSON 字典解析章节内容条目
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary;

@end

/**
 * @brief 摘要内容 DTO
 *
 * @discussion 对应 AiAnalysisResult[].summaryContent 节点，包含段落摘要和 Markdown 内容。
 */
@interface SummaryContent : NSObject

/// 整体文字摘要
@property (nonatomic, copy, nullable) NSString *paragraphSummary;

/// Markdown 格式摘要
@property (nonatomic, copy, nullable) NSString *markdownContent;

/**
 * @brief 从 JSON 字典解析摘要内容
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)contentWithDictionary:(nullable NSDictionary *)dictionary;

@end

/**
 * @brief AI 分析结果条目 DTO
 *
 * @discussion 对应响应中 AiAnalysisResult[] 数组元素，
 *             按 ResultType 区分章节（Chapter）与摘要（Summary）两类结果。
 */
@interface ResultItem : NSObject

/// 结果类型（"Chapter" / "Summary"）
@property (nonatomic, copy, nullable) NSString *resultType;

/// 视频标题
@property (nonatomic, copy, nullable) NSString *title;

/// 附加信息 JSON 字符串（可能含 "Summary" 字段，作为摘要降级来源）
@property (nonatomic, copy, nullable) NSString *extra;

/// 摘要内容（ResultType 为 Summary 时存在）
@property (nonatomic, strong, nullable) SummaryContent *summaryContent;

/// 章节内容列表（ResultType 为 Chapter 时存在）
@property (nonatomic, copy, nullable) NSArray<ChapterContentItem *> *chapterContentItems;

/// 视频标签列表（ResultType 为 Summary 时可能存在）
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/**
 * @brief 从 JSON 字典解析分析结果条目
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary;

@end

/**
 * @brief AI 内容分析接口响应 DTO
 *
 * @discussion 对应接口 GET {BASE_URL}/GetMediaAiAnalysisByResultType?MediaId={vid} 的完整响应。
 *             通过转换层映射为业务模型 AiVideoContent。
 */
@interface AiAnalysisResponse : NSObject

/// AI 分析结果列表
@property (nonatomic, copy, nullable) NSArray<ResultItem *> *aiAnalysisResult;

/**
 * @brief 从 JSON 字典解析响应
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)responseWithDictionary:(nullable NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
