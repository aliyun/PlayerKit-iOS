//
//  CoverSlot.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "BaseSlot.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 封面图插槽。
 *
 * @discussion 负责显示视频封面图，覆盖在播放器 Surface 之上。
 *             当视频首帧渲染完成后，封面图会自动隐藏，显示视频内容。
 *             封面图 URL 从 AliPlayerModel.coverUrl 获取。
 *
 *             可见性规则：在 Live、Restricted、Minimal 场景中不可见。
 *
 * @see BaseSlot
 * @see AliPlayerModel
 */
@interface CoverSlot : BaseSlot

@end

NS_ASSUME_NONNULL_END
