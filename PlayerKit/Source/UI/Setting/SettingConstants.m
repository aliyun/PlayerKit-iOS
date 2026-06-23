//
//  SettingConstants.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SettingConstants.h"
#import "SettingItem.h"
#import "SettingOptions.h"
#import "SceneType.h"
#import "SlotElements.h"
#import "MirrorMode.h"
#import "ScaleMode.h"
#import "RotateMode.h"
#import "TrackQuality.h"
#import "AliPlayerController.h"
#import "TrackUtil.h"
#import "LocaleMacros.h"
#import "LocaleKeys.h"

const NSInteger SettingGroupPlayback = 0;
const NSInteger SettingGroupAudio = 1;
const NSInteger SettingGroupDisplay = 2;

const CGFloat SettingItemHeight = 54.0;
const CGFloat SettingItemHorizontalPadding = 16.0;
const CGFloat SettingItemTitleFontSize = 15.0;
const CGFloat SettingItemSeparatorHeight = 1.0;

static const float kSpeedOptions[] = {0.3f, 0.5f, 1.0f, 1.5f, 2.0f, 3.0f};
static const NSInteger kSpeedOptionsCount = sizeof(kSpeedOptions) / sizeof(kSpeedOptions[0]);

static const NSInteger kMirrorOptions[] = {MirrorModeNone, MirrorModeHorizontal, MirrorModeVertical};
static const NSInteger kMirrorOptionsCount = sizeof(kMirrorOptions) / sizeof(kMirrorOptions[0]);

static const NSInteger kScaleOptions[] = {ScaleModeFitXY, ScaleModeFitCenter, ScaleModeCenterCrop};
static const NSInteger kScaleOptionsCount = sizeof(kScaleOptions) / sizeof(kScaleOptions[0]);

static const NSInteger kRotateOptions[] = {RotateModeDegree0, RotateModeDegree90, RotateModeDegree180, RotateModeDegree270};
static const NSInteger kRotateOptionsCount = sizeof(kRotateOptions) / sizeof(kRotateOptions[0]);

@implementation SettingConstants

