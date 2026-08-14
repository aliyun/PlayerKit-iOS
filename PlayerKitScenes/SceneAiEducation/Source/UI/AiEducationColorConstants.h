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
 * @brief 面板背景白 #FFFFFF。
 */
static inline UIColor *AiEducationPanelBgColor(void) {
    return [UIColor colorWithRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:1.0];
}

/**
 * @brief 摘要卡片背景 #F8F8F8。
 */
static inline UIColor *AiEducationSummaryBgColor(void) {
    return [UIColor colorWithRed:248.0 / 255.0 green:248.0 / 255.0 blue:248.0 / 255.0 alpha:1.0];
}

/**
 * @brief 主文字色 #333333（标题、正文）。
 */
static inline UIColor *AiEducationTextPrimaryColor(void) {
    return [UIColor colorWithRed:51.0 / 255.0 green:51.0 / 255.0 blue:51.0 / 255.0 alpha:1.0];
}

/**
 * @brief 次要文字色 #999999（时间戳等辅助信息）。
 */
static inline UIColor *AiEducationTextSecondaryColor(void) {
    return [UIColor colorWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0];
}

/**
 * @brief 缩略图占位背景 #E0E0E0。
 */
static inline UIColor *AiEducationThumbnailBgColor(void) {
    return [UIColor colorWithRed:224.0 / 255.0 green:224.0 / 255.0 blue:224.0 / 255.0 alpha:1.0];
}

/**
 * @brief 标签文字红 #FF4444。
 */
static inline UIColor *AiEducationTagTextColor(void) {
    return [UIColor colorWithRed:255.0 / 255.0 green:68.0 / 255.0 blue:68.0 / 255.0 alpha:1.0];
}

/**
 * @brief 标签背景浅红 #1AFF4444
 */
static inline UIColor *AiEducationTagBgColor(void) {
    return [UIColor colorWithRed:255.0 / 255.0 green:68.0 / 255.0 blue:68.0 / 255.0 alpha:26.0 / 255.0];
}

/**
 * @brief 弹窗遮罩黑 50% #80000000。
 */
static inline UIColor *AiEducationDialogOverlayColor(void) {
    return [UIColor colorWithWhite:0 alpha:128.0 / 255.0];
}

/**
 * @brief 分段卡片常态底色（浅灰 white:0.97，iOS 既有视觉，仅集中化不改色值）。
 */
static inline UIColor *AiEducationCardBgNormalColor(void) {
    return [UIColor colorWithWhite:0.97 alpha:1.0];
}

/**
 * @brief 分段卡片高亮底色（浅蓝，iOS 既有视觉，仅集中化不改色值）。
 */
static inline UIColor *AiEducationCardBgHighlightColor(void) {
    return [UIColor colorWithRed:0.9 green:0.95 blue:1.0 alpha:1.0];
}

/**
 * @brief 正文文字色（darkGray，与 Markdown 引擎 body 色一致；
 *        iOS 既有视觉，仅集中化不改色值）。
 */
static inline UIColor *AiEducationBodyTextColor(void) {
    return [UIColor darkGrayColor];
}
