//
//  SlotType.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 播放器视图插槽系统的插槽类型枚举。
 *
 * @discussion 定义播放器视图使用的内置插槽类型。
 *             枚举值间隔 10，以便后续插入新类型时不影响现有排序。
 *             枚举值的大小决定了插槽的 Z 轴顺序
 *             （值越小的插槽位于值越大的插槽下方）。
 *
 * @see SlotTypeName
 * @see SlotTypeAllBuiltinTypes
 */
typedef NS_ENUM(NSInteger, SlotType) {
    /** 播放器渲染视图层 */
    SlotTypePlayerSurface = 10,

    /** 手势识别和控制层 */
    SlotTypeGestureControl = 20,

    /** 横屏提示层 */
    SlotTypeLandscapeHint = 30,

    /** 视频封面图层 */
    SlotTypeCover = 40,

    /** 中心展示层（如加载指示器） */
    SlotTypeCenterDisplay = 50,

    /** 播放状态指示层 */
    SlotTypePlayState = 60,

    /** 日志面板层 */
    SlotTypeLogPanel = 70,

    /** 顶部导航栏层 */
    SlotTypeTopBar = 80,

    /** 底部控制栏层 */
    SlotTypeBottomBar = 90,

    /** 设置菜单层 */
    SlotTypeSettingMenu = 100,

    /** 选项面板层（倍速/清晰度） */
    SlotTypeOptionPanel = 110
};

/**
 * @brief 返回指定插槽类型的可读名称字符串。
 *
 * @param type 要转换的插槽类型。
 *
 * @return 描述该插槽类型的常量字符串，未识别的类型返回 @c @"Unknown"。
 */
FOUNDATION_EXPORT NSString *SlotTypeName(SlotType type);

/**
 * @brief 返回所有内置插槽类型的有序数组。
 *
 * @discussion 数组按枚举值升序排列，对应构建插槽时的 Z 轴顺序。
 *
 * @return 包含 @c NSNumber 包装的 @c SlotType 值的不可变数组。
 */
FOUNDATION_EXPORT NSArray<NSNumber *> *SlotTypeAllBuiltinTypes(void);

NS_ASSUME_NONNULL_END
