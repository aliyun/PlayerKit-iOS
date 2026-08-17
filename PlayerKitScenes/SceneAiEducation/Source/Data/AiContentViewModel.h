//
//  AiContentViewModel.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/17.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChapterInfo, KnowledgeInfo, SummaryInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节内容面板的展示视图模型。
 *
 * @discussion 由 AiContentAssembler 从服务端 DTO（AiAnalysisResponse）组装，
 *             作为 ChapterContentView 唯一的数据入口。视图侧仅负责渲染，
 *             不再感知服务端字段与响应结构。
 *
 *             TAB 组合规则由 hasChapterData / hasSummaryData 两个标志决定：
 *             - 仅 hasChapterData：ChaptersOnly + TextAnalysis
 *             - 仅 hasSummaryData：GraphicAnalysis 单 TAB
 *             - 两者都有：ChaptersOnly + GraphicAnalysis
 */
@interface AiContentViewModel : NSObject

/// 章节列表（ChaptersOnly 展示用）
@property (nonatomic, copy) NSArray<ChapterInfo *> *chapters;

/// 知识点列表（TextAnalysis 展示用）
@property (nonatomic, copy, nullable) NSArray<KnowledgeInfo *> *knowledgeItems;

/// 视频级摘要（GraphicAnalysis 展示用）
@property (nonatomic, strong, nullable) SummaryInfo *summaryInfo;

/// 是否存在章节结果（对应 chapterResult 是否存在，决定 TAB 组合）
@property (nonatomic, assign) BOOL hasChapterData;

/// 是否存在摘要结果（对应 summaryResult 是否存在，决定 TAB 组合）
@property (nonatomic, assign) BOOL hasSummaryData;

@end

NS_ASSUME_NONNULL_END
