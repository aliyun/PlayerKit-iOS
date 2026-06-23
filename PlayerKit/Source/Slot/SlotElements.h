//
//  SlotElements.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 插槽内子元素的位掩码常量定义。
 *
 * @discussion 配合 SlotManager 的 hideElements:forSlot: / showElements:forSlot: 方法使用，
 *             实现对插槽内单个 UI 元素的细粒度可见性控制。
 *             每组 NS_OPTIONS 对应一种插槽类型内部的子元素。
 *             各 Slot 子类通过 onRegisterElements 声明默认可见的元素组合。
 *
 * @see SlotManager
 * @see BaseSlot
 */

#pragma mark - TopBar Elements

typedef NS_OPTIONS(NSUInteger, TopBarElement) {
    TopBarElementBack     = 1 << 0,
    TopBarElementTitle    = 1 << 1,
    TopBarElementDownload = 1 << 2,
    TopBarElementSnapshot = 1 << 3,
    TopBarElementSettings = 1 << 4,
};

#pragma mark - BottomBar Elements

typedef NS_OPTIONS(NSUInteger, BottomBarElement) {
    BottomBarElementPlay     = 1 << 0,
    BottomBarElementProgress = 1 << 1,
    BottomBarElementRefresh  = 1 << 2,
    BottomBarElementSpeed    = 1 << 3,  // 倍速按钮（仅横屏布局可见，默认开启）
};

#pragma mark - SettingMenu Elements

typedef NS_OPTIONS(NSUInteger, SettingMenuElement) {
    SettingMenuElementSpeed      = 1 << 0,
    SettingMenuElementTrackInfo  = 1 << 1,
    SettingMenuElementLoop       = 1 << 2,
    SettingMenuElementMute       = 1 << 3,
    SettingMenuElementMirrorMode = 1 << 4,
    SettingMenuElementRotateMode = 1 << 5,
    SettingMenuElementScaleMode  = 1 << 6,
    SettingMenuElementSubtitle   = 1 << 7,
};

#pragma mark - CenterDisplay Elements

typedef NS_OPTIONS(NSUInteger, CenterDisplayElement) {
    CenterDisplayElementVolume     = 1 << 0,
    CenterDisplayElementBrightness = 1 << 1,
    CenterDisplayElementSpeed      = 1 << 2,
};

#pragma mark - GestureControl Elements

/**
 * @brief 手势控制元素位掩码。
 *
 * @discussion 这些常量控制手势交互的启用/禁用，而非 UI 元素的显隐。
 *             当某个手势位被设置为隐藏时，该手势将被禁用。
 */
typedef NS_OPTIONS(NSUInteger, GestureElement) {
    GestureElementSingleTap         = 1 << 0,
    GestureElementDoubleTap         = 1 << 1,
    GestureElementLongPress         = 1 << 2,
    GestureElementHorizontalDrag    = 1 << 3,
    GestureElementLeftVerticalDrag  = 1 << 4,
    GestureElementRightVerticalDrag = 1 << 5,
};

#pragma mark - PlayState Elements

typedef NS_OPTIONS(NSUInteger, PlayStateElement) {
    PlayStateElementErrorMessage   = 1 << 0,
    PlayStateElementLoadingMessage = 1 << 1,
};

NS_ASSUME_NONNULL_END
