//
//  LocaleKeys.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 本地化字符串 Key 常量定义。
 *
 * @discussion 所有 PlayerKit 内部使用的本地化字符串 key 均在此文件中声明。
 *             Key 命名规则：<component>.<semantic>，全小写，下划线分隔语义词。
 *             使用类型化常量而非硬编码字符串，确保编译期检查和 IDE 自动补全。
 *
 * @see LocaleManager
 * @see LocaleMacros.h
 */

#pragma mark - PlayState Slot

/** 错误代码标签（如 "错误代码"） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateErrorCodeLabel;
/** 错误信息标签（如 "错误信息"） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateErrorMessageLabel;
/** 默认错误信息（如 "发生了一个意外错误。"） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateErrorMessageDefault;
/** 错误详情格式串（参数: %@ 错误代码标签, %ld 错误码, %@ 错误信息标签, %@ 错误信息） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateErrorDetailsFormat;
/** 加载中提示（如 "加载中..."） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateLoading;
/** 截图完成提示（如 "截图已完成"） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateSnapshotCompleted;
/** 清晰度切换完成提示（参数: %@ 清晰度名称） */
FOUNDATION_EXPORT NSString *const LocaleKeyPlayStateTrackSwitchCompleted;

#pragma mark - BottomBar Slot

/** 时间标签初始值（如 "00:00 / 00:00"） */
FOUNDATION_EXPORT NSString *const LocaleKeyBottomBarTimeZero;
/** 时间格式串（参数: %02ld:%02ld / %02ld:%02ld） */
FOUNDATION_EXPORT NSString *const LocaleKeyBottomBarTimeFormat;
/** 倍速按钮文本 */
FOUNDATION_EXPORT NSString *const LocaleKeyBottomBarSpeed;
/** 清晰度按钮文本 */
FOUNDATION_EXPORT NSString *const LocaleKeyBottomBarQuality;

#pragma mark - CenterDisplay Slot

/** 倍速播放提示（如 "2x 倍速播放中"） */
FOUNDATION_EXPORT NSString *const LocaleKeySpeedPlayingHint;

#pragma mark - SettingMenu Slot

/** 设置面板标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingMenuTitle;
/** 取消按钮文本 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingCancel;

#pragma mark - Setting Item Titles

/** 倍速设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingSpeed;
/** 循环播放设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingLoop;
/** 静音设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingMute;
/** 清晰度设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingQuality;
/** 镜像设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingMirror;
/** 渲染填充设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingScale;
/** 旋转设置项标题 */
FOUNDATION_EXPORT NSString *const LocaleKeySettingRotate;

#pragma mark - Mirror Mode Labels

/** 镜像模式：无 */
FOUNDATION_EXPORT NSString *const LocaleKeyMirrorNone;
/** 镜像模式：水平 */
FOUNDATION_EXPORT NSString *const LocaleKeyMirrorHorizontal;
/** 镜像模式：垂直 */
FOUNDATION_EXPORT NSString *const LocaleKeyMirrorVertical;

#pragma mark - Scale Mode Labels

/** 缩放模式：拉伸填充 */
FOUNDATION_EXPORT NSString *const LocaleKeyScaleFitXY;
/** 缩放模式：适应 */
FOUNDATION_EXPORT NSString *const LocaleKeyScaleFitCenter;
/** 缩放模式：裁剪填充 */
FOUNDATION_EXPORT NSString *const LocaleKeyScaleCenterCrop;

#pragma mark - LogPanel Slot

/** 日志面板标题（展开时） */
FOUNDATION_EXPORT NSString *const LocaleKeyLogPanelTitleHide;
/** 日志面板标题（折叠时） */
FOUNDATION_EXPORT NSString *const LocaleKeyLogPanelTitleShow;
/** 日志面板清除按钮 */
FOUNDATION_EXPORT NSString *const LocaleKeyLogPanelClear;

#pragma mark - LandscapeHint Slot

/** 横屏提示文本（如 "全屏观看"） */
FOUNDATION_EXPORT NSString *const LocaleKeyLandscapeHintFullscreen;

#pragma mark - Chapter

/** 章节数量格式串（参数: %ld 章节总数） */
FOUNDATION_EXPORT NSString *const LocaleKeyChapterCountFormat;
/** 下一章按钮标题 */
FOUNDATION_EXPORT NSString *const LocaleKeyChapterNextButton;
/** 章节导航格式串（参数: %ld 章节序号, %@ 时间文本） */
FOUNDATION_EXPORT NSString *const LocaleKeyChapterNavFormat;

#pragma mark - Common

/** 通用：未知 */
FOUNDATION_EXPORT NSString *const LocaleKeyUnknown;

NS_ASSUME_NONNULL_END
