//
//  SettingsInitializer.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 设置初始化工具类。
 *
 * @discussion 负责在应用启动时从 UserDefaultsManager 持久化存储中恢复设置并应用到 AliPlayerKit 和 LogHub。
 *             将设置恢复逻辑封装在 DemoSettings 模块内，保持职责清晰。
 *             对标 Android 端 SettingsInitializer。
 *
 * @warning 必须在 AliPlayerKit.setup 之后调用。
 *
 * @see AliPlayerKit
 * @see UserDefaultsManager
 * @see SettingKeys
 */
@interface SettingsInitializer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 从持久化存储恢复设置并应用。
 *
 * @discussion 从 UserDefaultsManager 读取已保存的设置（Debug 模式、日志面板、日志等级），
 *             并应用到 AliPlayerKit 和 LogHub。如果没有已保存的值，使用默认值。
 *             建议在 AppDelegate 的 didFinishLaunching 中、AliPlayerKit.setup 之后调用。
 */
+ (void)setup;

@end

NS_ASSUME_NONNULL_END
