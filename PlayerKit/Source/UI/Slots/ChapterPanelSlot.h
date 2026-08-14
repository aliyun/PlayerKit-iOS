//
//  ChapterPanelSlot.h
//  AliPlayerKit
//
//  Created by keria on 2026/08/11.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "BasePanelSlot.h"
#import "SlotActionNotificationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 章节面板插槽。
 *
 * @discussion 在全屏状态下显示章节列表面板（右侧滑入）。
 *             通过 SlotActionNotificationDelegate 的 slotDidRequestShowChapterPanel 事件触发显示。
 *             用户点击章节项可跳转到对应播放位置。
 */
@interface ChapterPanelSlot : BasePanelSlot <SlotActionNotificationDelegate>

@end

NS_ASSUME_NONNULL_END
