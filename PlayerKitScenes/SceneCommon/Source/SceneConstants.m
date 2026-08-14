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
    return @"e07a81377f5b71f1ac554531958c0402";
}

+ (NSString *)landscapeSamplePlayAuth {
    return @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6ImFwcC0xMDAwMDAwIiwidmlkZW9JZCI6ImUwN2E4MTM3N2Y1YjcxZjFhYzU1NDUzMTk1OGMwNDAyIiwiY3VycmVudFRpbWVTdGFtcCI6MTc4NDAyMjI1NDY4OSwiZXhwaXJlVGltZVN0YW1wIjoxOTQxNzAyMjU0Njg5LCJyZWdpb25JZCI6ImNuLXNoYW5naGFpIiwicGxheUNvbnRlbnRJbmZvIjp7InN0cmVhbVR5cGUiOiJ2aWRlbyIsImFwaVZlcnNpb24iOiIxLjAuMiIsImF1dGhUaW1lb3V0IjoyODAwMH19.XUCGx2cKrS5FBmrAKTQLpDzN-p07SpSZNRg82xlEKyA";
}

#pragma mark - Portrait Sample

+ (NSString *)portraitSampleVid {
    return @"80b6301d909371f1aa965017f0e80402";
}

+ (NSString *)portraitSamplePlayAuth {
    return @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6ImFwcC0xMDAwMDAwIiwidmlkZW9JZCI6IjgwYjYzMDFkOTA5MzcxZjFhYTk2NTAxN2YwZTgwNDAyIiwiY3VycmVudFRpbWVTdGFtcCI6MTc4NTkwOTgxMTY4MiwiZXhwaXJlVGltZVN0YW1wIjoxOTQzNTg5ODExNjgyLCJyZWdpb25JZCI6ImNuLXNoYW5naGFpIiwicGxheUNvbnRlbnRJbmZvIjp7InN0cmVhbVR5cGUiOiJ2aWRlbyIsImFwaVZlcnNpb24iOiIxLjAuMiIsImF1dGhUaW1lb3V0IjoyODAwMH19.gQN7Iq7ufZXIUbJ8-JAfPI5NmDGIIfZhWUCSXFafMT0";
}

#pragma mark - Sample Video URL

+ (NSString *)sampleVideoURL {
    return @"https://alivc-demo-vod.aliyuncs.com/6b357371ef3c45f4a06e2536fd534380/53733986bce75cfc367d7554a47638c0-fd.mp4";
}

@end
