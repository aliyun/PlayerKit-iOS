//
//  PlayStateSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放状态插槽。
 *
 * @discussion 负责显示播放器的错误状态信息。当播放器发生错误时，
 *             在播放器中心区域显示错误码和错误描述，帮助用户了解问题。
 *             当播放器状态从错误恢复时，错误信息自动隐藏。
 *
 *             触摸行为：无错误时不拦截触摸事件（穿透到下层插槽）；
 *             错误显示时拦截触摸，防止用户误操作。
 *
 *             可见性规则：在所有场景类型中始终可见。
 *
 * @see BaseSlot
 * @see PlayerNotificationDelegate
 */
@interface PlayStateSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
