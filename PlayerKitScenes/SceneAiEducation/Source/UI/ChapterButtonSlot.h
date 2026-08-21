//
//  ChapterButtonSlot.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <PlayerKit/BaseSlot.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节入口按钮插槽。
 *
 * @discussion 位于底部控制栏区域的「章节」入口按钮，纯渲染组件：
 *             内部零业务推断，数据与回调均由 Scene VC attach 后显式配置。
 *             无章节数据时按钮隐藏；点击后通过 onChapterButtonTapped 回调外部弹出章节面板。
 *
 * @see BaseSlot
 */
@interface ChapterButtonSlot : BaseSlot

/**
 * @brief 章节按钮点击回调。
 *
 * @discussion 由 Scene VC 配置，点击按钮时触发（如弹出章节面板）。
 */
@property (nonatomic, copy, nullable) void (^onChapterButtonTapped)(void);

/**
 * @brief 更新章节可用状态。
 *
 * @discussion available 为 NO（无章节数据）时隐藏按钮，YES 时显示。
 *             由 Scene VC 在 AI 内容加载完成后显式调用。
 *
 * @param available 章节数据是否可用。
 */
- (void)updateChapterAvailable:(BOOL)available;

@end

NS_ASSUME_NONNULL_END
