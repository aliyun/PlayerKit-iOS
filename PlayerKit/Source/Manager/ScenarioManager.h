//
//  ScenarioManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SceneType.h"
#import "VideoSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器能力识别管理。
 *
 * @discussion 框架内部管理类，统一负责能力识别数据生成，用于播放体验优化和问题诊断。
 *             提供两个层级的能力标识：
 *             - 全局组件身份（buildGlobalExtraData）：标识「这是哪个组件」，
 *               由 GlobalManager 在初始化阶段写入 AliPlayerGlobalSettings.SET_EXTRA_DATA。
 *             - 实例级能力标识（buildScenarioFlagWithSceneType:sourceType:）：标识「这个播放器实例
 *               播什么、用什么源」，由 AliMediaPlayer 在 setDataSource: 内部写入 SCENARIO_FLAG。
 *
 *             此类不可实例化，所有方法均为类方法。
 *
 * @warning 仅由框架内部调用，外部不应直接使用。
 *
 * @see GlobalManager
 * @see AliMediaPlayer
 */
@interface ScenarioManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 生成全局能力识别数据（组件身份）。
 *
 * @discussion 在 SDK 全局初始化阶段写入 AliPlayer 的 SET_EXTRA_DATA，用于标识本组件。
 *             请勿覆盖：该数据用于播放体验优化与问题诊断，覆盖后会丢失组件来源信息。
 *
 * @return 形如 {"scene":"player-kit","platform":"ios","version":"x.y.z"} 的 JSON 字符串。
 */
+ (NSString *)buildGlobalExtraData;

/**
 * @brief 生成实例级能力识别数据。
 *
 * @discussion 基于当前播放场景与视频资源类型生成识别 JSON，用于播放体验优化与问题诊断。
 *             如某一枚举值超出已知范围，对应字段会降级为 "unknown" 并记录 ERROR 日志，不会抛出异常。
 *
 * @param sceneType  播放场景类型。
 * @param sourceType 视频资源类型。
 *
 * @return 形如 {"scene":"vod","source":"url"} 的 JSON 字符串。
 *
 * @see SceneType
 * @see VideoSourceType
 */
+ (NSString *)buildScenarioFlagWithSceneType:(SceneType)sceneType
                                  sourceType:(VideoSourceType)sourceType;

@end

NS_ASSUME_NONNULL_END
