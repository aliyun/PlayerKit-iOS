//
//  SceneConstants.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/17.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SceneConstants.h"

#pragma mark - Module Category

NSString * const SceneModuleCategory = @"播放场景";

@implementation SceneConstants

#pragma mark - Landscape Sample

+ (NSString *)landscapeSampleVid {
    return @"004fc90fd71d71f0bf184531958c0402";
}

+ (NSString *)landscapeSamplePlayAuth {
    return @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6ImFwcC0xMDAwMDAwIiwidmlkZW9JZCI6IjAwNGZjOTBmZDcxZDcxZjBiZjE4NDUzMTk1OGMwNDAyIiwiY3VycmVudFRpbWVTdGFtcCI6MTc2NjEzMTE5MTYxMywiZXhwaXJlVGltZVN0YW1wIjoxOTIzODExMTkxNjEzLCJyZWdpb25JZCI6ImNuLXNoYW5naGFpIiwicGxheUNvbnRlbnRJbmZvIjp7ImZvcm1hdHMiOiJtM3U4Iiwic3RyZWFtVHlwZSI6InZpZGVvIiwiYXV0aFRpbWVvdXQiOjE4MDB9fQ.CjqZA-6okJb2PxOZr0Jjai9gWwvaNdG-bk3LWBMzhdc";
}

#pragma mark - Portrait Sample

+ (NSString *)portraitSampleVid {
    return @"00e9b526d0d671f085715017f1e90402";
}

+ (NSString *)portraitSamplePlayAuth {
    return @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6ImFwcC0xMDAwMDAwIiwidmlkZW9JZCI6IjAwZTliNTI2ZDBkNjcxZjA4NTcxNTAxN2YxZTkwNDAyIiwiY3VycmVudFRpbWVTdGFtcCI6MTc2ODE4ODIzNzAwNiwiZXhwaXJlVGltZVN0YW1wIjoxOTI1ODY4MjM3MDA2LCJyZWdpb25JZCI6ImNuLXNoYW5naGFpIiwicGxheUNvbnRlbnRJbmZvIjp7ImZvcm1hdHMiOiJtM3U4Iiwic3RyZWFtVHlwZSI6InZpZGVvIiwiYXV0aFRpbWVvdXQiOjE4MDB9fQ.AwXM5c8EsLJbhTPoNbEiB3uFVkl7heukuFbntHmC7no";
}

#pragma mark - Sample Video URL

+ (NSString *)sampleVideoURL {
    return @"https://alivc-demo-vod.aliyuncs.com/6b357371ef3c45f4a06e2536fd534380/53733986bce75cfc367d7554a47638c0-fd.mp4";
}

@end
