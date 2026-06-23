# **多语言（Locale）**

**多语言 (Locale)** 是 AliPlayerKit 的国际化支撑模块。它通过统一的语言管理器，提供自动跟随系统语言、手动语言切换、自定义 Provider 注入等核心能力，使播放器 UI 文案能够灵活适配多语言场景。

---

## **1. 概念介绍**

### **1.1 什么是 Locale 模块？**

Locale 模块是 AliPlayerKit 的内置国际化方案，提供播放器所有 UI 文案（按钮文本、错误提示、设置项标题等）的本地化能力。它采用**解析链（Resolution Chain）**机制，按优先级逐级查找翻译：

```text
Custom Provider → 手动指定语言 Bundle → 跟随系统语言 Bundle → Key fallback
```

### **1.2 核心价值**

| 价值 | 说明 |
|------|------|
| 零配置可用 | 内置中/英两种语言，自动跟随系统语言，无需任何初始化 |
| 灵活切换 | 支持跟随系统和手动指定两种模式，满足不同业务需求 |
| 可扩展 | 通过 `LocaleProvider` 协议注入自定义翻译，优先级最高 |
| 实时通知 | 语言切换后通过 `NSNotification` 通知所有 UI 刷新 |

---

## **2. 功能特性**

### **2.1 默认行为（零配置）**

AliPlayerKit **开箱即用**，无需编写任何代码即可支持多语言：

- 内置简体中文和英文两种语言
- 播放器 UI 文案**自动跟随系统语言**切换，无需任何初始化或 API 调用
- 用户在系统「设置 → 通用 → 语言与地区」中切换语言后，播放器文案自动切换
- 如果系统语言不在内置支持范围内，自动回退到默认语言（简体中文）

### **2.2 内置语言**

| 语言 | 语言代码 | 资源目录 |
|------|---------|---------|
| 简体中文（默认） | `zh-Hans` | `PlayerKit.bundle/zh-Hans.lproj/Localizable.strings` |
| 英文 | `en` | `PlayerKit.bundle/en.lproj/Localizable.strings` |

> 对于大多数只需要中英文支持的应用，**无需调用任何 API，集成 AliPlayerKit 即可**。

### **2.3 语言模式**

| 模式 | 枚举值 | 说明 |
|------|--------|------|
| 跟随系统（默认） | `LocaleModeSystem` | 自动使用系统首选语言 |
| 手动指定 | `LocaleModeManual` | 使用开发者指定的语言代码 |

### **2.4 内置文案 Key 分类**

| 分类 | Key 前缀 | 示例 |
|------|---------|------|
| 播放状态 | `play_state.*` | 加载中、错误代码、截图完成 |
| 底部控制栏 | `bottom_bar.*` | 时间格式、倍速、清晰度 |
| 中心展示 | `center_display.*` | 倍速播放提示 |
| 设置菜单 | `setting_menu.*` / `setting.*` | 标题、各设置项 |
| 镜像模式 | `mirror.*` | 无、水平、垂直 |
| 缩放模式 | `scale.*` | 拉伸填充、适应、裁剪填充 |
| 日志面板 | `log_panel.*` | 展开/折叠标题、清除 |
| 通用 | `common.*` | 未知 |

---

## **3. 使用方式**

### **3.1 跟随系统语言（默认，无需代码）**

集成 AliPlayerKit 后，播放器文案自动根据系统语言显示对应翻译：

```objc
// 无需任何配置，播放器 UI 文案自动跟随系统语言
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
// 此时如系统为英文，所有 UI 文案自动显示英文
```

### **3.2 手动指定语言**

当需要在应用内提供语言切换入口、不跟随系统语言时：

```objc
// 强制切换到英文
[AliPlayerKit setLanguageCode:@"en"];

// 强制切换到简体中文
[AliPlayerKit setLanguageCode:@"zh-Hans"];
```

> 💡 调用 `setLanguageCode:` 后会发送 `LocaleDidChangeNotification` 通知，已绑定的插槽会自动刷新文案。

### **3.3 恢复跟随系统**

手动指定语言后，如需恢复为跟随系统：

```objc
// 清除手动设定，恢复跟随系统首选语言
[AliPlayerKit resetLocaleToSystemLanguage];
```

### **3.4 查询当前语言**

```objc
// 获取当前生效的语言代码
NSString *currentLang = [AliPlayerKit currentLanguageCode];
NSLog(@"当前语言: %@", currentLang); // 如 "zh-Hans" 或 "en"
```

