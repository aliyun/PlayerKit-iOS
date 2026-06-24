# **Localization System (Locale)**

The **Localization System (Locale)** is the internationalization support module of AliPlayerKit. Through a unified language manager `LocaleManager`, it provides core capabilities such as automatic system language tracking, manual language switching, and custom Provider injection, enabling player UI text to flexibly adapt to multilingual scenarios.

---

## **1. Concepts**

### **1.1 What is LocaleManager?**

`LocaleManager` is the built-in internationalization management singleton of AliPlayerKit, responsible for localized lookup of all player UI text (button labels, error messages, settings titles, etc.). It employs a **Resolution Chain** mechanism that searches for translations level by level in priority order:

```text
Custom Provider → activeBundle（手动/系统） → sdkBundle fallback → Key 本身
```

### **1.2 Core Value**

| Value | Description |
|-------|-------------|
| Zero-configuration | Built-in Chinese/English languages, automatically follows system language, no initialization required |
| Flexible switching | Supports both system-following and manual modes to meet different business needs |
| Extensible | Inject custom translations via the `LocaleProvider` protocol with highest priority |
| Real-time notifications | Notifies all UI to refresh via `LocaleDidChangeNotification` after language switch |

### **1.3 Language Modes**

| Mode | Enum Value | Description |
|------|------------|-------------|
| Follow System (default) | `LocaleModeSystem` | Automatically uses the system preferred language |
| Manual | `LocaleModeManual` | Uses the language code specified by the developer |

---

## **2. Features**

### **2.1 Default Behavior (Zero Configuration)**

AliPlayerKit works **out of the box** with multilingual support without writing any code:

- Built-in Simplified Chinese and English languages
- Player UI text **automatically follows system language** switching, no initialization or API calls required
- When the user switches language in system "Settings → General → Language & Region", player text switches automatically
- If the system language is not within the built-in supported range, it automatically falls back to the default language (Simplified Chinese)

### **2.2 Built-in Languages**

| Language | Language Code | Resource Directory |
|----------|--------------|-------------------|
| Simplified Chinese (default) | `zh-Hans` | `PlayerKit.bundle/zh-Hans.lproj/Localizable.strings` |
| English | `en` | `PlayerKit.bundle/en.lproj/Localizable.strings` |

> For most applications that only need Chinese and English support, **no API calls are needed — just integrate AliPlayerKit**.

### **2.3 Built-in Text Key Categories**

| Category | Key Constant Prefix | Example Keys |
|----------|-------------------|--------------|
| Playback State | `LocaleKeyPlayState*` | `LocaleKeyPlayStateLoading`, `LocaleKeyPlayStateErrorCodeLabel` |
| Bottom Control Bar | `LocaleKeyBottomBar*` | `LocaleKeyBottomBarSpeed`, `LocaleKeyBottomBarQuality` |
| Speed Hint | `LocaleKeySpeedPlayingHint` | Speed playback hint text |
| Settings Menu | `LocaleKeySetting*` | `LocaleKeySettingMenuTitle`, `LocaleKeySettingSpeed` |
| Mirror Mode | `LocaleKeyMirror*` | `LocaleKeyMirrorNone`, `LocaleKeyMirrorHorizontal` |
| Scale Mode | `LocaleKeyScale*` | `LocaleKeyScaleFitXY`, `LocaleKeyScaleCenterCrop` |
| Log Panel | `LocaleKeyLogPanel*` | `LocaleKeyLogPanelTitleHide`, `LocaleKeyLogPanelClear` |
| Landscape Hint | `LocaleKeyLandscapeHint*` | `LocaleKeyLandscapeHintFullscreen` |
| General | `LocaleKeyUnknown` | General "unknown" text |

> **Note**: All Key constants are defined in `LocaleKeys.h`, using typed constants to ensure compile-time checking and IDE auto-completion.

---

## **3. Usage**

### **3.1 Follow System Language (Default, No Code Required)**

After integrating AliPlayerKit, player text automatically displays the corresponding translation based on system language:

```objc
// No configuration needed, player UI text automatically follows system language
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
// If the system is set to English, all UI text automatically displays in English
```

### **3.2 Manually Specify Language**

When you need to provide a language switching entry within the app without following the system language:

```objc
// Force switch to English
[AliPlayerKit setLanguageCode:@"en"];

// Force switch to Simplified Chinese
[AliPlayerKit setLanguageCode:@"zh-Hans"];
```

> After calling `setLanguageCode:`, `localeMode` automatically switches to `LocaleModeManual` and sends `LocaleDidChangeNotification`. Bound slots will automatically refresh their text.

### **3.3 Restore System Following**

After manually specifying a language, to restore system following:

```objc
// Clear manual setting, localeMode restores to LocaleModeSystem
[AliPlayerKit resetLocaleToSystemLanguage];
```

### **3.4 Query Current Language**

```objc
// Get the currently active language code
NSString *currentLang = [AliPlayerKit currentLanguageCode];
NSLog(@"Current language: %@", currentLang); // e.g. "zh-Hans" or "en"
```

### **3.5 Listen for Language Changes**

