//
//  AliPlayerKit.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/27.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogLevel.h"
#import "Slot.h"
#import "PlayerStateStore.h"
#import "LocaleProvider.h"
#import "FullscreenTransition.h"
#import "DefaultFullscreenTransition.h"

@protocol PlayerFactory;
@protocol PlayerPreloader;

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 全局初始化完成后的自定义配置回调。
 *
 * @discussion 在 +setup 完成内部初始化后触发，仅执行一次。
 *             适用于全局级 SDK 配置，如 setOption、mediaLoader 等。
 *
 * @see setOnGlobalInitBlock:
 */
typedef void (^OnGlobalInitBlock)(void);

/**
 * @brief AliPlayerKit 全局配置入口。
 *
 * @discussion 提供 SDK 初始化、调试模式开关、播放器工厂设置等全局配置能力。
 *             此类不可实例化，所有方法均为类方法。
 *             使用前需调用 setup 进行初始化。
 *
 * @see PlayerFactory
 */
@interface AliPlayerKit : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 初始化 AliPlayerKit。
 *
 * @discussion 内部使用 dispatch_once 保证只执行一次。
 *             建议在 App 启动时调用。
 */
+ (void)setup;

/**
 * @brief 查询 AliPlayerKit 是否已初始化。
 *
 * @discussion 返回 setup 是否已成功执行的状态。
 *             此方法线程安全，可在任意线程调用。
 *
 * @return YES 表示 setup 已调用并完成。
 *
 * @see setup
 */
+ (BOOL)isInitialized;

/**
 * @brief 设置全局初始化自定义配置回调。
 *
 * @param block 全局初始化完成后执行的配置 Block，传入 nil 清除已设置的回调。
 *
 * @discussion 在 +setup 完成内部初始化后触发，仅执行一次。
 *             适用于全局级 SDK 配置，如 setOption、全局日志级别等。
 *             必须在调用 +setup 之前设置，否则不会生效。
 *
 * @see setup
 */
+ (void)setOnGlobalInitBlock:(nullable OnGlobalInitBlock)block;

/**
 * @brief 清除所有播放器缓存。
 *
 * @discussion 清除播放器 SDK 管理的本地媒体缓存文件。
 *             **前置条件**：必须在成功调用 setup 完成初始化之后执行。
 *
 * @warning 在未调用 setup 的情况下调用此方法，可能导致无效操作。
 *
 * @see setup
 */
+ (void)clearCaches;

/**
 * @brief 设置调试模式。
 *
 * @param enabled YES 开启调试模式，NO 关闭。
 */
+ (void)setDebugModeEnabled:(BOOL)enabled;

/**
 * @brief 查询调试模式是否开启。
 *
 * @return YES 表示调试模式已开启。
 */
+ (BOOL)isDebugModeEnabled;

#pragma mark - Log Panel

/**
 * @brief 设置日志面板是否启用。
 *
 * @param enabled YES 启用日志面板，NO 禁用（默认）。
 *
 * @discussion 启用后，LogPanelSlot 将在播放器视图中显示实时日志。
 *             需要在 rebuildSlots 之前设置。
 *             建议仅在调试场景中启用。
 *
 * @see LogPanelSlot
 */
+ (void)setLogPanelEnabled:(BOOL)enabled;

/**
 * @brief 查询日志面板是否启用。
 *
 * @return YES 表示日志面板已启用。
 */
+ (BOOL)isLogPanelEnabled;

#pragma mark - Log

/**
 * @brief 设置日志级别
 *
 * @discussion 低于该级别的日志将被忽略。默认值为 LogLevelInfo。
 * 必须在 +setup 之后调用。
 *
 * @param level 日志级别
 * @see LogLevel
 * @see LogHub
 */
+ (void)setLogLevel:(LogLevel)level;

/**
 * @brief 获取当前日志级别
 *
 * @return 当前生效的日志级别
 * @see LogLevel
 */
+ (LogLevel)logLevel;

/**
 * @brief 启用或禁用控制台日志输出
 *
 * @discussion 禁用后，日志仅通过 LogObserver 通知，不会输出到控制台。
 * 默认启用。
 *
 * @param enable YES 启用控制台日志，NO 禁用
 * @see LogHub
 */
+ (void)enableConsoleLog:(BOOL)enable;

/**
 * @brief 查询控制台日志是否开启
 *
 * @return YES 表示控制台日志已启用
 */
+ (BOOL)isConsoleLogEnabled;

#pragma mark - Player Factory

/**
 * @brief 设置自定义播放器工厂。
 *
 * @param factory 遵循 PlayerFactory 协议的工厂实例。
 *
 * @discussion 设置后，所有播放器实例将通过此工厂创建。
 *             传入 nil 将恢复使用默认工厂。
 *
 * @see PlayerFactory
 */
+ (void)setPlayerFactory:(nullable id<PlayerFactory>)factory;

/**
 * @brief 获取当前播放器工厂。
 *
 * @discussion 未设置自定义工厂时，返回 DefaultPlayerFactory 实例。
 *
 * @return 当前使用的播放器工厂。
 */
+ (id<PlayerFactory>)playerFactory;

#pragma mark - Preloader

/**
 * @brief 设置自定义预加载器。
 *
 * @param preloader 遵循 PlayerPreloader 协议的预加载器实例。
 *
 * @discussion 设置后，预加载任务将通过此预加载器管理。
 *             传入 nil 将恢复使用默认预加载器（DefaultPlayerPreloader）。
 *
 * @see PlayerPreloader
 * @see DefaultPlayerPreloader
 */
+ (void)setPreloader:(nullable id<PlayerPreloader>)preloader;

/**
 * @brief 获取当前预加载器。
 *
 * @discussion 未设置自定义预加载器时，返回 DefaultPlayerPreloader 实例。
 *
 * @return 当前使用的预加载器。
 *
 * @see PlayerPreloader
 */
+ (id<PlayerPreloader>)preloader;

/**
 * @brief 获取 AliPlayerKit 版本号。
 *
 * @return 版本号字符串。
 */
+ (NSString *)getPlayerKitVersion;

/**
 * @brief 获取底层播放器 SDK 版本号。
 *
 * @return SDK 版本号字符串。
 */
+ (NSString *)getSdkVersion;

#pragma mark - Locale

/**
 * @brief 设置手动语言代码。
 *
 * @discussion 调用后 SDK 内部所有 UI 文本将使用指定语言。
 *             支持的语言代码：@"zh-Hans"（简体中文）、@"en"（英语）。
 *             调用后会发送 LocaleDidChangeNotification 通知。
 *
 * @param languageCode 语言代码字符串。
 *
 * @see resetLocaleToSystemLanguage
 * @see LocaleManager
 */
+ (void)setLanguageCode:(NSString *)languageCode;

/**
 * @brief 注入自定义本地化 Provider。
 *
 * @discussion Provider 在字符串解析链中优先级最高。
 *             传入 nil 将移除已注入的 Provider。
 *
 * @param provider 遵循 LocaleProvider 协议的对象。
 *
 * @see LocaleProvider
 */
+ (void)setLocaleProvider:(nullable id<LocaleProvider>)provider;

/**
 * @brief 重置为跟随系统语言。
 *
 * @discussion 清除手动设定的语言代码，恢复跟随系统首选语言。
 *
 * @see setLanguageCode:
 */
+ (void)resetLocaleToSystemLanguage;

/**
 * @brief 获取当前生效的语言代码。
 *
 * @return 当前语言代码字符串（如 @"zh-Hans"、@"en"）。
 */
+ (NSString *)currentLanguageCode;

@end

NS_ASSUME_NONNULL_END
