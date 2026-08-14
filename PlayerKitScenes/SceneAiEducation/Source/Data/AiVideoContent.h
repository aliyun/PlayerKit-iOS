//
//  AiVideoContent.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AiContentType.h"

@class ChapterInfo;
@class AiSummary;
@class AiSegment;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 视频内容业务模型
 *
 * @discussion 顶层容器，聚合一个视频的所有 AI 分析内容，包括摘要、章节目录和分段解析。
 *
 * @see AiContentType
 * @see AiSummary
 * @see AiSegment
 */
@interface AiVideoContent : NSObject

/// 视频 ID（透传请求时的 mediaId）
@property (nonatomic, copy, readonly) NSString *videoId;

/// AI 内容类型
@property (nonatomic, assign, readonly) AiContentType type;

/// 视频整体摘要
@property (nonatomic, strong, readonly, nullable) AiSummary *summary;

/// 章节列表
@property (nonatomic, copy, readonly) NSArray<ChapterInfo *> *chapters;

/// AI 解析分段列表
@property (nonatomic, copy, readonly) NSArray<AiSegment *> *segments;

/**
 * @brief 便利构造方法，创建 AI 视频内容实例
 *
 * @param videoId  视频 ID（必须透传请求时的 mediaId）。
 * @param type     AI 内容类型。
 * @param summary  视频整体摘要，可为 nil。
 * @param chapters 章节列表，可为 nil（归一化为空数组）。
 * @param segments AI 解析分段列表，可为 nil（归一化为空数组）。
 *
 * @return 已初始化的 AI 视频内容实例。
 */
- (instancetype)initWithVideoId:(NSString *)videoId
                           type:(AiContentType)type
                        summary:(nullable AiSummary *)summary
                       chapters:(nullable NSArray<ChapterInfo *> *)chapters
                       segments:(nullable NSArray<AiSegment *> *)segments;

/**
 * @brief 按播放位置二分查找当前分段索引
 *
 * @discussion 分段列表须按 startMs 升序排列，
 *             命中条件为 startMs <= positionMs < endMs。
 *
 * @param positionMs 当前播放位置，单位毫秒。
 *
 * @return 命中的分段索引；未命中或列表为空时返回 -1。
 */
- (NSInteger)findSegmentIndexByPosition:(NSInteger)positionMs;

@end

NS_ASSUME_NONNULL_END