Listen for language switch events via `NSNotification`:

```objc
// Register notification
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(localeDidChange:)
                                             name:LocaleDidChangeNotification
                                           object:nil];

// Handle language change
- (void)localeDidChange:(NSNotification *)notification {
    NSString *newLanguage = notification.userInfo[LocaleLanguageCodeKey];
    NSLog(@"Language switched to: %@", newLanguage);
    // Refresh custom UI text
    [self refreshCustomUI];
}

// Remove when no longer needed
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
}
```

---

## **4. Custom Development**

### **4.1 LocaleProvider Protocol**

`LocaleProvider` defines the injection interface for custom translations:

```objc
@protocol LocaleProvider <NSObject>

@optional

/// Returns a localized string for the specified key.
/// Returning nil means this key is not handled, and the SDK internal fallback continues resolution.
- (nullable NSString *)localizedStringForKey:(NSString *)key;

@end
```

> **Note**: `localizedStringForKey:` is an `@optional` method. `LocaleManager` checks via `respondsToSelector:` before calling.

### **4.2 Inject Custom Provider**

By implementing the `LocaleProvider` protocol, you can customize any translation without modifying resource files:

```objc
// 1. Define a custom Provider
@interface MyLocaleProvider : NSObject <LocaleProvider>
@end

@implementation MyLocaleProvider

- (nullable NSString *)localizedStringForKey:(NSString *)key {
    // Customize translation for specific keys
    if ([key isEqualToString:LocaleKeyPlayStateLoading]) {
        return @"视频缓冲中，请稍候...";
    }
    if ([key isEqualToString:LocaleKeySettingSpeed]) {
        return @"播放倍率";
    }
    // Return nil to skip this key, letting the SDK fallback chain continue resolution
    return nil;
}

@end

// 2. Inject the Provider
MyLocaleProvider *provider = [[MyLocaleProvider alloc] init];
[AliPlayerKit setLocaleProvider:provider];
```

> **Note**: `LocaleManager` holds the Provider as a **weak reference**. The caller must maintain the Provider instance's lifecycle.

### **4.3 Add New Language Support**

When you need to add a language not yet built into AliPlayerKit (e.g., Japanese), implement full translations via a custom Provider:

```objc
@interface JapaneseLocaleProvider : NSObject <LocaleProvider>
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *translations;
@end

@implementation JapaneseLocaleProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        _translations = @{
            LocaleKeyPlayStateLoading: @"読み込み中...",
            LocaleKeyPlayStateErrorCodeLabel: @"エラーコード",
            LocaleKeyPlayStateErrorMessageLabel: @"エラーメッセージ",
            LocaleKeyBottomBarSpeed: @"速度",
            LocaleKeyBottomBarQuality: @"画質",
            LocaleKeySettingMenuTitle: @"設定",
            LocaleKeySettingSpeed: @"再生速度",
            LocaleKeySettingLoop: @"ループ再生",
            LocaleKeySettingMute: @"ミュート",
            LocaleKeySettingQuality: @"画質",
            // ... Provide full translations for all keys in LocaleKeys.h
        };
    }
    return self;
}

- (nullable NSString *)localizedStringForKey:(NSString *)key {
    return self.translations[key];
}

@end

// Inject Japanese Provider (you must retain the instance yourself)
self.jaProvider = [[JapaneseLocaleProvider alloc] init];
[AliPlayerKit setLocaleProvider:self.jaProvider];
```

### **4.4 Override Existing Translations**

When you only need to override some translations, the Provider returns only the keys that need modification, returning nil for the rest to let the SDK handle them:

```objc
- (nullable NSString *)localizedStringForKey:(NSString *)key {
    // Only override the "loading" hint text
    if ([key isEqualToString:LocaleKeyPlayStateLoading]) {
        return @"精彩即将呈现...";
    }
    return nil; // Other keys use SDK built-in translations
}
```

### **4.5 Remove Custom Provider**

```objc
// Remove Provider, restore to SDK built-in translations
[AliPlayerKit setLocaleProvider:nil];
```

---

## **5. Design Notes**

### **5.1 String Resolution Chain**

`LocaleManager` internally searches for translations in the following priority order:

| Priority | Source | Description |
|----------|--------|-------------|
| 1 (Highest) | Custom Provider | Object implementing `LocaleProvider` protocol, called after `respondsToSelector:` check |
| 2 | activeBundle | Currently active language Bundle (manually specified language in Manual mode, system language in System mode) |
| 3 | sdkBundle fallback | Falls back to SDK Bundle query when activeBundle differs from sdkBundle |
| 4 (Lowest) | Key fallback | Returns the key itself directly |

### **5.2 Thread Safety**

`LocaleManager` internally uses a serial queue (`dispatch_queue_t`) to protect all state reads and writes:

| Operation | Thread Safety Mechanism |
|-----------|----------------------|
| Property reads (`currentLanguageCode`, `localeMode`) | `dispatch_sync` serial queue |
| Language switch methods (`setLanguageCode:`, etc.) | `dispatch_sync` serial queue |
| Notification sending | `dispatch_async(dispatch_get_main_queue(), ...)` always on main thread |
| Provider retention | Weak reference (`weak`) |

