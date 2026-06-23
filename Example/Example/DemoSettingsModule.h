//
//  DemoSettingsModule.h
//  Example
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PlayerKitScenes/AppModuleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Demo 设置模块的注册类。
 *
 * @discussion 遵循 AppModuleProtocol 以便在运行时被 AppModuleManager 自动发现。
 *             放置于 Example 应用层（组合根），避免 DemoSettings 与 PlayerKitScenes 之间的循环依赖。
 *
 * @see SettingViewController
 */
@interface DemoSettingsModule : NSObject <AppModuleProtocol>

@end

NS_ASSUME_NONNULL_END
