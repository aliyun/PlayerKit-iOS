//
//  ChapterChipView.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/3.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChapterInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节 Chip 导航视图。
 *
 * @discussion 内含横向 UICollectionView，展示可滑动的章节导航列表。
 *             每个 Chip 显示章节的起始时间和标题，支持高亮当前播放章节。
 */
@interface ChapterChipView : UIView

/**
 * @brief Chip 被点击时的回调。
 *
 * @discussion 外部通过此 block 接收 Chip 点击事件并执行 seek 操作。
 */
@property (nonatomic, copy, nullable) void (^onChipSelected)(ChapterInfo *chapter);

/**
 * @brief 设置章节数据。
 *
 * @param chapters  章节列表。
 * @param durationMs 视频总时长（毫秒），当前未使用但预留用于后续扩展。
 */
- (void)setChapters:(NSArray<ChapterInfo *> *)chapters
           duration:(NSInteger)durationMs;

/**
 * @brief 更新当前高亮章节索引（增量刷新）。
 *
 * @param index 新的高亮索引，-1 表示无选中。
 */
- (void)updateCurrentIndex:(NSInteger)index;

/**
 * @brief 滚动到指定章节使其左对齐可见。
 *
 * @param index    目标章节索引。
 * @param animated 是否动画滚动。
 */
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
