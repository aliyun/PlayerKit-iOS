//
//  DefaultFullscreenTransition.h
//  AliPlayerKit
//
//  Created by keria on 2024/3/15.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FullscreenTransition.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 默认全屏过渡实现。
 *
 * @discussion 采用独立 UIWindow + FullscreenViewController 方案实现全屏过渡。
 *             进入全屏时创建高层级窗口并将播放器视图迁移至其中；
 *             退出全屏时将播放器视图还原至原始父视图，并隐藏全屏窗口。
 */
@interface DefaultFullscreenTransition : NSObject <FullscreenTransition>

@end

NS_ASSUME_NONNULL_END
