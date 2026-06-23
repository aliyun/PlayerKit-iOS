//
//  GlobalManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief SDK 全局初始化管理器。
 *
 * @discussion 负责底层播放器 SDK 的全局配置，包括业务标识设置、
 *             本地缓存配置和缓存清理策略。
 *             此类为内部实现，不对外暴露，仅由 AliPlayerKit 内部调用。
 *             所有方法均为类方法，不可实例化。
 *
 * @warning 仅由 AliPlayerKit 内部调用，外部不应直接使用。
 *
 * @see AliPlayerKit
 */
@interface GlobalManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 执行全局初始化。
 *
 * @discussion 依次执行业务标识设置、本地缓存配置和缓存清理策略配置。
 *             由 AliPlayerKit 的 setup 方法内部调用，不应被外部直接调用。
 *
 * @see AliPlayerKit
 */
+ (void)setup;

/**
 * @brief 清除所有播放器缓存。
 *
 * @discussion 调用底层 SDK 接口清除本地媒体缓存。
 *             由 AliPlayerKit 的 clearCaches 方法内部调用。
 *
 * @see AliPlayerKit
 */
+ (void)clearCaches;

@end

NS_ASSUME_NONNULL_END
