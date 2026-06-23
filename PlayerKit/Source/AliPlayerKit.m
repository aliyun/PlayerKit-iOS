//
//  AliPlayerKit.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "AliPlayerKit.h"
#import "DefaultPlayerFactory.h"
#import "PlayerPreloader.h"
#import "DefaultPlayerPreloader.h"
#import "GlobalManager.h"
#import "LogHub.h"
#import "LocaleManager.h"

#if __has_include(<AliVCSDK_Standard/AliVCSDK_Standard.h>)
#import <AliVCSDK_Standard/AliVCSDK_Standard.h>

#elif __has_include(<AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>)
#import <AliVCSDK_InteractiveLive/AliVCSDK_InteractiveLive.h>

#elif __has_include(<AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>)
#import <AliVCSDK_BasicLive/AliVCSDK_BasicLive.h>

#elif __has_include(<AliVCSDK_UGC/AliVCSDK_UGC.h>)
#import <AliVCSDK_UGC/AliVCSDK_UGC.h>

#endif

#if __has_include(<AliyunPlayer/AliyunPlayer.h>)
#import <AliyunPlayer/AliyunPlayer.h>
#endif

/**
 * @brief AliPlayerKit 版本号。
 *
 * @discussion AliPlayerKit version number.
 */
static NSString * const kPlayerKitVersion = @"7.15.0";

static BOOL sInitialized = NO;
static BOOL sDebugModeEnabled = NO;
static id<PlayerFactory> sPlayerFactory = nil;
static OnGlobalInitBlock sGlobalInitBlock = nil;
static id<PlayerPreloader> sPreloader = nil;
static BOOL sLogPanelEnabled = NO;

@implementation AliPlayerKit

#pragma mark - Public Methods

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [GlobalManager setup];
        sInitialized = YES;

        if (sGlobalInitBlock) {
            sGlobalInitBlock();
            sGlobalInitBlock = nil;
        }
    });
}

+ (BOOL)isInitialized {
    return sInitialized;
}

+ (void)setOnGlobalInitBlock:(nullable OnGlobalInitBlock)block {
    sGlobalInitBlock = [block copy];
}

+ (void)clearCaches {
    [GlobalManager clearCaches];
}

+ (void)setDebugModeEnabled:(BOOL)enabled {
    sDebugModeEnabled = enabled;
}

+ (BOOL)isDebugModeEnabled {
    return sDebugModeEnabled;
}

#pragma mark - Log Panel

+ (void)setLogPanelEnabled:(BOOL)enabled {
    sLogPanelEnabled = enabled;
}

+ (BOOL)isLogPanelEnabled {
    return sLogPanelEnabled;
}

#pragma mark - Log

+ (void)setLogLevel:(LogLevel)level {
    [LogHub sharedHub].logLevel = level;
}

+ (LogLevel)logLevel {
    return [LogHub sharedHub].logLevel;
}

+ (void)enableConsoleLog:(BOOL)enable {
    [LogHub sharedHub].consoleLogEnabled = enable;
}

+ (BOOL)isConsoleLogEnabled {
    return [LogHub sharedHub].consoleLogEnabled;
}

#pragma mark - Player Factory

+ (void)setPlayerFactory:(nullable id<PlayerFactory>)factory {
    @synchronized (self) {
        sPlayerFactory = factory;
    }
}

+ (id<PlayerFactory>)playerFactory {
    @synchronized (self) {
        if (!sPlayerFactory) {
            sPlayerFactory = [[DefaultPlayerFactory alloc] init];
        }
        return sPlayerFactory;
    }
}

#pragma mark - Preloader

+ (void)setPreloader:(nullable id<PlayerPreloader>)preloader {
    @synchronized (self) {
        sPreloader = preloader;
    }
}

+ (id<PlayerPreloader>)preloader {
    @synchronized (self) {
        if (!sPreloader) {
            sPreloader = [[DefaultPlayerPreloader alloc] init];
        }
        return sPreloader;
    }
}

+ (NSString *)getPlayerKitVersion {
    return kPlayerKitVersion;
}

+ (NSString *)getSdkVersion {
    return [AliPlayer getSDKVersion];
}

#pragma mark - Locale

+ (void)setLanguageCode:(NSString *)languageCode {
    [[LocaleManager sharedManager] setLanguageCode:languageCode];
}

+ (void)setLocaleProvider:(nullable id<LocaleProvider>)provider {
    [[LocaleManager sharedManager] setLocaleProvider:provider];
}

+ (void)resetLocaleToSystemLanguage {
    [[LocaleManager sharedManager] resetToSystemLanguage];
}

+ (NSString *)currentLanguageCode {
    return [LocaleManager sharedManager].currentLanguageCode;
}

@end
