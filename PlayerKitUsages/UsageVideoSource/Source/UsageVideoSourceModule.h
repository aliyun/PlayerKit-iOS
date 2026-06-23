//
//  UsageVideoSourceModule.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 视频源使用示例模块注册类。
 *
 * @discussion 注册视频源示例到 App 模块系统，由 AppModuleManager 在运行时自动发现。
 *
 * @see AppModuleProtocol
 * @see UsageVideoSourceViewController
 */
@interface UsageVideoSourceModule : NSObject <AppModuleProtocol>

@end

NS_ASSUME_NONNULL_END
