//
//  UsageLifecycleStrategyModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageLifecycleStrategyModule.h"
#import "UsageLifecycleStrategyViewController.h"
#import "UsageCommon.h"

@implementation UsageLifecycleStrategyModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"播放器生命周期策略使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/lifecyclestrategy", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 30;
}

+ (UIViewController *)moduleViewController {
    return [[UsageLifecycleStrategyViewController alloc] init];
}

@end
