//
//  UsageLogSystemModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/16.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageLogSystemModule.h"
#import "UsageLogSystemViewController.h"
#import "UsageCommon.h"

@implementation UsageLogSystemModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"日志系统使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/logsystem", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 50;
}

+ (UIViewController *)moduleViewController {
    return [[UsageLogSystemViewController alloc] init];
}

@end
