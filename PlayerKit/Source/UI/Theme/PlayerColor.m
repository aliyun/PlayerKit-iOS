//
//  PlayerColor.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright (c) 2024 Alibaba Cloud. All rights reserved.
//

#import "PlayerColor.h"

@implementation PlayerColor

#pragma mark - Text

+ (UIColor *)textWhite {
    return [UIColor whiteColor];
}

+ (UIColor *)textShadow {
    // #66000000
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
}

#pragma mark - Slider / SeekBar

+ (UIColor *)sliderBackground {
    // #4DFFFFFF
    return [UIColor colorWithWhite:1.0 alpha:0.3];
}

+ (UIColor *)sliderTrack {
    // #FFFFFF
    return [UIColor whiteColor];
}

+ (UIColor *)sliderBuffer {
    // #80FFFFFF
    return [UIColor colorWithWhite:1.0 alpha:0.5];
}

#pragma mark - Panel

+ (UIColor *)panelBackground {
    // #CC1C1D22 (80% alpha)
    return [UIColor colorWithRed:0x1C/255.0 green:0x1D/255.0 blue:0x22/255.0 alpha:0.8];
}

+ (UIColor *)playStateBackground {
    // #CC1C1D22 (80% alpha)
    return [UIColor colorWithRed:0x1C/255.0 green:0x1D/255.0 blue:0x22/255.0 alpha:0.8];
}

#pragma mark - LandscapeHint

+ (UIColor *)landscapeHintBackground {
    // #FF202020
    return [UIColor colorWithRed:0x20/255.0 green:0x20/255.0 blue:0x20/255.0 alpha:1.0];
}

+ (UIColor *)landscapeHintBorder {
    // #FF333333
    return [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1.0];
}

#pragma mark - Setting Menu

+ (UIColor *)settingPanelBackground {
    // #E61C1D22 (90% alpha)
    return [UIColor colorWithRed:0x1C/255.0 green:0x1D/255.0 blue:0x22/255.0 alpha:0.9];
}

+ (UIColor *)settingItemBackground {
    // #1AFFFFFF (10% alpha white)
    return [UIColor colorWithWhite:1.0 alpha:0.1];
}

+ (UIColor *)settingDivider {
    // #33FFFFFF (20% alpha white)
    return [UIColor colorWithWhite:1.0 alpha:0.2];
}

+ (UIColor *)settingOptionSelected {
    // #FFFFFFFF
    return [UIColor whiteColor];
}

+ (UIColor *)settingOptionNormal {
    // #99FFFFFF (60% alpha white)
    return [UIColor colorWithWhite:1.0 alpha:0.6];
}

@end
