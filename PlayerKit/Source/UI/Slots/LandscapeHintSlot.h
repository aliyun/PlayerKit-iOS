//
//  LandscapeHintSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 横屏提示插槽。
 *
 * @discussion 当视频为横屏内容（宽 > 高）且当前屏幕为竖屏时，
 *             在视频内容区域底部显示 "横屏观看" 提示按钮。
 *             点击后触发进入全屏模式。
 *
 *             与 Android LandscapeHintSlot 对齐：
 *             - 检测视频宽高比 > 1
 *             - 在 FIT_CENTER 下定位到视频底部边缘
 *             - 竖屏时显示，横屏/全屏时隐藏
 *
 *             可见性规则：在 Minimal 场景中不可见（由 SlotConfig 控制）。
 *
 * @see BaseSlot
 * @see SlotType
 */
@interface LandscapeHintSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
