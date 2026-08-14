//
//  SceneType.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 场景类型枚举，用于控制插槽可见性。
 *
 * @discussion 定义不同播放场景下控制哪些插槽可见的场景类型。
 *             每种场景类型代表一个独立的播放上下文，拥有各自的可见插槽集合。
 *
 * @warning 维护约束：新增枚举值时，必须同步更新 ScenarioManager 中的 kSceneProtocolValues 数组，
 *          否则新值将降级为 "unknown"。
 *
 * @see SlotConfig
 * @see ScenarioManager
 */
typedef NS_ENUM(NSInteger, SceneType) {
    /** @brief 视频点播场景。 */
    SceneTypeVOD = 0,

    /** @brief 直播场景。 */
    SceneTypeLive = 1,

    /** @brief 视频列表或短视频流场景。 */
    SceneTypeVideoList = 2,

    /** @brief 受限播放场景。 */
    SceneTypeRestricted = 3,

    /** @brief 极简播放页场景。 */
    SceneTypeMinimal = 4,

    /** @brief AI 视频点播场景。 */
    SceneTypeAIVod = 5,
};

NS_ASSUME_NONNULL_END
