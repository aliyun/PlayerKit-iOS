//
//  UsageVideoSourceModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UsageVideoSourceModule.h"
#import "UsageVideoSourceViewController.h"
#import "UsageCommon.h"

@implementation UsageVideoSourceModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"视频源使用示例";
}

+ (NSString *)moduleSchema {
    return [NSString stringWithFormat:@"playerkit://%@/videosource", UsageSchemaHost];
}

+ (NSString *)moduleCategory {
    return UsageModuleCategory;
}

+ (NSInteger)modulePriority {
    return 80;
}

+ (UIViewController *)moduleViewController {
    return [[UsageVideoSourceViewController alloc] init];
}

@end
