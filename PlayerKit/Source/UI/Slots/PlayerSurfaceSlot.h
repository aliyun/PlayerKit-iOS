//
//  PlayerSurfaceSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 提供播放器渲染视图的插槽。
 *
 * @discussion 创建并管理播放器用于视频输出的渲染视图。
 *             挂载时，渲染视图通过 @c setRenderView: 传递给宿主，
 *             以便播放器控制器使用该视图进行渲染。
 *             卸载时，渲染视图从宿主解绑。
 *
 * @see BaseSlot
 * @see SlotHost
 */
@interface PlayerSurfaceSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
