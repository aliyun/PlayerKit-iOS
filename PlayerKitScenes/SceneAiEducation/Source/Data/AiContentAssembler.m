//
//  AiContentAssembler.m
//  AliPlayerKit
//
//  Created by keria on 2026/8/17.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiContentAssembler.h"
#import "AiAnalysisResponse.h"
#import "AiContentViewModel.h"
#import "ChapterInfo.h"
#import "KnowledgeInfo.h"
#import "SummaryInfo.h"

@implementation AiContentAssembler

#pragma mark - Public Methods

+ (NSArray<ChapterInfo *> *)buildChaptersFromResponse:(nullable AiAnalysisResponse *)response {
    NSArray<ChapterContentItem *> *items = response.chapterResult.chapterContentItems;
    if (items.count == 0) {
        return @[];
    }

    NSMutableArray<ChapterInfo *> *chapters = [NSMutableArray arrayWithCapacity:items.count];
    for (ChapterContentItem *contentItem in items) {
        NSInteger startTime = contentItem.startTime;
        NSInteger endTime = contentItem.endTime;
        NSString *chapterTitle = contentItem.chapterTitle ?: @"";
        NSString *chapterId = contentItem.chapterId.length > 0 ? contentItem.chapterId : @"0";

        ChapterInfo *chapter = [[ChapterInfo alloc] initWithChapterId:chapterId
                                                              startMs:startTime
                                                                endMs:endTime
                                                                title:chapterTitle
                                                         thumbnailUrl:contentItem.thumbnailUrl];
        [chapters addObject:chapter];
    }
    return [chapters copy];
}

+ (NSArray<KnowledgeInfo *> *)buildKnowledgeItemsFromResponse:(nullable AiAnalysisResponse *)response {
    NSArray<ChapterContentItem *> *items = response.chapterResult.chapterContentItems;
    if (items.count == 0) {
        return @[];
    }

    NSMutableArray<KnowledgeInfo *> *result = [NSMutableArray arrayWithCapacity:items.count];
    for (ChapterContentItem *item in items) {
        KnowledgeInfo *info = [[KnowledgeInfo alloc] init];
        info.title = item.chapterTitle;
        info.startMs = item.startTime;
        info.endMs = item.endTime;
        info.contentMarkdown = [self buildContentMarkdownForItem:item];
        [result addObject:info];
    }
    return [result copy];
}

+ (nullable SummaryInfo *)buildSummaryInfoFromResponse:(nullable AiAnalysisResponse *)response {
    ResultItem *sr = response.summaryResult;
    if (!sr) {
        return nil;
    }

    SummaryInfo *info = [[SummaryInfo alloc] init];
    info.paragraphSummary = sr.summaryContent.paragraphSummary;
    info.markdownContent = sr.summaryContent.markdownContent;

    // 直接传递完整 MindMapItem 数组（含 title + topics）
    NSArray<MindMapItem *> *mindMapItems = sr.summaryContent.mindMapSummary;
    info.mindMapItems = mindMapItems.count > 0 ? mindMapItems : nil;

    return info;
}

+ (AiContentViewModel *)buildViewModelFromResponse:(nullable AiAnalysisResponse *)response {
    AiContentViewModel *viewModel = [[AiContentViewModel alloc] init];
    viewModel.chapters = [self buildChaptersFromResponse:response];
    viewModel.knowledgeItems = [self buildKnowledgeItemsFromResponse:response];
    viewModel.summaryInfo = [self buildSummaryInfoFromResponse:response];
    viewModel.hasChapterData = (response.chapterResult != nil);
    viewModel.hasSummaryData = (response.summaryResult != nil);
    return viewModel;
}

#pragma mark - Private Methods

/// 组装单个章节条目的 Markdown 内容
+ (nullable NSString *)buildContentMarkdownForItem:(ChapterContentItem *)item {
    if (item.knowledgePoints.count > 0) {
        NSMutableString *md = [NSMutableString string];
        for (KnowledgePointItem *kp in item.knowledgePoints) {
            if (kp.point.length > 0) {
                NSString *desc = kp.pointDescription.length > 0 ? kp.pointDescription : @"";
                [md appendFormat:@"- **%@**：%@\n", kp.point, desc];
            }
        }
        if (md.length > 0) {
            return [md copy];
        }
    }
    if (item.summary.length > 0) {
        return item.summary;
    }
    return nil;
}

@end
