//
//  GlobalManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "GlobalManager.h"
#import "FileUtils.h"
#import "ScenarioManager.h"
#import <SDWebImage/SDImageCache.h>

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

// 本地缓存开关
static const BOOL kEnableLocalCache = YES;

// 本地缓存最大缓冲内存（KB）
static const int kLocalCacheMaxBufferMemoryKB = 10 * 1024;

// 本地缓存过期时间（分钟）：30 天
static const int64_t kLocalCacheExpireMin = 30 * 24 * 60;

// 本地缓存最大容量（MB）：20GB
static const int64_t kLocalCacheMaxCapacityMB = 20 * 1024;

// 本地缓存磁盘最小空余（MB）
static const int64_t kLocalCacheFreeStorageMB = 0;

// 缓存目录名称
static NSString * const kCacheSubDirectory = @"AliPlayerKit/Preload";

// SDWebImage 最大内存缓存（Byte）：50 MB
static const NSUInteger kSDImageCacheMaxMemoryCost = 50 * 1024 * 1024;

// SDWebImage 最大磁盘缓存（Byte）：200 MB
static const NSUInteger kSDImageCacheMaxDiskSize = 200 * 1024 * 1024;

@implementation GlobalManager

#pragma mark - Public Methods

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self loadPlayerLicense];
        [self setupExtraData];
        [self setupLocalCache];
        [self setupCacheClearConfig];
        [self setupSDWebImageConfig];
    });
}

+ (void)clearCaches {
    // 清除本地缓存
    [AliPlayerGlobalSettings clearCaches];
    // 清除 SDWebImage 磁盘缓存
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    // 清除 SDWebImage 内存缓存
    [[SDImageCache sharedImageCache] clearMemory];
}

#pragma mark - Private Methods

// 设置全局组件身份标识（用于播放体验优化与问题诊断，请勿覆盖）
+ (void)setupExtraData {
    NSString *extraData = [ScenarioManager buildGlobalExtraData];
    [AliPlayerGlobalSettings setOption:SET_EXTRA_DATA value:extraData];
}

+ (void)setupLocalCache {
    // 构建缓存目录路径
    NSString *cacheDir = [FileUtils combinePaths:@[[FileUtils cachesDirectory], kCacheSubDirectory]];

    // 确保缓存目录存在
    [FileUtils safeCreateDirectoryAtPath:cacheDir error:nil];

    // 启用本地缓存
    [AliPlayerGlobalSettings enableLocalCache:kEnableLocalCache
                            maxBufferMemoryKB:kLocalCacheMaxBufferMemoryKB
                                localCacheDir:cacheDir];
}

+ (void)setupCacheClearConfig {
    // 配置缓存清理策略
    [AliPlayerGlobalSettings setCacheFileClearConfig:kLocalCacheExpireMin
                                       maxCapacityMB:kLocalCacheMaxCapacityMB
                                       freeStorageMB:kLocalCacheFreeStorageMB];
}

// 配置 SDWebImage 的图片缓存设置
+ (void)setupSDWebImageConfig {
    SDImageCache *cache = [SDImageCache sharedImageCache];
    // 配置最大缓存大小（内存和磁盘）
    cache.config.maxMemoryCost = kSDImageCacheMaxMemoryCost;
    cache.config.maxDiskSize = kSDImageCacheMaxDiskSize;
    // 配置磁盘缓存过期时间（秒）
    cache.config.maxDiskAge = 60 * kLocalCacheExpireMin;
}

+ (void)loadPlayerLicense {
    [AliPrivateService initLicenseService];
}

@end
