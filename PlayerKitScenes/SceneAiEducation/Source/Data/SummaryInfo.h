//
//  SummaryInfo.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/17.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MindMapItem;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief GraphicAnalysis TAB 的客户端展示模型。
 *
 * @discussion 由 AiContentAssembler 从 AiAnalysisResponse.summaryResult 组装，
 *             承载视频级摘要文本、思维导图标题与完整 Markdown 内容，
 *             ChapterContentView 直接读取渲染。取代原 AiSummary 模型。
 */
@interface SummaryInfo : NSObject

/// 段落摘要文字
@property (nonatomic, copy, nullable) NSString *paragraphSummary;

/// 思维导图条目列表（来源：MindMapSummary[]，含 title 和 topics）
@property (nonatomic, copy, nullable) NSArray<MindMapItem *> *mindMapItems;

/// Markdown 全文内容
@property (nonatomic, copy, nullable) NSString *markdownContent;

@end

NS_ASSUME_NONNULL_END
