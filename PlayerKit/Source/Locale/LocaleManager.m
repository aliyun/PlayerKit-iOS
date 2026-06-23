//
//  LocaleManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "LocaleManager.h"
#import "Log.h"

NSNotificationName const LocaleDidChangeNotification = @"LocaleDidChangeNotification";
NSString *const LocaleLanguageCodeKey = @"LocaleLanguageCodeKey";

static NSString *const kLocaleTableName = @"Localizable";
static NSString *const kDefaultLanguageCode = @"zh-Hans";

@interface LocaleManager ()

@property (nonatomic, copy, readwrite) NSString *currentLanguageCode;
@property (nonatomic, assign, readwrite) LocaleMode localeMode;
@property (nonatomic, weak, readwrite) id<LocaleProvider> localeProvider;

@property (nonatomic, strong) NSBundle *sdkBundle;
@property (nonatomic, strong) NSBundle *activeBundle;
@property (nonatomic, strong) dispatch_queue_t localeQueue;

@end

@implementation LocaleManager

#pragma mark - Property Accessors

- (NSString *)currentLanguageCode {
    __block NSString *code;
    dispatch_sync(self.localeQueue, ^{
        code = self->_currentLanguageCode;
    });
    return code;
}

- (LocaleMode)localeMode {
    __block LocaleMode mode;
    dispatch_sync(self.localeQueue, ^{
        mode = self->_localeMode;
    });
    return mode;
}

#pragma mark - Lifecycle

+ (instancetype)sharedManager {
    static LocaleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initPrivate];
    });
    return instance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _localeQueue = dispatch_queue_create("com.aliyun.playerkit.locale", DISPATCH_QUEUE_SERIAL);
        _localeMode = LocaleModeSystem;
        _sdkBundle = [self loadSDKBundle];
        _currentLanguageCode = [self resolveSystemLanguageCode];
        _activeBundle = [self bundleForLanguageCode:_currentLanguageCode];
    }
    return self;
}

#pragma mark - Configuration

- (void)setLanguageCode:(NSString *)languageCode {
    if (!languageCode.length) {
        return;
    }

    __block BOOL changed = NO;
    dispatch_sync(self.localeQueue, ^{
        if (![self->_currentLanguageCode isEqualToString:languageCode] ||
            self->_localeMode != LocaleModeManual) {
            self->_localeMode = LocaleModeManual;
            self->_currentLanguageCode = [languageCode copy];
            self->_activeBundle = [self bundleForLanguageCode:languageCode];
            changed = YES;
        }
    });

    if (changed) {
        SLOGI(@"Language set to: %@", languageCode);
        [self postLanguageChangeNotification:languageCode];
    }
}

- (void)setLocaleProvider:(nullable id<LocaleProvider>)provider {
    __block BOOL changed = NO;
    dispatch_sync(self.localeQueue, ^{
        if (self->_localeProvider != provider) {
            self->_localeProvider = provider;
            changed = YES;
        }
    });

    if (changed) {
        NSString *code = self.currentLanguageCode;
        SLOGI(@"Provider %@", provider ? @"registered" : @"removed");
        [self postLanguageChangeNotification:code];
    }
}

- (void)resetToSystemLanguage {
    __block BOOL changed = NO;
    dispatch_sync(self.localeQueue, ^{
        NSString *newCode = [self resolveSystemLanguageCode];
        if (self->_localeMode != LocaleModeSystem ||
            ![self->_currentLanguageCode isEqualToString:newCode]) {
            self->_localeMode = LocaleModeSystem;
            self->_currentLanguageCode = newCode;
            self->_activeBundle = [self bundleForLanguageCode:newCode];
            changed = YES;
        }
    });

    if (changed) {
        NSString *code = self.currentLanguageCode;
        SLOGI(@"Reset to system language: %@", code);
        [self postLanguageChangeNotification:code];
    }
}

#pragma mark - String Lookup

