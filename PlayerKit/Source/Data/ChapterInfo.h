//
//  ChapterInfo.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频章节信息模型。
 *
 * @discussion 描述视频中单个章节的时间区间与展示信息，
 *             由 AI 内容理解服务的章节划分结果转换而来，
 *             仅在 SceneTypeAIVod 场景下由 AliPlayerModel.chapters 注入使用。
 *             章节区间为 [startMs, endMs)，即包含起始时间、不包含结束时间。
 *
 * @see AliPlayerModel
 */
@interface ChapterInfo : NSObject

/**
 * @brief 章节唯一标识。
 */
@property (nonatomic, copy) NSString *chapterId;

/**
 * @brief 章节起始时间，单位毫秒（含）。
 */
@property (nonatomic, assign) NSInteger startMs;

/**
 * @brief 章节结束时间，单位毫秒（不含）。
 */
@property (nonatomic, assign) NSInteger endMs;

/**
 * @brief 章节标题。
 */
@property (nonatomic, copy) NSString *title;

/**
 * @brief 章节缩略图 URL，可为 nil。
 */
@property (nonatomic, copy, nullable) NSString *thumbnailUrl;

/**
 * @brief 便利构造方法，创建章节信息实例。
 *
 * @param chapterId    章节唯一标识。
 * @param startMs      章节起始时间（毫秒，含）。
 * @param endMs        章节结束时间（毫秒，不含）。
 * @param title        章节标题。
 * @param thumbnailUrl 章节缩略图 URL，可为 nil。
 *
 * @return 已初始化的章节信息实例。
 */
- (instancetype)initWithChapterId:(NSString *)chapterId
                          startMs:(NSInteger)startMs
                            endMs:(NSInteger)endMs
                            title:(NSString *)title
                     thumbnailUrl:(nullable NSString *)thumbnailUrl;

/**
 * @brief 按播放位置二分查找当前章节索引。
 *
 * @discussion 章节列表须按 startMs 升序排列。
 *             命中条件为 startMs <= positionMs < endMs（区间 [startMs, endMs)）。
 *
 * @param chapters   章节列表，可为 nil 或空。
 * @param positionMs 当前播放位置，单位毫秒。
 *
 * @return 命中的章节索引；未命中或列表为空时返回 -1。
 */
+ (NSInteger)findIndexByPosition:(nullable NSArray<ChapterInfo *> *)chapters
                      positionMs:(NSInteger)positionMs;

@end

NS_ASSUME_NONNULL_END
