//
//  SceneLongVideoModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneLongVideoModule.h"
#import "SceneLongVideoViewController.h"
#import "SceneConstants.h"

@implementation SceneLongVideoModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"中长视频";
}

+ (NSString *)moduleSchema {
    return @"playerkit://scenes/longvideo";
}

+ (NSString *)moduleCategory {
    return SceneModuleCategory;
}

+ (NSInteger)modulePriority {
    return 400;
}

+ (UIViewController *)moduleViewController {
    return [[SceneLongVideoViewController alloc] init];
}

@end
