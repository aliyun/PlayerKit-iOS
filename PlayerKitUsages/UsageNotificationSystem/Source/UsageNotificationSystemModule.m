//
//  UsageNotificationSystemModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/19.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageNotificationSystemModule.h"
#import "UsageNotificationSystemViewController.h"
#import "UsageCommon.h"

@implementation UsageNotificationSystemModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"事件系统使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/notificationsystem", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 40;
}

+ (UIViewController *)moduleViewController {
    return [[UsageNotificationSystemViewController alloc] init];
}

@end
