//
//  ScenePlaylistModule.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "ScenePlaylistModule.h"
#import "ScenePlaylistViewController.h"
#import "SceneConstants.h"

@implementation ScenePlaylistModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"列表播放";
}

+ (NSString *)moduleSchema {
    return @"playerkit://scenes/playlist";
}

+ (NSString *)moduleCategory {
    return SceneModuleCategory;
}

+ (NSInteger)modulePriority {
    return 200;
}

+ (UIViewController *)moduleViewController {
    return [[ScenePlaylistViewController alloc] init];
}

@end
