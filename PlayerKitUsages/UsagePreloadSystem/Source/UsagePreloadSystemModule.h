//
//  UsagePreloadSystemModule.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 预加载系统用法示例的模块注册类。
 *
 * @discussion 遵循 AppModuleProtocol 以便在运行时被 AppModuleManager 自动发现。
 *             提供模块元数据（标题、Schema、描述、分类）以及用于创建该用法示例主视图控制器的工厂方法。
 *
 * @see AppModuleProtocol
 * @see AppModuleManager
 * @see UsagePreloadSystemViewController
 */
@interface UsagePreloadSystemModule : NSObject <AppModuleProtocol>

@end

NS_ASSUME_NONNULL_END
