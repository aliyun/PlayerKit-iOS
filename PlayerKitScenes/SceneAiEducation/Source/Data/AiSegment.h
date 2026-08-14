//
//  AiSegment.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频 AI 解析分段模型
 *
 * @discussion 承载单个章节分段的 AI 解析内容（文字摘要与知识点 Markdown），
 *             分段区间为 [startMs, endMs)。
 *
 * @see AiVideoContent
 */
@interface AiSegment : NSObject

/// 分段唯一标识
@property (nonatomic, copy, nullable) NSString *segmentId;

/// 分段起始时间，单位毫秒（含）
@property (nonatomic, assign) NSInteger startMs;

/// 分段结束时间，单位毫秒（不含）
@property (nonatomic, assign) NSInteger endMs;

/// 分段标题
@property (nonatomic, copy, nullable) NSString *title;

/// 分段文字摘要（TEXT_ANALYSIS 模式使用）
@property (nonatomic, copy, nullable) NSString *summary;

/// 知识点拼接的 Markdown 内容（GRAPHIC_ANALYSIS 模式使用）
/// 格式为 "- **{Point}**: {Description}\n" 逐条拼接
@property (nonatomic, copy, nullable) NSString *markdown;

/**
 * @brief 便利构造方法，创建分段实例
 *
 * @param segmentId 分段唯一标识。
 * @param startMs   分段起始时间（毫秒，含）。
 * @param endMs     分段结束时间（毫秒，不含）。
 * @param title     分段标题。
 * @param summary   分段文字摘要，可为 nil。
 * @param markdown  知识点 Markdown 内容，可为 nil。
 *
 * @return 已初始化的分段实例。
 */
- (instancetype)initWithSegmentId:(nullable NSString *)segmentId
                          startMs:(NSInteger)startMs
                            endMs:(NSInteger)endMs
                            title:(nullable NSString *)title
                          summary:(nullable NSString *)summary
                         markdown:(nullable NSString *)markdown;

@end

NS_ASSUME_NONNULL_END
