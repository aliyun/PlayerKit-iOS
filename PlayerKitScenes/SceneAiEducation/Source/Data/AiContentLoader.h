//
//  AiContentLoader.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AiVideoContent;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 内容加载器
 *
 * @discussion 负责从客户自部署的 App Server 加载播放凭证与 AI 内容理解结果：
 *             - 网络超时：连接 5s、读取 5s；
 *             - 请求在串行后台队列（PlayerKit-AiContentLoader）中执行；
 *             - 回调统一切回主队列，派发前检查取消标记；
 *             - cancel 后不再触发任何回调。
 *
 * @note 页面销毁（dealloc）时必须调用 cancel。
 *
 * @see AiContentConstants
 * @see AiVideoContent
 */
@interface AiContentLoader : NSObject

/**
 * @brief 通过 App Server 基础地址创建加载器
 *
 * @param baseURL App Server 基础地址（末尾不带 /），
 *                传 nil 或空串时使用 AiContentAppServerBaseURL 默认值。
 *
 * @return 已初始化的加载器实例。
 */
- (instancetype)initWithBaseURL:(nullable NSString *)baseURL;

/**
 * @brief 异步加载播放凭证
 *
 * @discussion 请求 /appServer/GetVideoPlayAuth?videoId={vid} 接口，
 *             失败（网络错误/超时/响应无效）时回调 nil。
 *             回调在主队列执行；已 cancel 时不回调。
 *
 * @param videoId    视频 ID。
 * @param completion 完成回调，playAuth 为 Base64 播放授权凭证，失败为 nil。
 */
- (void)loadPlayAuthWithVideoId:(NSString *)videoId
                     completion:(void (^)(NSString * _Nullable playAuth))completion;

/**
 * @brief 异步加载 AI 内容理解结果
 *
 * @discussion 请求 /GetMediaAiAnalysisByResultType?MediaId={vid} 接口（省略 ResultType 返回全部），
 *             并将 DTO 转换为 AiVideoContent 业务模型；
 *             失败或无有效内容时回调 nil。
 *             回调在主队列执行；已 cancel 时不回调。
 *
 * @param mediaId    媒资 ID（透传至 AiVideoContent.videoId）。
 * @param completion 完成回调，失败为 nil。
 */
- (void)loadWithMediaId:(NSString *)mediaId
             completion:(void (^)(AiVideoContent * _Nullable content))completion;

/**
 * @brief 取消所有进行中的请求
 *
 * @discussion 置位取消标记并取消所有持有的进行中任务；
 *             调用后不会再触发任何回调。页面销毁时必须调用。
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
