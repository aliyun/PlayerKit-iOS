//
//  PlayerImage.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright (c) 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerImage.h"

@implementation PlayerImage

+ (nullable UIImage *)imageNamed:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [bundle pathForResource:@"PlayerKit" ofType:@"bundle"];
    if (!bundlePath) {
        return nil;
    }
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    NSString *imagePath = [resourceBundle pathForResource:name ofType:@"png" inDirectory:@"Images"];
    if (!imagePath) {
        return nil;
    }
    return [[UIImage alloc] initWithContentsOfFile:imagePath];
}

#pragma mark - TopBar

+ (nullable UIImage *)iconBack {
    return [self imageNamed:@"ic_back"];
}

+ (nullable UIImage *)iconSettings {
    return [self imageNamed:@"ic_settings"];
}

+ (nullable UIImage *)iconSnapshot {
    return [self imageNamed:@"ic_snapshot"];
}

+ (nullable UIImage *)iconDownload {
    return [self imageNamed:@"ic_download"];
}

#pragma mark - BottomBar

+ (nullable UIImage *)iconPlay {
    return [self imageNamed:@"ic_play"];
}

+ (nullable UIImage *)iconPause {
    return [self imageNamed:@"ic_pause"];
}

+ (nullable UIImage *)iconFullscreen {
    return [self imageNamed:@"ic_fullscreen"];
}

+ (nullable UIImage *)iconReplay {
    return [self imageNamed:@"ic_replay"];
}

#pragma mark - CenterDisplay

+ (nullable UIImage *)iconBrightness {
    return [self imageNamed:@"ic_brightness"];
}

+ (nullable UIImage *)iconVolume {
    return [self imageNamed:@"ic_volume"];
}

+ (nullable UIImage *)iconSpeed {
    return [self imageNamed:@"ic_speed"];
}

#pragma mark - PlayState

+ (nullable UIImage *)iconError {
    return [self imageNamed:@"ic_error"];
}

+ (nullable UIImage *)iconLoading {
    return [self imageNamed:@"ic_loading"];
}

+ (nullable UIImage *)iconSuccess {
    return [self imageNamed:@"ic_success"];
}

#pragma mark - LandscapeHint

+ (nullable UIImage *)iconFullscreenHint {
    return [self imageNamed:@"ic_fullscreen_hint"];
}

@end