### **3.5 监听语言变更**

通过 `NSNotification` 监听语言切换事件：

```objc
// 注册通知
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(localeDidChange:)
                                             name:LocaleDidChangeNotification
                                           object:nil];

// 处理语言变更
- (void)localeDidChange:(NSNotification *)notification {
    NSString *newLanguage = notification.userInfo[LocaleLanguageCodeKey];
    NSLog(@"语言已切换为: %@", newLanguage);
    // 刷新自定义 UI 文案
    [self refreshCustomUI];
}

// 不再需要时移除（iOS 9+ 可自动移除，建议仍显式移除）
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LocaleDidChangeNotification
                                                  object:nil];
}
```

---

## **4. 自定义开发**

### **4.1 注入自定义 Provider**

通过实现 `LocaleProvider` 协议，可以在不修改资源文件的情况下自定义任何翻译：

```objc
// 1. 定义自定义 Provider
@interface MyLocaleProvider : NSObject <LocaleProvider>
@end

@implementation MyLocaleProvider

- (nullable NSString *)localizedStringForKey:(NSString *)key {
    // 自定义特定 key 的翻译
    if ([key isEqualToString:LocaleKeyPlayStateLoading]) {
        return @"视频缓冲中，请稍候...";
    }
    if ([key isEqualToString:LocaleKeySettingSpeed]) {
        return @"播放倍率";
    }
    // 返回 nil 表示不处理此 key，由 SDK fallback 链继续解析
    return nil;
}

@end

// 2. 注入 Provider
MyLocaleProvider *provider = [[MyLocaleProvider alloc] init];
[AliPlayerKit setLocaleProvider:provider];
```

> 💡 Provider 以 **弱引用** 持有，需确保其生命周期不短于播放器。

### **4.2 新增语言支持**

当需要新增 AliPlayerKit 尚未内置的语言（如日语、韩语）时，通过自定义 Provider 实现全量翻译：

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
            // ... 全量翻译所有 LocaleKey
        };
    }
    return self;
}

- (nullable NSString *)localizedStringForKey:(NSString *)key {
    return self.translations[key];
}

@end

