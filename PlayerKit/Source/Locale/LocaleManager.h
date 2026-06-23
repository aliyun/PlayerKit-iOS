//
//  LocaleManager.h
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocaleProvider.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 语言模式枚举。
 *
 * @discussion 定义 LocaleManager 的语言解析策略。
 */
typedef NS_ENUM(NSInteger, LocaleMode) {
    /** 跟随系统语言（默认） */
    LocaleModeSystem = 0,
    /** 手动指定语言代码 */
    LocaleModeManual,
};

/**
 * @brief 语言变更通知名称。
 *
 * @discussion 当语言模式或语言代码发生变化时，在主线程发送此通知。
 *             userInfo 中包含 LocaleLanguageCodeKey。
 */
FOUNDATION_EXPORT NSNotificationName const LocaleDidChangeNotification;

/**
 * @brief 通知 userInfo 中携带新语言代码的 key。
 */
FOUNDATION_EXPORT NSString *const LocaleLanguageCodeKey;

/**
 * @brief 本地化管理单例。
 *
 * @discussion 管理 PlayerKit 的多语言支持，提供字符串本地化查询、语言切换、
 *             以及自定义 Provider 注入能力。
 *
 *             字符串解析链（Resolution Chain）：
 *             1. Custom Provider（若已注入）
 *             2. 手动指定语言的 Bundle（Manual 模式下）
 *             3. 跟随系统语言的 SDK Bundle
 *             4. 返回 key 本身作为 fallback
 *
 *             此类为单例，禁止外部实例化。
 *
 * @warning 语言切换方法可在任意线程调用，通知始终在主线程发送。
 *
 * @see LocaleProvider
 * @see LocaleKeys.h
 */
@interface LocaleManager : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief 获取单例实例。
 *
 * @return LocaleManager 共享实例。
 */
+ (instancetype)sharedManager;

/**
 * @brief 当前生效的语言代码。
 *
 * @discussion 如 "zh-Hans"、"en" 等。System 模式下返回系统首选语言，
 *             Manual 模式下返回手动指定的语言代码。
 */
@property (nonatomic, copy, readonly) NSString *currentLanguageCode;

/**
 * @brief 当前语言模式。
 *
 * @see LocaleMode
 */
@property (nonatomic, assign, readonly) LocaleMode localeMode;

/**
 * @brief 当前注入的自定义 Provider。
 *
 * @discussion 返回 nil 表示未注入 Provider。
 */
@property (nonatomic, weak, readonly, nullable) id<LocaleProvider> localeProvider;

#pragma mark - Configuration

/**
 * @brief 设置手动语言代码。
 *
 * @discussion 调用后将 localeMode 切换为 LocaleModeManual。
 *             如果指定的语言代码对应的 lproj 不存在，fallback 到 SDK 默认语言。
 *             调用后会发送 LocaleDidChangeNotification。
 *
 * @param languageCode 语言代码（如 @"zh-Hans"、@"en"）。
 *
 * @see resetToSystemLanguage
 */
- (void)setLanguageCode:(NSString *)languageCode;

/**
 * @brief 注入自定义本地化 Provider。
 *
 * @discussion Provider 优先级最高，在 Resolution Chain 中首先查询。
 *             传入 nil 将移除已注入的 Provider。
 *             调用后会发送 LocaleDidChangeNotification。
 *
 * @param provider 遵循 LocaleProvider 协议的对象，弱引用持有。
 *
 * @see LocaleProvider
 */
- (void)setLocaleProvider:(nullable id<LocaleProvider>)provider;

/**
 * @brief 重置为跟随系统语言模式。
 *
 * @discussion 清除手动设定的语言代码，localeMode 恢复为 LocaleModeSystem。
 *             调用后会发送 LocaleDidChangeNotification。
 */
- (void)resetToSystemLanguage;

#pragma mark - String Lookup

/**
 * @brief 查询本地化字符串。
 *
 * @discussion 按照 Resolution Chain 顺序查询：
 *             Provider → Manual Bundle → System Bundle → Key fallback。
 *
 * @param key 本地化字符串 key，对应 LocaleKeys.h 中的常量。
 *
 * @return 本地化后的字符串。若全部 fallback 失败，返回 key 本身。
 *
 * @see LocaleKeys.h
 */
- (NSString *)localizedStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
