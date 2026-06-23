//
//  UsagePreloadSystemModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsagePreloadSystemModule.h"
#import "UsagePreloadSystemViewController.h"
#import "UsageCommon.h"

@implementation UsagePreloadSystemModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"预加载使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/preloadsystem", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 20;
}

+ (UIViewController *)moduleViewController {
    return [[UsagePreloadSystemViewController alloc] init];
}

@end