// 注入日语 Provider
JapaneseLocaleProvider *jaProvider = [[JapaneseLocaleProvider alloc] init];
[AliPlayerKit setLocaleProvider:jaProvider];
```

### **4.3 覆盖已有翻译**

仅需覆盖部分翻译时，Provider 只返回需要修改的 key，其余返回 nil 由 SDK 处理：

```objc
- (nullable NSString *)localizedStringForKey:(NSString *)key {
    // 仅覆盖"加载中"提示文案
    if ([key isEqualToString:LocaleKeyPlayStateLoading]) {
        return @"精彩即将呈现...";
    }
    return nil; // 其他 key 使用 SDK 内置翻译
}
```

### **4.4 移除自定义 Provider**

```objc
// 移除 Provider，恢复使用 SDK 内置翻译
[AliPlayerKit setLocaleProvider:nil];
```

---

## **5. 设计说明**

### **5.1 字符串解析链（Resolution Chain）**

`LocaleManager` 内部按以下优先级查找翻译：

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1（最高） | Custom Provider | 实现 `LocaleProvider` 协议的对象 |
| 2 | Manual Bundle | 手动指定语言对应的 `.lproj` |
| 3 | System Bundle | 跟随系统语言对应的 `.lproj` |
| 4（最低） | Key fallback | 直接返回 key 本身 |

### **5.2 线程安全**

| 操作 | 线程安全机制 |
|------|------------|
| 语言切换方法 | 可在任意线程调用 |
| 通知发送 | 始终在主线程发送 |
| Provider 访问 | 弱引用，无需加锁 |

### **5.3 通知机制**

| 通知名 | 触发时机 | userInfo |
|--------|---------|----------|
| `LocaleDidChangeNotification` | 语言模式或语言代码变化时 | `LocaleLanguageCodeKey` → 新语言代码 |

触发场景：
- 调用 `setLanguageCode:` 切换手动语言
- 调用 `resetLocaleToSystemLanguage` 恢复系统跟随
- 调用 `setLocaleProvider:` 注入/移除 Provider

---

## **6. API 速查**

### **6.1 AliPlayerKit 类方法**

| 方法 | 说明 |
|------|------|
| `+setLanguageCode:` | 手动指定语言代码（如 `@"en"`、`@"zh-Hans"`） |
| `+resetLocaleToSystemLanguage` | 恢复跟随系统语言 |
| `+setLocaleProvider:` | 注入/移除自定义翻译 Provider |
| `+currentLanguageCode` | 获取当前生效的语言代码 |

### **6.2 LocaleManager 实例方法**

| 方法/属性 | 说明 |
|----------|------|
| `+sharedManager` | 获取单例实例 |
| `currentLanguageCode` | 当前语言代码（只读） |
| `localeMode` | 当前语言模式（只读） |
| `localeProvider` | 当前注入的 Provider（只读，弱引用） |
| `-setLanguageCode:` | 设置手动语言代码 |
| `-setLocaleProvider:` | 注入自定义 Provider |
| `-resetToSystemLanguage` | 重置为跟随系统 |
| `-localizedStringForKey:` | 按解析链查询本地化字符串 |

### **6.3 LocaleProvider 协议**

| 方法 | 说明 |
|------|------|
| `-localizedStringForKey:` | 为指定 key 返回翻译，返回 nil 表示降级 |

### **6.4 SDK 内部使用的宏**

| 宏 | 用法 | 说明 |
|----|------|------|
| `LocalizedString(key)` | `LocalizedString(LocaleKeyPlayStateLoading)` | 获取本地化字符串 |
| `LocalizedFormat(key, ...)` | `LocalizedFormat(LocaleKeyBottomBarTimeFormat, min, sec, totalMin, totalSec)` | 获取格式化本地化字符串 |

### **6.5 相关文件**

| 文件 | 说明 |
|------|------|
| `PlayerKit/Source/Locale/LocaleManager.h` | 本地化管理器（单例） |
| `PlayerKit/Source/Locale/LocaleProvider.h` | 自定义翻译 Provider 协议 |
| `PlayerKit/Source/Locale/LocaleKeys.h` | 所有本地化 Key 常量定义 |
| `PlayerKit/Source/Locale/LocaleMacros.h` | SDK 内部使用的便捷宏 |
| `PlayerKit/Source/Locale/Localized.h` | 聚合头文件 |
| `PlayerKit/Source/AliPlayerKit.h` | 全局 API 入口（Locale 相关类方法） |
| `PlayerKit.bundle/zh-Hans.lproj/Localizable.strings` | 简体中文翻译文件 |
| `PlayerKit.bundle/en.lproj/Localizable.strings` | 英文翻译文件 |

> 完整 API 详见 [API 参考](../ApiReference.md)。

---

## **7. 最佳实践**

### **7.1 选择合适的方案**

| 场景 | 推荐方案 | 说明 |
|------|---------|------|
| 仅需中英文 | 无需任何操作 | 内置中英文，自动跟随系统语言 |
| 新增整套语言 | `LocaleProvider` 全量翻译 | 实现协议，返回所有 key 的翻译 |
| 覆盖部分文案 | `LocaleProvider` 部分翻译 | 仅处理需要覆盖的 key，其余返回 nil |
| 强制指定语言 | `setLanguageCode:` | 不跟随系统，由应用自行控制 |
| 运行时动态切换 | `setLanguageCode:` + 通知 | 切换后通过通知刷新自定义 UI |

### **7.2 注意事项**

| 事项 | 说明 |
|------|------|
| Provider 生命周期 | Provider 以弱引用持有，需确保其在播放器使用期间不被释放 |
| 全量翻译 | 新增语言时建议翻译所有 `LocaleKeys.h` 中的 key，避免混合语言显示 |
| 语言代码规范 | 使用 Apple 标准 lproj 命名（如 `zh-Hans`、`en`、`ja`） |
| 通知时机 | `LocaleDidChangeNotification` 始终在主线程发送，可安全更新 UI |
| 插槽自动刷新 | 内置插槽监听语言变更通知并自动刷新文案，自定义插槽需自行监听 |

---

## **8. 示例参考**

项目提供了完整的多语言示例，位于 `PlayerKitUsages/UsageLocaleSystem`。

### **8.1 示例功能**

| 功能 | 说明 |
|------|------|
| 语言切换 | 演示中/英两种语言的手动切换 |
| 自定义 Provider | 演示通过 Provider 覆盖内置翻译 |
| 变更监听 | 演示语言变更通知的注册与响应 |

### **8.2 运行示例**

在 Demo App 中选择「Locale System」示例查看效果。

---

## **9. 下一步**

- 了解场景类型对 UI 的影响 → [场景类型](SceneType.md)
- 了解全局与实例级配置 → [自定义配置](CustomConfig.md)
- 查看完整 API 文档 → [API 参考](../ApiReference.md)
