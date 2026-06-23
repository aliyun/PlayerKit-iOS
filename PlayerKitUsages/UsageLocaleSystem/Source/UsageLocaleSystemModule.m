//
//  UsageLocaleSystemModule.m
//  PlayerKitUsages
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageLocaleSystemModule.h"
#import "UsageLocaleSystemViewController.h"
#import "UsageCommon.h"

@implementation UsageLocaleSystemModule

+ (NSString *)moduleTitle {
    return @"多语言使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/localesystem", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 10;
}

+ (UIViewController *)moduleViewController {
    return [[UsageLocaleSystemViewController alloc] init];
}

@end
