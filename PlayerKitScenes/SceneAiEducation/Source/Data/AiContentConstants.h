//
//  AiContentConstants.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief App Server 的基础地址
 *
 * @discussion
 *  ① 这是接入 AI 教育场景时唯一必须修改的配置项。
 *  ② 地址格式为 http://<IP或域名>:<端口>，末尾不带 /。
 *  ③ 依赖两个接口路径：/appServer/GetVideoPlayAuth?videoId={vid}
 *     与 /GetMediaAiAnalysisByResultType?MediaId={vid}。
 *  ④ App Server 已开源于阿里云 VodAppServer 项目，
 *     项目地址：https://github.com/MediaBox-Demos/VodAppServer
 */
FOUNDATION_EXPORT NSString * const AiContentAppServerBaseURL;

/// 默认演示视频 MediaId
FOUNDATION_EXPORT NSString * const AiContentDefaultMediaId;

/// 播放凭证接口的 videoId 参数名
FOUNDATION_EXPORT NSString * const AiContentParamVideoId;

/// AI 分析接口的 MediaId 参数名
FOUNDATION_EXPORT NSString * const AiContentParamMediaId;

/// AI 分析接口的 ResultType 参数名
FOUNDATION_EXPORT NSString * const AiContentParamResultType;

/// ResultType 取值：章节划分结果
FOUNDATION_EXPORT NSString * const AiContentResultTypeChapter;

/// ResultType 取值：摘要结果
FOUNDATION_EXPORT NSString * const AiContentResultTypeSummary;

/**
 * @brief AI 教育场景网络常量与 URL 构建工具
 *
 * @discussion 提供 App Server 两个接口的完整请求 URL 构建方法。
 */
@interface AiContentConstants : NSObject

/**
 * @brief 构建获取播放凭证接口的完整 URL
 *
 * @discussion 格式：{baseURL}/appServer/GetVideoPlayAuth?videoId={vid}，
 *             vid 会进行 URL 编码。
 *
 * @param baseURL App Server 基础地址（末尾不带 /）。
 * @param videoId 视频 ID。
 *
 * @return 完整请求 URL 字符串；参数无效时返回 nil。
 */
+ (nullable NSString *)buildPlayAuthURLWithBaseURL:(NSString *)baseURL
                                           videoId:(NSString *)videoId;

/**
 * @brief 构建获取 AI 内容分析接口的完整 URL
 *
 * @discussion 格式：{baseURL}/GetMediaAiAnalysisByResultType?MediaId={vid}[&ResultType={type}]，
 *             resultType 为 nil 时省略 ResultType 参数（返回全部结果，推荐）；
 *             vid 会进行 URL 编码。
 *
 * @param baseURL    App Server 基础地址（末尾不带 /）。
 * @param mediaId    媒资 ID。
 * @param resultType 结果类型（AiContentResultTypeChapter / AiContentResultTypeSummary），可为 nil。
 *
 * @return 完整请求 URL 字符串；参数无效时返回 nil。
 */
+ (nullable NSString *)buildAiAnalysisURLWithBaseURL:(NSString *)baseURL
                                             mediaId:(NSString *)mediaId
                                          resultType:(nullable NSString *)resultType;

@end

NS_ASSUME_NONNULL_END
