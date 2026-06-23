//
//  SceneShortVideoModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneShortVideoModule.h"
#import "SceneShortVideoViewController.h"
#import "SceneConstants.h"

@implementation SceneShortVideoModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"短视频列表播放";
}

+ (NSString *)moduleSchema {
    return @"playerkit://scenes/shortvideo";
}

+ (NSString *)moduleCategory {
    return SceneModuleCategory;
}

+ (NSInteger)modulePriority {
    return 100;
}

+ (UIViewController *)moduleViewController {
    return [[SceneShortVideoViewController alloc] init];
}

@end
