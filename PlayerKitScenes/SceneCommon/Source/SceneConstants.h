//
//  SceneConstants.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Module Category

/**
 * @brief 场景模块的模块分类名称。
 *
 * @discussion 在 App 模块系统中注册场景模块时用作显示分类。
 */
FOUNDATION_EXPORT NSString * const SceneModuleCategory;

/**
 * @brief 用于演示/示例数据的场景常量。
 *
 * @discussion 持有场景演示模块的固定常量，如示例 Vid 和 PlayAuth 令牌。
 *
 *             注意事项：
 *             - 本类中的常量仅用于 Demo/测试。
 *               请勿在生产环境中硬编码敏感值。
 *             - PlayAuth 令牌有过期时间，过期后必须重新生成。
 *             - JWTPlayAuth 要求播放器 SDK 版本 >= 7.10.0。
 *
 * @see SceneLongVideoViewController
 */
@interface SceneConstants : NSObject

#pragma mark - Landscape Sample

/**
 * @brief 横屏示例视频 Vid（视频 ID）。
 *
 * @discussion 用于获取横屏视频播放 URL（仅限演示）。
 */
+ (NSString *)landscapeSampleVid;

/**
 * @brief 横屏示例 PlayAuth 令牌（PlayAuth / JWTPlayAuth）。
 *
 * @discussion 用于横屏视频播放鉴权（仅限演示）。
 *             该令牌有过期时间，过期后必须重新生成。
 *
 * @warning JWTPlayAuth 要求播放器 SDK 版本 >= 7.10.0，
 *          否则播放鉴权可能失败。
 */
+ (NSString *)landscapeSamplePlayAuth;

#pragma mark - Portrait Sample

/**
 * @brief 竖屏示例视频 Vid（视频 ID）。
 *
 * @discussion 用于获取竖屏视频播放 URL（仅限演示）。
 */
+ (NSString *)portraitSampleVid;

/**
 * @brief 竖屏示例 PlayAuth 令牌（PlayAuth / JWTPlayAuth）。
 *
 * @discussion 用于竖屏视频播放鉴权（仅限演示）。
 *             该令牌有过期时间，过期后必须重新生成。
 *
 * @warning JWTPlayAuth 要求播放器 SDK 版本 >= 7.10.0，
 *          否则播放鉴权可能失败。
 */
+ (NSString *)portraitSamplePlayAuth;

#pragma mark - Sample Video URL

/**
 * @brief 示例视频播放 URL。
 *
 * @discussion 用于视频播放演示（仅限演示）。
 *
 * @warning 此 URL 可能随时过期，请谨慎使用。
 *          出于安全性和更好的媒资管理考虑，建议使用基于 Vid 的播放方式而非直接 URL。
 */
+ (NSString *)sampleVideoURL;

@end

NS_ASSUME_NONNULL_END
