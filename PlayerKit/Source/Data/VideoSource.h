//
//  VideoSource.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频资源类型定义。
 *
 * @discussion 定义了播放视频时支持的不同资源类型，
 *             用于区分不同的视频源获取方式，包括 VidAuth、VidSts、URL 三种类型。
 *             不同类型对应不同的鉴权和播放逻辑。
 *
 * @warning 维护约束：新增枚举值时，必须同步更新 ScenarioManager 中的 kSourceProtocolValues 数组，
 *          且 int 值需从 0 开始连续递增，否则新值将降级为 "unknown"。
 *
 * @see ScenarioManager
 */
typedef NS_ENUM(NSInteger, VideoSourceType) {
    /**
     * VID + PlayAuth 播放凭证播放源（推荐）
     *
     * 通过 VID 和播放授权码播放视频资源。
     * 使用播放授权码进行授权，适用于需要更简单授权机制的场景。
     */
    VideoSourceTypeVidAuth = 0,

    /**
     * VID + STS 临时凭证播放源
     *
     * 通过 VID 和 STS 令牌播放视频资源。
     * 使用阿里云 STS (Security Token Service) 进行授权，提供更高的安全性和访问控制。
     * 适用于需要临时访问凭证的场景。
     */
    VideoSourceTypeVidSts,

    /**
     * URL 直接播放源
     *
     * 通过直接 URL 播放视频资源。
     * 适用于公开访问的视频资源，无需额外的授权验证。
     */
    VideoSourceTypeUrl,
};

/**
 * @brief 视频播放源模型。
 *
 * @discussion 定义了所有播放源类型的共同接口，支持不同类型的视频资源播放。
 *             封装播放器所需的视频源信息，支持三种接入方式：
 *             VID+PlayAuth 播放凭证（推荐）、VID+STS 临时凭证、URL 直播/点播。
 *             通过工厂方法创建对应类型的实例，创建后不可修改。
 *
 * @see VideoSourceType
 */
@interface VideoSource : NSObject

/**
 * @brief 视频源类型。
 *
 * @discussion 返回当前视频源的类型标识，用于区分不同的视频源类型。
 */
@property (nonatomic, assign, readonly) VideoSourceType sourceType;

/**
 * @brief 视频源的唯一标识符，用于播放器实例生命周期管理。
 *
 * @discussion 根据视频源类型自动派生：
 *             - VidAuth / VidSts 类型返回 vid。
 *             - URL 类型返回 url。
 *
 * @see IdScopedPoolLifecycleStrategy
 */
@property (nonatomic, copy, readonly, nullable) NSString *uniqueId;

/**
 * @brief 视频 URL 地址，仅 URL 类型有效。
 *
 * @discussion 通过直接 URL 播放视频，适用于公开访问的视频资源。
 */
@property (nonatomic, copy, readonly, nullable) NSString *url;

/**
 * @brief 视频唯一标识符，VidSts 和 VidAuth 类型有效。
 *
 * @discussion 用于在播放服务中定位视频资源。
 */
@property (nonatomic, copy, readonly, nullable) NSString *vid;

/**
 * @brief 访问密钥 ID，仅 VidSts 类型有效。
 *
 * @discussion 阿里云 STS 临时凭证的 AccessKeyId。
 */
@property (nonatomic, copy, readonly, nullable) NSString *accessKeyId;

/**
 * @brief 访问密钥密文，仅 VidSts 类型有效。
 *
 * @discussion 阿里云 STS 临时凭证的 AccessKeySecret。
 */
@property (nonatomic, copy, readonly, nullable) NSString *accessKeySecret;

/**
 * @brief 安全令牌，仅 VidSts 类型有效。
 *
 * @discussion 阿里云 STS 临时凭证的 SecurityToken。
 */
@property (nonatomic, copy, readonly, nullable) NSString *securityToken;

/**
 * @brief 区域信息，仅 VidSts 类型有效。
 *
 * @discussion 视频资源所在的区域标识，为 nil 时使用默认区域。
 */
@property (nonatomic, copy, readonly, nullable) NSString *region;

/**
 * @brief 播放授权码，仅 VidAuth 类型有效。
 *
 * @discussion 用于播放鉴权的授权码，由服务端签发。
 */
@property (nonatomic, copy, readonly, nullable) NSString *playAuth;

/**
 * @brief 创建 VID+PlayAuth 类型视频源（推荐）。
 *
 * @discussion 通过 VID 和播放授权码播放视频，使用播放授权码进行授权。
 *             适用于需要更简单授权机制的场景。
 *
 * @param vid 视频唯一标识符，不能为 nil 或空字符串。
 * @param playAuth 播放授权码，不能为 nil 或空字符串。
 *
 * @return VidAuth 类型的视频源实例。
 */
+ (instancetype)vidAuthSourceWithVid:(NSString *)vid
                            playAuth:(NSString *)playAuth;

/**
 * @brief 创建 VID+STS 类型视频源。
 *
 * @discussion 通过 VID 和 STS 令牌播放视频，使用阿里云 STS 进行授权。
 *             适用于需要临时访问凭证的场景，提供更高的安全性和访问控制。
 *
 * @param vid 视频唯一标识符，不能为 nil 或空字符串。
 * @param accessKeyId 访问密钥 ID，不能为 nil 或空字符串。
 * @param accessKeySecret 访问密钥密文，不能为 nil 或空字符串。
 * @param securityToken 安全令牌，不能为 nil 或空字符串。
 * @param region 区域信息，可为 nil。
 *
 * @return VidSts 类型的视频源实例。
 */
+ (instancetype)vidStsSourceWithVid:(NSString *)vid
                        accessKeyId:(NSString *)accessKeyId
                    accessKeySecret:(NSString *)accessKeySecret
                      securityToken:(NSString *)securityToken
                             region:(nullable NSString *)region;

/**
 * @brief 创建 URL 类型视频源。
 *
 * @discussion 通过直接 URL 播放视频，适用于公开访问的视频资源，
 *             无需额外的授权验证。
 *
 * @param url 视频 URL 地址，不能为 nil 或空字符串。
 *
 * @return URL 类型的视频源实例。
 */
+ (instancetype)urlSourceWithUrl:(NSString *)url;

/**
 * @brief 验证当前资源配置是否有效。
 *
 * @discussion 检查视频源的所有必需参数是否都已正确设置。
 *             在配置播放器之前应该调用此方法进行验证。
 *
 * @return YES 表示配置有效，NO 表示配置不完整。
 */
- (BOOL)isValid;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