+ (NSArray<SettingItem *> *)defaultItemsWithController:(AliPlayerController *)controller {
    NSMutableArray<SettingItem *> *items = [NSMutableArray array];

    __weak AliPlayerController *weakController = controller;

    // 倍速（VOD、VideoList、Minimal 支持）
    NSMutableIndexSet *speedScenes = [NSMutableIndexSet indexSet];
    [speedScenes addIndex:SceneTypeVOD];
    [speedScenes addIndex:SceneTypeVideoList];
    [speedScenes addIndex:SceneTypeMinimal];

    SettingItem *speedItem = [[SettingItem alloc] initWithElement:SettingMenuElementSpeed
                                                            title:LocalizedString(LocaleKeySettingSpeed)
                                                             type:SettingItemTypeSelector
                                                     initialValue:@1.0f];
    NSMutableArray *speedOptionValues = [NSMutableArray arrayWithCapacity:kSpeedOptionsCount];
    for (NSInteger i = 0; i < kSpeedOptionsCount; i++) {
        [speedOptionValues addObject:@(kSpeedOptions[i])];
    }
    speedItem.options = [ArraySettingOptions optionsWithArray:speedOptionValues];
    speedItem.formatterBlock = ^NSString *(id value) {
        return [NSString stringWithFormat:@"%@x", value];
    };
    speedItem.supportedScenes = speedScenes;
    speedItem.group = SettingGroupPlayback;
    speedItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController setRate:[newValue floatValue]];
    };
    [items addObject:speedItem];

    // 循环播放（VOD、VideoList、Restricted、Minimal 支持）
    NSMutableIndexSet *loopScenes = [NSMutableIndexSet indexSet];
    [loopScenes addIndex:SceneTypeVOD];
    [loopScenes addIndex:SceneTypeVideoList];
    [loopScenes addIndex:SceneTypeRestricted];
    [loopScenes addIndex:SceneTypeMinimal];

    SettingItem *loopItem = [[SettingItem alloc] initWithElement:SettingMenuElementLoop
                                                           title:LocalizedString(LocaleKeySettingLoop)
                                                            type:SettingItemTypeSwitcher
                                                    initialValue:@NO];
    loopItem.supportedScenes = loopScenes;
    loopItem.group = SettingGroupAudio;
    loopItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController setLoop:[newValue boolValue]];
    };
    [items addObject:loopItem];

    // 静音
    SettingItem *muteItem = [[SettingItem alloc] initWithElement:SettingMenuElementMute
                                                           title:LocalizedString(LocaleKeySettingMute)
                                                            type:SettingItemTypeSwitcher
                                                    initialValue:@NO];
    muteItem.group = SettingGroupAudio;
    muteItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController setMuted:[newValue boolValue]];
    };
    [items addObject:muteItem];

    // 清晰度（options 运行时动态设置）
    SettingItem *qualityItem = [[SettingItem alloc] initWithElement:SettingMenuElementTrackInfo
                                                              title:LocalizedString(LocaleKeySettingQuality)
                                                               type:SettingItemTypeSelector
                                                       initialValue:nil];
    qualityItem.formatterBlock = ^NSString *(id value) {
        return [TrackUtil findNearestResolution:value];
    };
    qualityItem.group = SettingGroupPlayback;
    qualityItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController selectTrack:(TrackQuality *)newValue];
    };
    [items addObject:qualityItem];

    // 镜像模式
    NSMutableArray *mirrorOptionValues = [NSMutableArray arrayWithCapacity:kMirrorOptionsCount];
    for (NSInteger i = 0; i < kMirrorOptionsCount; i++) {
        [mirrorOptionValues addObject:@(kMirrorOptions[i])];
    }

    SettingItem *mirrorItem = [[SettingItem alloc] initWithElement:SettingMenuElementMirrorMode
                                                             title:LocalizedString(LocaleKeySettingMirror)
                                                              type:SettingItemTypeSelector
                                                      initialValue:@(MirrorModeNone)];
    mirrorItem.options = [ArraySettingOptions optionsWithArray:mirrorOptionValues];
    mirrorItem.group = SettingGroupDisplay;
    mirrorItem.formatterBlock = ^NSString *(id value) {
        switch ([value integerValue]) {
            case MirrorModeNone: return LocalizedString(LocaleKeyMirrorNone);
            case MirrorModeHorizontal: return LocalizedString(LocaleKeyMirrorHorizontal);
            case MirrorModeVertical: return LocalizedString(LocaleKeyMirrorVertical);
            default: return LocalizedString(LocaleKeyUnknown);
        }
    };
    mirrorItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController setMirrorMode:(MirrorMode)[newValue integerValue]];
    };
    [items addObject:mirrorItem];

    // 缩放模式
    NSMutableArray *scaleOptionValues = [NSMutableArray arrayWithCapacity:kScaleOptionsCount];
    for (NSInteger i = 0; i < kScaleOptionsCount; i++) {
        [scaleOptionValues addObject:@(kScaleOptions[i])];
    }

    SettingItem *scaleItem = [[SettingItem alloc] initWithElement:SettingMenuElementScaleMode
                                                            title:LocalizedString(LocaleKeySettingScale)
                                                             type:SettingItemTypeSelector
                                                     initialValue:@(ScaleModeFitCenter)];
    scaleItem.options = [ArraySettingOptions optionsWithArray:scaleOptionValues];
    scaleItem.group = SettingGroupDisplay;
    scaleItem.formatterBlock = ^NSString *(id value) {
        switch ([value integerValue]) {
            case ScaleModeFitXY: return LocalizedString(LocaleKeyScaleFitXY);
            case ScaleModeFitCenter: return LocalizedString(LocaleKeyScaleFitCenter);
            case ScaleModeCenterCrop: return LocalizedString(LocaleKeyScaleCenterCrop);
            default: return LocalizedString(LocaleKeyUnknown);
        }
    };
    scaleItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController setScaleMode:(ScaleMode)[newValue integerValue]];
    };
    [items addObject:scaleItem];

    // 旋转模式
    NSMutableArray *rotateOptionValues = [NSMutableArray arrayWithCapacity:kRotateOptionsCount];
    for (NSInteger i = 0; i < kRotateOptionsCount; i++) {
        [rotateOptionValues addObject:@(kRotateOptions[i])];
    }

    SettingItem *rotateItem = [[SettingItem alloc] initWithElement:SettingMenuElementRotateMode
                                                             title:LocalizedString(LocaleKeySettingRotate)
                                                              type:SettingItemTypeSelector
                                                      initialValue:@(RotateModeDegree0)];
    rotateItem.options = [ArraySettingOptions optionsWithArray:rotateOptionValues];
    rotateItem.group = SettingGroupDisplay;
    rotateItem.formatterBlock = ^NSString *(id value) {
        return [NSString stringWithFormat:@"%@°", value];
    };
    rotateItem.valueChangedBlock = ^(SettingItem *item, id newValue) {
        [weakController setRotateMode:(RotateMode)[newValue integerValue]];
    };
    [items addObject:rotateItem];

    return [items copy];
}

@end
