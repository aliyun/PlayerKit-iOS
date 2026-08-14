//
//  DefaultSlotFactory.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/23.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "DefaultSlotFactory.h"
#import "SlotConfig.h"
#import "SceneType.h"
#import "AliPlayerKit.h"

#import "PlayerSurfaceSlot.h"
#import "GestureControlSlot.h"
#import "LandscapeHintSlot.h"
#import "CoverSlot.h"
#import "CenterDisplaySlot.h"
#import "SeekThumbnailSlot.h"
#import "PlayStateSlot.h"
#import "LogPanelSlot.h"
#import "TopBarSlot.h"
#import "BottomBarSlot.h"
#import "SettingMenuSlot.h"
#import "OptionPanelSlot.h"
#import "ChapterPanelSlot.h"

@implementation DefaultSlotFactory

+ (NSDictionary<NSNumber *, SlotProvider> *)defaultProviders {
    return @{
        @(SlotTypePlayerSurface):  ^UIView<SlotProtocol> *(UIView *parentView) { return [[PlayerSurfaceSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeGestureControl): ^UIView<SlotProtocol> *(UIView *parentView) { return [[GestureControlSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeLandscapeHint):  ^UIView<SlotProtocol> *(UIView *parentView) { return [[LandscapeHintSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeCover):          ^UIView<SlotProtocol> *(UIView *parentView) { return [[CoverSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeCenterDisplay):  ^UIView<SlotProtocol> *(UIView *parentView) { return [[CenterDisplaySlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeSeekThumbnail):  ^UIView<SlotProtocol> *(UIView *parentView) { return [[SeekThumbnailSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypePlayState):      ^UIView<SlotProtocol> *(UIView *parentView) { return [[PlayStateSlot alloc] initWithFrame:parentView.bounds]; },
        // LogPanel 仅在 logPanelEnabled 时创建，需在 rebuildSlots 前设置
        @(SlotTypeLogPanel):       ^UIView<SlotProtocol> * _Nullable (UIView *parentView) { return [AliPlayerKit isLogPanelEnabled] ? [[LogPanelSlot alloc] initWithFrame:parentView.bounds] : nil; },
        @(SlotTypeTopBar):         ^UIView<SlotProtocol> *(UIView *parentView) { return [[TopBarSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeBottomBar):      ^UIView<SlotProtocol> *(UIView *parentView) { return [[BottomBarSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeSettingMenu):    ^UIView<SlotProtocol> *(UIView *parentView) { return [[SettingMenuSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeOptionPanel):    ^UIView<SlotProtocol> *(UIView *parentView) { return [[OptionPanelSlot alloc] initWithFrame:parentView.bounds]; },
        @(SlotTypeChapterPanel):   ^UIView<SlotProtocol> *(UIView *parentView) { return [[ChapterPanelSlot alloc] initWithFrame:parentView.bounds]; },
    };
}

+ (NSArray<SlotConfig *> *)defaultConfigs {
    return @[
        [SlotConfig configWithSlotType:SlotTypePlayerSurface],
        [SlotConfig configWithSlotType:SlotTypePlayState],

        [SlotConfig configWithSlotType:SlotTypeGestureControl  excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeLandscapeHint   excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeCenterDisplay   excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeSeekThumbnail   excludedScenes:[NSSet setWithObjects:@(SceneTypeLive), @(SceneTypeRestricted), @(SceneTypeMinimal), nil]],
        [SlotConfig configWithSlotType:SlotTypeLogPanel        excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeTopBar          excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeBottomBar       excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeSettingMenu     excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeOptionPanel     excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],
        [SlotConfig configWithSlotType:SlotTypeChapterPanel    excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]],

        // Cover 在 live/restricted/minimal 场景下排除
        [SlotConfig configWithSlotType:SlotTypeCover excludedScenes:[NSSet setWithObjects:@(SceneTypeLive), @(SceneTypeRestricted), @(SceneTypeMinimal), nil]],
    ];
}

@end
