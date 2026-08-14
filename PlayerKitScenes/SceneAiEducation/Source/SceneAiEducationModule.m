//
//  SceneAiEducationModule.m
//  AliPlayerKit
//
//  Created by keria on 2026/7/28.
//  Copyright © 2026 Alibaba Cloud. All rights reserved.
//

#import "SceneAiEducationModule.h"
#import "SceneAiEducationViewController.h"
#import "SceneConstants.h"

@implementation SceneAiEducationModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"AI 教育";
}

+ (NSString *)moduleSchema {
    return @"playerkit://scenes/aieducation";
}

+ (NSString *)moduleCategory {
    return SceneModuleCategory;
}

+ (NSInteger)modulePriority {
    return 50;
}

+ (UIViewController *)moduleViewController {
    return [[SceneAiEducationViewController alloc] init];
}

@end
