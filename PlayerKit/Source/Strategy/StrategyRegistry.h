//
//  StrategyRegistry.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StrategyProtocol;
@class StrategyManager;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 策略工厂 Block 类型。
 *
 * @discussion 每次调用时创建一个新的策略实例，确保每个控制器拥有独立的策略对象。
 *
 * @return 新创建的策略实例。
 */
typedef id<StrategyProtocol> _Nonnull (^StrategyFactory)(void);

/**
 * @brief 全局策略注册表，管理默认策略工厂。
 *
 * @discussion 维护一组策略工厂 Block 的有序列表。
 *             每当新的 AliPlayerController 创建时，通过 applyToManager:
 *             将所有已注册的工厂实例化并注入到控制器的 StrategyManager 中。
 *             这确保了每个控制器拥有独立的策略实例，避免共享状态。
 *
 *             内置策略（FirstFrameStrategy、StutterDetectStrategy、TrafficProtectionStrategy）
 *             在首次访问时自动注册。
 *
 * @see StrategyManager
 * @see StrategyProtocol
 */
@interface StrategyRegistry : NSObject

/**
 * @brief 获取全局策略注册表单例。
 *
 * @return 全局唯一的注册表实例。
 */
+ (instancetype)sharedRegistry;

/**
 * @brief 添加全局策略工厂。
 *
 * @param factory 策略工厂 Block，每次调用创建一个新实例。
 *
 * @discussion 添加的工厂会在后续所有 applyToManager: 调用中生效。
 *             已创建的控制器不受影响。
 *
 * @see applyToManager:
 */
- (void)addGlobalStrategyFactory:(StrategyFactory)factory;

/**
 * @brief 移除所有已注册的全局策略工厂。
 *
 * @discussion 清空全局策略列表，包括内置策略。
 *             后续创建的控制器将不会自动装载任何策略。
 *
 * @see resetToDefault
 */
- (void)clearGlobalStrategies;

/**
 * @brief 将所有全局策略实例化并注册到指定的策略管理器。
 *
 * @param manager 目标策略管理器。
 *
 * @discussion 遍历所有已注册的工厂，调用每个工厂创建新实例，
 *             然后注册到管理器中。
 */
- (void)applyToManager:(StrategyManager *)manager;

/**
 * @brief 恢复为默认内置策略配置。
 *
 * @discussion 清除所有自定义策略工厂，仅保留内置的三个默认策略。
 */
- (void)resetToDefault;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
