//
//  DemoSettingsModule.m
//  Example
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "DemoSettingsModule.h"
#import <DemoSettings/SettingViewController.h>

@implementation DemoSettingsModule

#pragma mark - AppModuleProtocol

+ (NSString *)moduleTitle {
    return @"设置";
}

+ (NSString *)moduleSchema {
    return @"playerkit://settings";
}

+ (NSString *)moduleCategory {
    return @"工具";
}

+ (UIViewController *)moduleViewController {
    return [[SettingViewController alloc] init];
}

@end
