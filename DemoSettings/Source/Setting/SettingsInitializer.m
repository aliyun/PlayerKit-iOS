//
//  SettingsInitializer.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingsInitializer.h"
#import "UserDefaultsManager.h"
#import "SettingKeys.h"
#import <PlayerKit/AliPlayerKit.h>
#import <PlayerKit/LogLevel.h>

@implementation SettingsInitializer

#pragma mark - Public Methods

+ (void)setup {
    [self restoreDebugModeSettings];
    [self restoreLogSettings];
}

#pragma mark - Private Methods

// 恢复 Debug 模式设置
+ (void)restoreDebugModeSettings {
    BOOL defaultDebugMode = [AliPlayerKit isDebugModeEnabled];
    BOOL enableDebugMode = [[UserDefaultsManager sharedInstance] boolForKey:SettingKeyDebugMode defValue:defaultDebugMode];
    [AliPlayerKit setDebugModeEnabled:enableDebugMode];
}

// 恢复日志相关设置（日志面板开关 + 日志等级）
+ (void)restoreLogSettings {
    // 恢复日志面板开关
    BOOL defaultLogPanel = [AliPlayerKit isLogPanelEnabled];
    BOOL enableLogPanel = [[UserDefaultsManager sharedInstance] boolForKey:SettingKeyEnableLogPanel defValue:defaultLogPanel];
    [AliPlayerKit setLogPanelEnabled:enableLogPanel];

    // 恢复日志等级
    NSInteger defaultLevel = (NSInteger)[AliPlayerKit logLevel];
    NSInteger logLevel = [[UserDefaultsManager sharedInstance] integerForKey:SettingKeyLogLevel defValue:defaultLevel];
    [AliPlayerKit setLogLevel:(LogLevel)logLevel];
}

@end
