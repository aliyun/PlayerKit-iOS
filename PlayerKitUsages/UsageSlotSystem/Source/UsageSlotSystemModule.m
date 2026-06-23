//
//  UsageSlotSystemModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageSlotSystemModule.h"
#import "UsageSlotSystemViewController.h"
#import "UsageCommon.h"

@implementation UsageSlotSystemModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"插槽系统使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/slotsystem", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 70;
}

+ (UIViewController *)moduleViewController {
    return [[UsageSlotSystemViewController alloc] init];
}

@end