### **5.3 Notification Mechanism**

| Notification Name | Trigger Timing | userInfo |
|-------------------|---------------|----------|
| `LocaleDidChangeNotification` | When language mode or language code changes | `LocaleLanguageCodeKey` → new language code |

Trigger scenarios:
- Calling `setLanguageCode:` to switch manual language
- Calling `resetLocaleToSystemLanguage` to restore system following
- Calling `setLocaleProvider:` to inject/remove Provider

---

## **6. API Quick Reference**

### **6.1 AliPlayerKit Class Methods**

| Method | Description |
|--------|-------------|
| `+setLanguageCode:` | Manually specify language code (e.g., `@"en"`, `@"zh-Hans"`), `localeMode` switches to `LocaleModeManual` |
| `+resetLocaleToSystemLanguage` | Restore to follow system language, `localeMode` switches to `LocaleModeSystem` |
| `+setLocaleProvider:` | Inject/remove custom translation Provider (held as weak reference), pass `nil` to remove |
| `+currentLanguageCode` | Get the currently active language code |

### **6.2 LocaleManager Instance Methods**

| Method/Property | Description |
|-----------------|-------------|
| `+sharedManager` | Get singleton instance |
| `currentLanguageCode` | Current language code (`readonly`) |
| `localeMode` | Current language mode (`readonly`, `LocaleModeSystem` / `LocaleModeManual`) |
| `localeProvider` | Currently injected Provider (`readonly`, weak reference) |
| `-setLanguageCode:` | Set manual language code |
| `-setLocaleProvider:` | Inject custom Provider |
| `-resetToSystemLanguage` | Reset to follow system |
| `-localizedStringForKey:` | Query localized string via resolution chain |

### **6.3 LocaleProvider Protocol**

| Method | Required | Description |
|--------|----------|-------------|
| `-localizedStringForKey:` | `@optional` | Returns translation for specified key, returning nil falls back to SDK built-in translation |

### **6.4 Macros Used Internally by the SDK**

| Macro | Usage | Description |
|-------|-------|-------------|
| `LocalizedString(key)` | `LocalizedString(LocaleKeyPlayStateLoading)` | Get localized string |
| `LocalizedFormat(key, ...)` | `LocalizedFormat(LocaleKeyBottomBarTimeFormat, min, sec, totalMin, totalSec)` | Get formatted localized string |

### **6.5 Notification Constants**

| Constant | Type | Description |
|----------|------|-------------|
| `LocaleDidChangeNotification` | `NSNotificationName` | Language change notification name |
| `LocaleLanguageCodeKey` | `NSString *` | New language code key in notification userInfo |

### **6.6 Related Files**

| File | Description |
|------|-------------|
| `PlayerKit/Source/Locale/LocaleManager.h` | Localization manager (singleton) |
| `PlayerKit/Source/Locale/LocaleProvider.h` | Custom translation Provider protocol |
| `PlayerKit/Source/Locale/LocaleKeys.h` | All localization Key constant definitions |
| `PlayerKit/Source/Locale/LocaleMacros.h` | Convenience macros used internally by the SDK |
| `PlayerKit/Source/Locale/Localized.h` | Aggregate header file |
| `PlayerKit/Source/AliPlayerKit.h` | Global API entry point (Locale-related class methods) |
| `PlayerKit.bundle/zh-Hans.lproj/Localizable.strings` | Simplified Chinese translation file |
| `PlayerKit.bundle/en.lproj/Localizable.strings` | English translation file |

> For the complete API, see [API Reference](../ApiReference-EN.md).

---

## **7. Best Practices**

### **7.1 Choose the Right Approach**

| Scenario | Recommended Approach | Description |
|----------|---------------------|-------------|
| Only need Chinese/English | No action required | Built-in Chinese/English, automatically follows system language |
| Add a complete new language | Full translation via `LocaleProvider` | Implement protocol, return translations for all keys |
| Override partial text | Partial translation via `LocaleProvider` | Only handle keys that need overriding, return nil for others |
| Force specific language | `setLanguageCode:` | Does not follow system, controlled by the app |
| Dynamic runtime switching | `setLanguageCode:` + notification | Refresh custom UI via notification after switching |

### **7.2 Important Notes**

| Item | Description |
|------|-------------|
| Provider lifecycle | Provider is held as a weak reference; the caller must ensure the Provider instance is not deallocated |
| Full translation | When adding a new language, translate all keys in `LocaleKeys.h` to avoid mixed-language display |
| Language code conventions | Use Apple standard lproj naming (e.g., `zh-Hans`, `en`, `ja`) |
| Notification thread | `LocaleDidChangeNotification` is always sent on the main thread, safe to update UI |
| Slot auto-refresh | Built-in slots listen for language change notifications and auto-refresh text; custom slots need to listen manually |

---

## **8. Example Reference**

> **Reference**: The `PlayerKitUsages/UsageLocaleSystem` module provides a complete usage example of the localization system, including language switching, custom Provider injection, and change notification listening.
