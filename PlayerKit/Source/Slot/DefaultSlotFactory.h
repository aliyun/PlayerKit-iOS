//
//  DefaultSlotFactory.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/23.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlotProtocol.h"
#import "SlotType.h"

@class SlotConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 默认插槽工厂。
 *
 * @discussion 集中管理 PlayerKit 自带的所有内置插槽：
 *             - defaultProviders：SlotType → SlotProvider 的工厂闭包映射
 *             - defaultConfigs：内置插槽的场景可见性配置
 *
 *             SlotManager 在初始化时一次性拉取这两份数据完成默认注册。
 *             新增/移除内置插槽仅需修改本文件。
 *
 * @see SlotProvider
 * @see SlotConfig
 * @see SlotManager
 */
@interface DefaultSlotFactory : NSObject

/**
 * @brief 内置插槽工厂表。
 *
 * @return SlotType（NSNumber 包装）→ SlotProvider 的不可变字典。
 */
+ (NSDictionary<NSNumber *, SlotProvider> *)defaultProviders;

/**
 * @brief 内置插槽场景可见性配置。
 *
 * @discussion 各插槽类型的默认可见性规则：
 *             - PlayerSurface/PlayState：始终可见
 *             - GestureControl/LandscapeHint/CenterDisplay/SeekThumbnail/LogPanel/TopBar/BottomBar/SettingMenu/OptionPanel：在 SceneTypeMinimal 中不可见
 *             - Cover：在 Live/Restricted/Minimal 场景中不可见
 *
 * @return SlotConfig 数组。
 */
+ (NSArray<SlotConfig *> *)defaultConfigs;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
