//
//  ChapterContentPanelSlot.h
//  AliPlayerKit
//
//  Created by keria on 2026/8/13.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <PlayerKit/BasePanelSlot.h>

@class AiAnalysisResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节 / AI 解析面板插槽（控制器角色）。
 *
 * @discussion 继承 BasePanelSlot，复用统一的显示状态机、蒙层与滑入滑出动画。
 *             自身不渲染面板内容，仅作为控制器：面板的实际渲染委托给
 *             ChapterContentView，并承载在挂到窗口上的容器内
 *             （竖屏自底部弹出，横屏自右侧弹出）。
 *
 *             AI 内容由场景层经 updateAiContent: 推入（AliPlayerModel 无法承载），
 *             章节 / 分段点击直接经 host.controller 执行 seek，
 *             播放进度与全屏切换经 PlayerNotificationDelegate 自动接收：
 *             进度驱动高亮，全屏切换则直接关闭面板。
 *
 * @see BasePanelSlot
 * @see ChapterContentView
 */
@interface ChapterContentPanelSlot : BasePanelSlot

/**
 * @brief 更新面板展示的 AI 内容。
 *
 * @discussion 由场景层在 AI 内容就绪后推入：AI 内容（摘要 / 分段）无法承载在
 *             AliPlayerModel 上，因此不经数据绑定链路传递。
 *             内容视图在面板显示时按当前内容一次性构建，
 *             故显示期间换内容会先收起面板，下次打开时按新内容重建。
 *
 * @param response AI 分析响应；为 nil 时面板无内容可显示，将拒绝打开。
 */
- (void)updateAiContent:(nullable AiAnalysisResponse *)response;

@end

NS_ASSUME_NONNULL_END
