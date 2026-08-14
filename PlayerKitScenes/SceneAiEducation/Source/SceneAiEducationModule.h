//
//  SceneAiEducationModule.h
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief AI 教育场景的模块注册类。
 *
 * @discussion 遵循 AppModuleProtocol 以便在运行时被 AppModuleManager 自动发现。
 *             提供模块元数据（标题、Schema、分类、优先级）以及用于创建该场景主视图控制器的工厂方法。
 *
 * @see AppModuleProtocol
 * @see AppModuleManager
 * @see SceneAiEducationViewController
 */
@interface SceneAiEducationModule : NSObject <AppModuleProtocol>

@end

NS_ASSUME_NONNULL_END
