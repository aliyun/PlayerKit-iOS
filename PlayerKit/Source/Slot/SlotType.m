//
//  SlotType.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "SlotType.h"

NSString *SlotTypeName(SlotType type) {
    switch (type) {
        case SlotTypePlayerSurface:
            return @"PlayerSurface";
        case SlotTypeGestureControl:
            return @"GestureControl";
        case SlotTypeLandscapeHint:
            return @"LandscapeHint";
        case SlotTypeCover:
            return @"Cover";
        case SlotTypeCenterDisplay:
            return @"CenterDisplay";
        case SlotTypePlayState:
            return @"PlayState";
        case SlotTypeLogPanel:
            return @"LogPanel";
        case SlotTypeTopBar:
            return @"TopBar";
        case SlotTypeBottomBar:
            return @"BottomBar";
        case SlotTypeSettingMenu:
            return @"SettingMenu";
        case SlotTypeOptionPanel:
            return @"OptionPanel";
        default:
            return @"Unknown";
    }
}

NSArray<NSNumber *> *SlotTypeAllBuiltinTypes(void) {
    static NSArray<NSNumber *> *builtinTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builtinTypes = @[
            @(SlotTypePlayerSurface),
            @(SlotTypeGestureControl),
            @(SlotTypeLandscapeHint),
            @(SlotTypeCover),
            @(SlotTypeCenterDisplay),
            @(SlotTypePlayState),
            @(SlotTypeLogPanel),
            @(SlotTypeTopBar),
            @(SlotTypeBottomBar),
            @(SlotTypeSettingMenu),
            @(SlotTypeOptionPanel)
        ];
    });
    return builtinTypes;
}
