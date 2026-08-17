//
//  AiAnalysisResponse.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "AiAnalysisResponse.h"
#import "SafeValueHelper.h"
#import "AiContentConstants.h"

#pragma mark - Chapter 场景数据

@implementation KnowledgePointItem

#pragma mark - Public Methods

+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    KnowledgePointItem *item = [[KnowledgePointItem alloc] init];
    item.pointId = SafeStringOrNumber(dictionary[@"PointId"]);
    item.point = SafeString(dictionary[@"Point"]);
    item.pointDescription = SafeString(dictionary[@"Description"]);
    return item;
}

@end

@implementation ChapterContentItem

#pragma mark - Public Methods

+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    ChapterContentItem *item = [[ChapterContentItem alloc] init];
    item.chapterId = SafeStringOrNumber(dictionary[@"ChapterId"]);
    item.startTime = SafeInteger(dictionary[@"StartTime"], 0);
    item.endTime = SafeInteger(dictionary[@"EndTime"], 0);
    item.chapterTitle = SafeString(dictionary[@"ChapterTitle"]);
    item.summary = SafeString(dictionary[@"Summary"]);
    item.thumbnailUrl = SafeString(dictionary[@"ThumbnailUrl"]);

    // 数组可能含 NSNull，逐项类型检查跳过
    id rawPoints = dictionary[@"KnowledgePoints"];
    if ([rawPoints isKindOfClass:[NSArray class]]) {
        NSMutableArray<KnowledgePointItem *> *points = [NSMutableArray array];
        for (id element in (NSArray *)rawPoints) {
            KnowledgePointItem *point = [KnowledgePointItem itemWithDictionary:element];
            if (point) {
                [points addObject:point];
            }
        }
        item.knowledgePoints = [points copy];
    }
    return item;
}

@end

#pragma mark - Summary 场景数据

@implementation MindMapItem

#pragma mark - Public Methods

+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    MindMapItem *item = [[MindMapItem alloc] init];
    item.title = SafeString(dictionary[@"Title"]);
    NSArray *topics = dictionary[@"Topic"];
    if ([topics isKindOfClass:[NSArray class]]) {
        item.topics = topics;
    }
    return item;
}

@end

@implementation SummaryContent

#pragma mark - Public Methods

+ (nullable instancetype)contentWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    SummaryContent *content = [[SummaryContent alloc] init];
    content.paragraphSummary = SafeString(dictionary[@"ParagraphSummary"]);
    content.markdownContent = SafeString(dictionary[@"MarkdownContent"]);

    // 解析思维导图摘要列表
    NSArray *mindMapArray = dictionary[@"MindMapSummary"];
    if ([mindMapArray isKindOfClass:[NSArray class]]) {
        NSMutableArray<MindMapItem *> *items = [NSMutableArray array];
        for (NSDictionary *dict in mindMapArray) {
            MindMapItem *item = [MindMapItem itemWithDictionary:dict];
            if (item) {
                [items addObject:item];
            }
        }
        content.mindMapSummary = items.count > 0 ? [items copy] : nil;
    }
    return content;
}

@end

#pragma mark - 通用数据（Chapter + Summary）

@implementation ResultItem

#pragma mark - Public Methods

+ (nullable instancetype)itemWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    ResultItem *item = [[ResultItem alloc] init];
    item.resultType = SafeString(dictionary[@"ResultType"]);
    item.title = SafeString(dictionary[@"Title"]);
    item.extra = SafeString(dictionary[@"Extra"]);
    item.summaryContent = [SummaryContent contentWithDictionary:dictionary[@"summaryContent"]];

    // 标签数组（字段名 tags）：缺失/非数组时为 nil，元素逐项类型检查
    id rawTags = dictionary[@"tags"];
    if ([rawTags isKindOfClass:[NSArray class]]) {
        NSMutableArray<NSString *> *tags = [NSMutableArray array];
        for (id element in (NSArray *)rawTags) {
            NSString *tag = SafeString(element);
            if (tag.length > 0) {
                [tags addObject:tag];
            }
        }
        item.tags = tags.count > 0 ? [tags copy] : nil;
    }

    // 数组可能含 NSNull，逐项类型检查跳过
    id rawItems = dictionary[@"chapterContentItems"];
    if ([rawItems isKindOfClass:[NSArray class]]) {
        NSMutableArray<ChapterContentItem *> *chapterItems = [NSMutableArray array];
        for (id element in (NSArray *)rawItems) {
            ChapterContentItem *chapterItem = [ChapterContentItem itemWithDictionary:element];
            if (chapterItem) {
                [chapterItems addObject:chapterItem];
            }
        }
        item.chapterContentItems = [chapterItems copy];
    }
    return item;
}

@end

@implementation AiAnalysisResponse

#pragma mark - Public Methods

+ (nullable instancetype)responseWithDictionary:(nullable NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    AiAnalysisResponse *response = [[AiAnalysisResponse alloc] init];

    // 数组可能含 NSNull（如 [null, {...}]），逐项类型检查跳过
    id rawResults = dictionary[@"AiAnalysisResult"];
    if ([rawResults isKindOfClass:[NSArray class]]) {
        NSMutableArray<ResultItem *> *results = [NSMutableArray array];
        for (id element in (NSArray *)rawResults) {
            ResultItem *result = [ResultItem itemWithDictionary:element];
            if (result) {
                [results addObject:result];
            }
        }
        response.aiAnalysisResult = [results copy];
    }
    return response;
}

#pragma mark - Convenience Accessors

- (ResultItem *)chapterResult {
    for (ResultItem *item in self.aiAnalysisResult) {
        if ([AiContentResultTypeChapter isEqualToString:item.resultType]) {
            return item;
        }
    }
    return nil;
}

- (ResultItem *)summaryResult {
    for (ResultItem *item in self.aiAnalysisResult) {
        if ([AiContentResultTypeSummary isEqualToString:item.resultType]) {
            return item;
        }
    }
    return nil;
}

@end
