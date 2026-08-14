//
//  PlayAuthResponse.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放凭证接口响应的 data 节点 DTO
 *
 * @discussion 对应接口 /appServer/GetVideoPlayAuth 响应中的 data 字段，
 *             包含视频 ID 与播放授权凭证。
 */
@interface PlayAuthData : NSObject

/// 视频 ID
@property (nonatomic, copy, nullable) NSString *videoId;

/// Base64 编码的播放授权凭证字符串（有时效性）
@property (nonatomic, copy, nullable) NSString *playAuth;

/**
 * @brief 从 JSON 字典解析 data 节点
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)dataWithDictionary:(nullable NSDictionary *)dictionary;

@end

/**
 * @brief 播放凭证接口响应 DTO
 *
 * @discussion 对应接口 GET {BASE_URL}/appServer/GetVideoPlayAuth?videoId={vid} 的完整响应。
 */
@interface PlayAuthResponse : NSObject

/// 业务返回码，0 表示成功
@property (nonatomic, assign) NSInteger code;

/// 请求是否成功
@property (nonatomic, assign) BOOL success;

/// 响应数据节点
@property (nonatomic, strong, nullable) PlayAuthData *data;

/**
 * @brief 从 JSON 字典解析响应
 *
 * @param dictionary JSON 字典，非字典类型时返回 nil。
 *
 * @return 解析后的实例；入参无效时返回 nil。
 */
+ (nullable instancetype)responseWithDictionary:(nullable NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