- (NSString *)localizedStringForKey:(NSString *)key {
    if (!key.length) {
        return @"";
    }

    __block id<LocaleProvider> provider = nil;
    __block NSBundle *bundle = nil;

    dispatch_sync(self.localeQueue, ^{
        provider = self->_localeProvider;
        bundle = self->_activeBundle;
    });

    // 解析链步骤 1：Custom Provider
    if (provider && [provider respondsToSelector:@selector(localizedStringForKey:)]) {
        NSString *result = [provider localizedStringForKey:key];
        if (result) {
            return result;
        }
    }

    // 解析链步骤 2/3：Bundle 查询（Manual 或 System）
    if (bundle) {
        NSString *result = [bundle localizedStringForKey:key value:nil table:kLocaleTableName];
        if (result && ![result isEqualToString:key]) {
            return result;
        }
    }

    // 解析链步骤 4：SDK Bundle fallback（当 activeBundle 非 sdkBundle 时）
    if (bundle != self.sdkBundle && self.sdkBundle) {
        NSString *result = [self.sdkBundle localizedStringForKey:key value:nil table:kLocaleTableName];
        if (result && ![result isEqualToString:key]) {
            return result;
        }
    }

    // 最终 fallback：返回 key 本身
    return key;
}

#pragma mark - Private Methods

- (NSBundle *)loadSDKBundle {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"PlayerKit" ofType:@"bundle"];
    if (!bundlePath) {
        // CocoaPods framework 场景下查找
        NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
        bundlePath = [classBundle pathForResource:@"PlayerKit" ofType:@"bundle"];
    }
    if (bundlePath) {
        return [NSBundle bundleWithPath:bundlePath];
    }
    return [NSBundle mainBundle];
}

- (NSBundle *)bundleForLanguageCode:(NSString *)languageCode {
    if (!languageCode.length) {
        return self.sdkBundle;
    }

    NSString *lprojPath = [self.sdkBundle pathForResource:languageCode ofType:@"lproj"];
    if (lprojPath) {
        NSBundle *lprojBundle = [NSBundle bundleWithPath:lprojPath];
        if (lprojBundle) {
            return lprojBundle;
        }
    }

    // fallback 到默认语言
    if (![languageCode isEqualToString:kDefaultLanguageCode]) {
        NSString *defaultPath = [self.sdkBundle pathForResource:kDefaultLanguageCode ofType:@"lproj"];
        if (defaultPath) {
            NSBundle *defaultBundle = [NSBundle bundleWithPath:defaultPath];
            if (defaultBundle) {
                return defaultBundle;
            }
        }
    }

    return self.sdkBundle;
}

- (NSString *)resolveSystemLanguageCode {
    NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
    if (preferredLanguages.count == 0) {
        return kDefaultLanguageCode;
    }

    NSString *systemLang = preferredLanguages.firstObject;

    // 按长度降序排列，确保 "zh-Hans" 优先于 "zh" 匹配
    NSArray<NSString *> *supportedLanguages = [self supportedLanguageCodes];
    NSArray<NSString *> *sorted = [supportedLanguages sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [@(b.length) compare:@(a.length)];
    }];

    for (NSString *supported in sorted) {
        if ([systemLang hasPrefix:supported]) {
            return supported;
        }
    }

    // 未匹配到支持的语言，使用默认语言
    return kDefaultLanguageCode;
}

- (NSArray<NSString *> *)supportedLanguageCodes {
    static NSArray<NSString *> *codes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *lprojPaths = [self.sdkBundle pathsForResourcesOfType:@"lproj" inDirectory:nil];
        NSMutableArray<NSString *> *result = [NSMutableArray array];
        for (NSString *path in lprojPaths) {
            NSString *langCode = [[path lastPathComponent] stringByDeletingPathExtension];
            [result addObject:langCode];
        }
        if (result.count == 0) {
            [result addObject:kDefaultLanguageCode];
            [result addObject:@"en"];
        }
        codes = [result copy];
    });
    return codes;
}

- (void)postLanguageChangeNotification:(NSString *)languageCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:LocaleDidChangeNotification
                                                            object:self
                                                          userInfo:@{ LocaleLanguageCodeKey: languageCode ?: @"" }];
    });
}

@end
