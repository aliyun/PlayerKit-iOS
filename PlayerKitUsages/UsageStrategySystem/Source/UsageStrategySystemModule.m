//
//  UsageStrategySystemModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageStrategySystemModule.h"
#import "UsageStrategySystemViewController.h"
#import "UsageCommon.h"

@implementation UsageStrategySystemModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"策略系统使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/strategysystem", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 60;
}

+ (UIViewController *)moduleViewController {
    return [[UsageStrategySystemViewController alloc] init];
}

@end
