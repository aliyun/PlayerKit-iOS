//
//  PlayerColor.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright (c) 2024 Alibaba Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerColor : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Text

+ (UIColor *)textWhite;
+ (UIColor *)textShadow;

#pragma mark - Slider / SeekBar

+ (UIColor *)sliderBackground;
+ (UIColor *)sliderTrack;
+ (UIColor *)sliderBuffer;

#pragma mark - Panel (CenterDisplay / PlayState)

+ (UIColor *)panelBackground;
+ (UIColor *)playStateBackground;

#pragma mark - LandscapeHint

+ (UIColor *)landscapeHintBackground;
+ (UIColor *)landscapeHintBorder;

#pragma mark - Setting Menu

+ (UIColor *)settingPanelBackground;
+ (UIColor *)settingItemBackground;
+ (UIColor *)settingDivider;
+ (UIColor *)settingOptionSelected;
+ (UIColor *)settingOptionNormal;

@end

NS_ASSUME_NONNULL_END
