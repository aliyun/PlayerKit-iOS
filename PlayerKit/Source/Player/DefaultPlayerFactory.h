//
//  DefaultPlayerFactory.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerFactory.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 默认播放器工厂实现。
 *
 * @discussion 使用阿里云播放器 SDK（AliPlayer）创建标准的播放器实例。
 *             作为 PlayerKit 框架内置的默认工厂，通过 AliPlayerKit 的 setPlayerFactory: 可替换为自定义工厂。
 *             内部创建 AliMediaPlayer 实例并包装为 MediaPlayer 协议。
 *
 * @see PlayerFactory
 * @see AliMediaPlayer
 */
@interface DefaultPlayerFactory : NSObject <PlayerFactory>

@end

NS_ASSUME_NONNULL_END
