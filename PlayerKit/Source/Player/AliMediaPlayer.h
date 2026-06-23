//
//  AliMediaPlayer.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaPlayer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 基于阿里云播放器 SDK 的 MediaPlayer 协议实现。
 *
 * @discussion 封装 AliPlayer SDK，实现 MediaPlayer 协议定义的全部播放控制能力。
 *             负责将 AliPlayer SDK 的事件回调（AVPDelegate）转换为抽象的 PlayerState 状态。
 *             通过 DefaultPlayerFactory 创建实例。
 *
 * @see MediaPlayer
 * @see DefaultPlayerFactory
 */
@interface AliMediaPlayer : NSObject <MediaPlayer>

@end

NS_ASSUME_NONNULL_END
