//
//  ChapterContentView.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AiContentViewModel;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节 / AI 解析面板的内容视图。
 *
 * @discussion 展示 AI 内容理解结果，纯渲染角色，不做任何数据组装，支持三种展示样式：
 *             - ChaptersOnly：章节列表（缩略图 + 标题 + 时间）；
 *             - TextAnalysis：文字解析（知识点格式化或 Summary markdown）；
 *             - GraphicAnalysis：图解分析（ParagraphSummary + Tags + Markdown）。
 *
 *             TAB 组合规则由 AiContentViewModel 中的 hasChapterData / hasSummaryData 决定：
 *             - 仅 hasChapterData → 双 TAB（章节 + AI 解析）
 *             - 仅 hasSummaryData → 无 TAB（图解直接展示）
 *             - 两者都有 → 双 TAB（章节 + 图解）
 *
 *             章节列表项点击后通过 onChapterSelected 回调外部 seek 并关闭面板。
 *
 * @see AiContentViewModel
 * @see AiContentType
 * @see ChapterContentPanelSlot
 */
@interface ChapterContentView : UIView

/**
 * @brief 章节点击回调。
 *
 * @discussion 参数为章节起始时间（毫秒），由外部执行 seek 并关闭面板。
 */
@property (nonatomic, copy, nullable) void (^onChapterSelected)(NSInteger startMs);

/**
 * @brief 面板关闭按钮点击回调。
 *
 * @discussion 由外部实现收起面板逻辑。
 */
@property (nonatomic, copy, nullable) void (^onCloseTapped)(void);

/**
 * @brief 通过视图模型创建内容视图。
 *
 * @discussion 初始 frame 为 CGRectZero，由容器负责设定。
 *
 * @param viewModel 由 AiContentAssembler 组装好的视图模型。
 *
 * @return 已初始化的内容视图实例。
 */
- (instancetype)initWithViewModel:(AiContentViewModel *)viewModel;

/**
 * @brief 更新当前播放位置，驱动章节高亮。
 *
 * @discussion 内部二分查找定位当前章节，仅在索引变化时刷新对应行。
 *
 * @param positionMs 当前播放位置，单位毫秒。
 */
- (void)updateCurrentPosition:(NSInteger)positionMs;

@end

NS_ASSUME_NONNULL_END
