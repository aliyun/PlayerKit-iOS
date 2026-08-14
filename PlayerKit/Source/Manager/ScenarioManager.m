//
//  ScenarioManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "ScenarioManager.h"
#import "AliPlayerKit.h"
#import "LogHub.h"

static NSString * const kTag = @"ScenarioManager";

#pragma mark - 数据协议常量

// 组件身份场景标识，用于全局识别本组件的来源
static NSString * const kScenePlayerKit = @"player-kit";

// 平台标识，便于跨端聚合统计区分
static NSString * const kPlatformIOS = @"ios";

// 未知枚举值降级协议值
// 当 sceneType / sourceType 超出已知枚举范围时，返回本值作为安全降级
static NSString * const kUnknownProtocolValue = @"unknown";

// SceneType 协议值映射
// 索引与 SceneType 枚举值严格一一对应（VOD=0, Live=1, VideoList=2, Restricted=3, Minimal=4, AIVod=5）
// 维护约束：新增 SceneType 枚举值时，必须在此数组末尾同步追加协议值，且 int 值需从 0 开始连续递增
static NSString * const kSceneProtocolValues[] = {
    @"vod",          // SceneTypeVOD
    @"live",         // SceneTypeLive
    @"list-player",  // SceneTypeVideoList
    @"restricted",   // SceneTypeRestricted
    @"minimal",      // SceneTypeMinimal
    @"ai-vod",       // SceneTypeAIVod
};

// VideoSourceType 协议值映射
// 索引与 VideoSourceType 枚举值严格一一对应（VidAuth=0, VidSts=1, Url=2）
// 维护约束：新增 VideoSourceType 枚举值时，必须在此数组末尾同步追加协议值，且 int 值需从 0 开始连续递增
static NSString * const kSourceProtocolValues[] = {
    @"vid-auth",  // VideoSourceTypeVidAuth
    @"vid-sts",   // VideoSourceTypeVidSts
    @"url",       // VideoSourceTypeUrl
};

static const NSInteger kSceneProtocolValuesCount = sizeof(kSceneProtocolValues) / sizeof(kSceneProtocolValues[0]);
static const NSInteger kSourceProtocolValuesCount = sizeof(kSourceProtocolValues) / sizeof(kSourceProtocolValues[0]);

@implementation ScenarioManager

#pragma mark - Public Methods

+ (NSString *)buildGlobalExtraData {
    return [NSString stringWithFormat:
            @"{\"scene\":\"%@\",\"platform\":\"%@\",\"version\":\"%@\"}",
            kScenePlayerKit, kPlatformIOS, [AliPlayerKit getPlayerKitVersion]];
}

+ (NSString *)buildScenarioFlagWithSceneType:(SceneType)sceneType
                                  sourceType:(VideoSourceType)sourceType {
    return [NSString stringWithFormat:
            @"{\"scene\":\"%@\",\"source\":\"%@\"}",
            [self sceneValue:sceneType], [self sourceValue:sourceType]];
}

#pragma mark - Private Methods

// SceneType 协议值查找
// 以枚举 int 作为索引取出协议值，越界时降级为 unknown 并记录 ERROR 日志
+ (NSString *)sceneValue:(SceneType)sceneType {
    if (sceneType < 0 || sceneType >= kSceneProtocolValuesCount) {
        [[LogHub sharedHub] e:kTag msg:[NSString stringWithFormat:
            @"Unknown SceneType: %ld, please update ScenarioManager kSceneProtocolValues",
            (long)sceneType]];
        return kUnknownProtocolValue;
    }
    return kSceneProtocolValues[sceneType];
}

// VideoSourceType 协议值查找
// 以枚举 int 作为索引取出协议值，越界时降级为 unknown 并记录 ERROR 日志
+ (NSString *)sourceValue:(VideoSourceType)sourceType {
    if (sourceType < 0 || sourceType >= kSourceProtocolValuesCount) {
        [[LogHub sharedHub] e:kTag msg:[NSString stringWithFormat:
            @"Unknown VideoSourceType: %ld, please update ScenarioManager kSourceProtocolValues",
            (long)sourceType]];
        return kUnknownProtocolValue;
    }
    return kSourceProtocolValues[sourceType];
}

@end
