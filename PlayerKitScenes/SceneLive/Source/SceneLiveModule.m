//
//  SceneLiveModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneLiveModule.h"
#import "SceneLiveViewController.h"
#import "SceneConstants.h"

@implementation SceneLiveModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"直播";
}

+ (NSString *)moduleSchema {
    return @"playerkit://scenes/live";
}

+ (NSString *)moduleCategory {
    return SceneModuleCategory;
}

+ (NSInteger)modulePriority {
    return 300;
}

+ (UIViewController *)moduleViewController {
    return [[SceneLiveViewController alloc] init];
}

@end
