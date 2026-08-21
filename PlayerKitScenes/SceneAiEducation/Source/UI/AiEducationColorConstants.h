//
//  AiEducationColorConstants.h
//  AliPlayerKit
//
//  Created by keria on 2026/07/29.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * @brief AI 教育场景配色常量。
 *
 * @discussion 面板内所有语义化颜色统一从此处取值，禁止散落硬编码。
 *
 * @see ChapterContentView
 */

/**
 * @brief 高亮红 #FF4444（当前章节标题 / 分段时间戳高亮）。
 */
static inline UIColor *AiEducationHighlightRedColor(void) {
    return [UIColor colorWithRed:255.0 / 255.0 green:68.0 / 255.0 blue:68.0 / 255.0 alpha:1.0];
}

/**
 * @brief 面板背景透明，实际背景由模糊视图 + 深色遮罩提供。
 */
static inline UIColor *AiEducationPanelBgColor(void) {
    return [UIColor clearColor];
}

/**
 * @brief 摘要卡片背景 #1C1C1E。
 */
static inline UIColor *AiEducationSummaryBgColor(void) {
    return [UIColor colorWithRed:28.0 / 255.0 green:28.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];
}

/**
 * @brief 主文字色 #FFFFFF（标题、正文）。
 */
static inline UIColor *AiEducationTextPrimaryColor(void) {
    return [UIColor whiteColor];
}

/**
 * @brief 次要文字色 #9EA4AB（时间戳等辅助信息）。
 */
static inline UIColor *AiEducationTextSecondaryColor(void) {
    return [UIColor colorWithRed:158.0 / 255.0 green:164.0 / 255.0 blue:171.0 / 255.0 alpha:1.0];
}

/**
 * @brief 弱化的主文字色 rgba(255,255,255,0.8)（章节未选中标题等）。
 */
static inline UIColor *AiEducationTextMutedColor(void) {
    return [UIColor colorWithWhite:1.0 alpha:0.8];
}

/**
 * @brief 缩略图占位背景 #333333。
 */
static inline UIColor *AiEducationThumbnailBgColor(void) {
    return [UIColor colorWithRed:51.0 / 255.0 green:51.0 / 255.0 blue:51.0 / 255.0 alpha:1.0];
}

/**
 * @brief 标签文字白色。
 */
static inline UIColor *AiEducationTagTextColor(void) {
    return [UIColor whiteColor];
}

/**
 * @brief 标签背景深色 #28 2A 24。
 */
static inline UIColor *AiEducationTagBgColor(void) {
    return [UIColor colorWithRed:40/255.0 green:42/255.0 blue:36/255.0 alpha:1.0];
}

/**
 * @brief 弹窗遮罩黑 50% #80000000。
 */
static inline UIColor *AiEducationDialogOverlayColor(void) {
    return [UIColor colorWithWhite:0 alpha:128.0 / 255.0];
}

/**
 * @brief 分段卡片常态底色 #1C1C1E（适配深色面板）。
 */
static inline UIColor *AiEducationCardBgNormalColor(void) {
    return [UIColor colorWithRed:28.0 / 255.0 green:28.0 / 255.0 blue:30.0 / 255.0 alpha:1.0];
}

/**
 * @brief 分段卡片高亮底色 rgba(255,255,255,0.15)（适配深色面板）。
 */
static inline UIColor *AiEducationCardBgHighlightColor(void) {
    return [UIColor colorWithWhite:1.0 alpha:0.15];
}

/**
 * @brief 正文文字色 rgba(255,255,255,0.8)（与 Markdown 引擎 body 色一致；
 *        适配深色面板）。
 */
static inline UIColor *AiEducationBodyTextColor(void) {
    return [UIColor colorWithWhite:1.0 alpha:0.8];
}

/**
 * @brief 关闭按钮背景色 #2C2C2E。
 */
static inline UIColor *AiEducationCloseButtonBgColor(void) {
    return [UIColor colorWithRed:44.0 / 255.0 green:44.0 / 255.0 blue:46.0 / 255.0 alpha:1.0];
}

/**
 * @brief 关闭按钮图标色 #8E8E93。
 */
static inline UIColor *AiEducationCloseButtonTintColor(void) {
    return [UIColor colorWithRed:142.0 / 255.0 green:142.0 / 255.0 blue:147.0 / 255.0 alpha:1.0];
}

/**
 * @brief Tab 分隔线色 rgba(255,255,255,0.1)。
 */
static inline UIColor *AiEducationTabSeparatorColor(void) {
    return [UIColor colorWithWhite:1.0 alpha:0.1];
}

/**
 * @brief 毛玻璃深色遮罩 rgba(0,0,0,0.25)。
 */
static inline UIColor *AiEducationBlurOverlayColor(void) {
    return [UIColor colorWithWhite:0 alpha:0.25];
}

/**
 * @brief 章节列表当前行高亮背景 rgba(255,255,255,0.1)。
 */
static inline UIColor *AiEducationChapterRowHighlightColor(void) {
    return [UIColor colorWithWhite:1.0 alpha:0.1];
}
