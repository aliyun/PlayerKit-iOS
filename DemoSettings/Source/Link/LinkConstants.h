//
//  LinkConstants.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LinkItem;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 链接配置页面常量与初始化数据。
 *
 * @discussion 集中定义所有可配置的业务项常量（存储键名），并提供默认配置项列表的构建方法。
 *             所有链接配置项的键名都在此统一管理，便于维护和扩展。
 *             对标 Android 端的 LinkConstants。
 *
 * @see LinkItem
 * @see LinkViewController
 */

#pragma mark - Storage Keys

/** @brief 视频 Direct URL 地址存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoURL;

/** @brief 视频 ID (Vid) 存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoVid;

/** @brief Vid 播放凭证 (PlayAuth) 存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoPlayAuth;

/** @brief 直播地址存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoLiveURL;

/** @brief VidSts 视频 ID 存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoVidStsVid;

/** @brief VidSts 访问密钥 ID 存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoVidStsAccessKeyId;

/** @brief VidSts 访问密钥密文存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoVidStsAccessKeySecret;

/** @brief VidSts 安全令牌存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoVidStsSecurityToken;

/** @brief VidSts 区域信息存储键。 */
FOUNDATION_EXPORT NSString * const LinkKeyVideoVidStsRegion;

#pragma mark - Factory

@interface LinkConstants : NSObject

/**
 * @brief 构建默认配置项列表。
 *
 * @discussion 创建包含所有可配置链接项的列表，每个配置项包含显示名称和存储键名。
 *             列表顺序决定了在 UI 中的显示顺序。
 *
 * @return 默认配置项列表。
 */
+ (NSArray<LinkItem *> *)buildDefaultItems;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
