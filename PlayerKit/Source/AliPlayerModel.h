//
//  AliPlayerModel.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SceneType.h"

@class VideoSource;
@protocol MediaPlayer;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器配置模型。
 *
 * @discussion 封装播放所需的全部配置信息，包括视频源、封面图、标题和播放选项。
 *             通过指定初始化方法创建实例，在传递给控制器之前配置可选属性。
 *
 * @see VideoSource
 * @see AliPlayerController
 */
@interface AliPlayerModel : NSObject

/**
 * @brief 视频数据源（必填）。
 *
 * @discussion 支持 Direct URL / VidSts / VidAuth 等类型。
 *
 * @see VideoSource
 */
@property (nonatomic, strong, readonly) VideoSource *videoSource;

/**
 * @brief 播放场景类型，默认为 SceneTypeVOD。
 *
 * @discussion 影响控制器及插槽策略，例如 VOD/LIVE 的 UI 与行为差异。
 *
 * @see SceneType
 */
@property (nonatomic, assign) SceneType sceneType;

/**
 * @brief 封面图 URL。
 *
 * @discussion 视频播放前的封面图片 URL，用于在视频加载时显示。
 *             设为 nil 表示不使用封面图。
 */
@property (nonatomic, copy, nullable) NSString *coverUrl;

/**
 * @brief 视频标题。
 *
 * @discussion 视频的标题文本，用于在 UI 中显示。
 *             设为 nil 表示不显示标题。
 */
@property (nonatomic, copy, nullable) NSString *videoTitle;

/**
 * @brief 是否在配置完成后自动播放，默认为 YES。
 *
 * @discussion YES 表示视频配置完成后自动开始播放，
 *             NO 表示需要手动调用播放方法。
 */
@property (nonatomic, assign) BOOL autoPlay;

/**
 * @brief 跟踪标识符，用于播放质量监控与单点追查。
 *
 * @discussion 值由业务方自行定义，需为用户或设备的唯一标识符，
 *             例如业务 userId、IDFA 等。
 *             传入 traceId 后，SDK 埋点日志上报功能开启，
 *             后续可使用播放质量监控、单点追查和视频播放统计功能。
 *
 * @see https://help.aliyun.com/zh/vod/developer-reference/single-point-tracing
 */
@property (nonatomic, copy, nullable) NSString *traceId;

/**
 * @brief 播放起始位置，单位毫秒，默认为 0。
 *
 * @discussion 视频开始播放的时间点。
 *             如果传入负数，会自动修正为 0（从视频开头播放）。
 */
@property (nonatomic, assign) NSInteger startTime;

/**
 * @brief 是否启用硬件解码，默认为 YES。
 *
 * @discussion YES 为使用硬件解码，NO 为使用软件解码。
 */
@property (nonatomic, assign) BOOL hardwareDecode;

/**
 * @brief 是否允许播放期间屏幕休眠，默认为 NO。
 *
 * @discussion YES 允许屏幕休眠，NO 不允许屏幕休眠（保持屏幕常亮）。
 */
@property (nonatomic, assign) BOOL allowScreenSleep;

/**
 * @brief 是否禁止截屏/录屏，默认为 NO（iOS 特有）。
 *
 * @discussion 启用后，视频渲染视图将嵌入安全容器。
 *             截屏或录屏时视频画面自动变黑，UI 控件不受影响。
 */
@property (nonatomic, assign) BOOL disableScreenshot;

/**
 * @brief 实例级播放器自定义配置回调。
 *
 * @discussion 在每次 configure: 时，prepare 之前触发。
 *             适用于实例级 SDK 配置，如 setConfig（缓冲/Referer）、setOption 等。
 *             回调参数为底层播放器实例，可通过此实例访问 SDK 配置能力。
 *
 * @see AliPlayerController
 */
@property (nonatomic, copy, nullable) void (^onPlayerConfigBlock)(id<MediaPlayer> player);

/**
 * @brief 通过指定视频源创建播放器模型。
 *
 * @param videoSource 有效的视频源对象。
 *
 * @return 已配置的播放器模型实例；如果 videoSource 无效则返回 nil。
 */
- (nullable instancetype)initWithVideoSource:(VideoSource *)videoSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
