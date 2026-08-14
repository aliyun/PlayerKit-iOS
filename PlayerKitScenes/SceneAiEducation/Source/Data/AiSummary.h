//
//  AiSummary.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频整体摘要模型
 *
 * @discussion 承载 AI 内容理解服务返回的视频整体摘要信息，
 *             包含标题、描述和标签，对应 Summarize 能力的产出。
 *
 * @see AiVideoContent
 */
@interface AiSummary : NSObject

/// 视频标题
@property (nonatomic, copy, nullable) NSString *title;

/// 整体文字摘要
@property (nonatomic, copy, nullable) NSString *summaryText;

/// Markdown 格式摘要
@property (nonatomic, copy, nullable) NSString *markdown;

/// 视频标签列表
@property (nonatomic, copy, nullable) NSArray<NSString *> *tags;

/**
 * @brief 便利构造方法，创建摘要实例
 *
 * @param title       视频标题。
 * @param summaryText 整体文字摘要。
 * @param markdown    Markdown 格式摘要，可为 nil。
 * @param tags        视频标签列表，可为 nil。
 *
 * @return 已初始化的摘要实例。
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                  summaryText:(nullable NSString *)summaryText
                     markdown:(nullable NSString *)markdown
                         tags:(nullable NSArray<NSString *> *)tags;

@end

NS_ASSUME_NONNULL_END
