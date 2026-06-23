//
//  PlayerImage.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright (c) 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerImage : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (nullable UIImage *)imageNamed:(NSString *)name;

#pragma mark - TopBar

+ (nullable UIImage *)iconBack;
+ (nullable UIImage *)iconSettings;
+ (nullable UIImage *)iconSnapshot;
+ (nullable UIImage *)iconDownload;

#pragma mark - BottomBar

+ (nullable UIImage *)iconPlay;
+ (nullable UIImage *)iconPause;
+ (nullable UIImage *)iconFullscreen;
+ (nullable UIImage *)iconReplay;

#pragma mark - CenterDisplay

+ (nullable UIImage *)iconBrightness;
+ (nullable UIImage *)iconVolume;
+ (nullable UIImage *)iconSpeed;

#pragma mark - PlayState

+ (nullable UIImage *)iconError;
+ (nullable UIImage *)iconLoading;
+ (nullable UIImage *)iconSuccess;

#pragma mark - LandscapeHint

+ (nullable UIImage *)iconFullscreenHint;

@end

NS_ASSUME_NONNULL_END
