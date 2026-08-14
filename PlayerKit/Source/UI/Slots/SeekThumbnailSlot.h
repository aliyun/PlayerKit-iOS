//
//  SeekThumbnailSlot.h
//  AliPlayerKit
//
//  Created by keria on 2026/07/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 拖动进度条缩略图预览插槽。
 *
 * @discussion 用户拖动进度条时，在播放区域底部中央展示
 *             「缩略图 + 时间戳」竖排浮层；松手后浮层消失。
 *             缩略图 URL 支持双源初始化：
 *             1. 外部通过 AliPlayerModel.thumbnailUrl 指定（优先）；
 *             2. Vid 播放时从媒体信息中自动提取（控制台雪碧图）。
 *             本插槽为纯渲染组件，仅响应通知事件，不推断业务场景。
 *
 * @see BaseSlot
 * @see PlayerNotificationDelegate
 */
@interface SeekThumbnailSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
