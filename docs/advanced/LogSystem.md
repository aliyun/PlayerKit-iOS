# **日志系统 (Log System)**

**日志系统 (Log System)** 是 AliPlayerKit 的基础支撑模块。它通过统一的日志中心 `LogHub`，提供日志输出、级别过滤、观察者机制等核心能力，实现播放器运行时信息的可视化与可追溯。

---

## **1. 概念介绍**

### **1.1 什么是 LogHub？**

**LogHub** 是 AliPlayerKit 中所有日志输出的统一入口，采用单例模式设计。它封装了 iOS 原生日志 API（`NSLog`），在保留原有功能的基础上，增加了以下核心能力：

| 能力 | 说明 |
|-----|------|
| 日志开关 | 控制日志输出是否启用（总开关） |
| 控制台开关 | 控制日志是否输出到 Xcode Console |
| 级别过滤 | 只输出指定级别及以上的日志 |
| 观察者机制 | 支持外部观察者接收日志输出，实现自定义处理（如写入文件） |

### **1.2 什么是日志观察者？**

**日志观察者 (LogObserver)** 是用于接收 `LogHub` 输出日志的回调协议。通过实现该协议，可以自定义日志的处理方式，例如：

- 将日志写入文件，便于问题排查时提供给技术支持团队
- 将日志上传到远程服务器，实现远程日志收集
- 在 UI 上展示日志，用于调试面板

### **1.3 混合线程模型**

`LogHub` 采用混合线程模型：

| 操作 | 线程 |
|------|------|
| 线程名和时间戳捕获 | 调用线程同步执行 |
| 控制台输出（NSLog） | 调用线程同步执行 |
| 观察者通知 | 后台串行队列异步分派 |

> **注意**：`LogObserver.onLog:` 回调在**后台串行队列**执行，如需更新 UI 请切换到主线程。

---

## **2. 功能特性**

### **2.1 核心能力**

| 能力 | 说明 |
|-----|------|
| 多级别日志 | 支持 Verbose、Debug、Info、Warn、Error 五个级别 |
| 三重控制 | 全局开关 + 级别过滤 + 控制台开关，精确控制输出范围 |
| 观察者机制 | 支持注册自定义观察者，实现日志持久化、远程上报等 |
| 便捷宏 | 提供 `SLOGV/D/I/W/E` 宏，自动捕获源码位置 |
| 日志面板 | 通过 `LogPanelSlot` 在播放器视图中实时展示日志（调试专用） |
| 全局快捷 API | 通过 `AliPlayerKit` 类方法快速配置日志级别和控制台输出 |

### **2.2 核心组件**

| 组件 | 类型 | 说明 |
|------|------|------|
| `LogHub` | 单例 | 日志中心，统一日志输出入口 |
| `LogLevel` | 枚举 | 日志级别定义 |
| `LogInfo` | 数据类 | 日志信息模型，封装单条日志的完整信息 |
| `LogObserver` | 协议 | 日志观察者接口 |
| `LogPanelSlot` | 插槽 | 播放器内嵌日志面板，实时展示关键日志 |

---

## **3. 使用方式**

### **3.1 基本用法 — 全局快捷配置**

通过 `AliPlayerKit` 类方法快速配置日志系统（推荐方式）：

```objc
// 在 AppDelegate 中，setup 之后配置
[AliPlayerKit setup];

// 设置日志级别
[AliPlayerKit setLogLevel:LogLevelVerbose];

// 启用/禁用控制台日志
[AliPlayerKit enableConsoleLog:YES];
```

| AliPlayerKit 方法 | 说明 |
|-------------------|------|
| `setLogLevel:` | 设置日志级别，低于该级别的日志被忽略（默认 `LogLevelInfo`） |
| `logLevel` | 获取当前日志级别 |
| `enableConsoleLog:` | 启用/禁用控制台输出（默认启用） |
| `isConsoleLogEnabled` | 查询控制台日志是否启用 |
| `setDebugModeEnabled:` | 开启/关闭调试模式 |
| `isDebugModeEnabled` | 查询调试模式是否开启 |
| `setLogPanelEnabled:` | 启用/禁用日志面板插槽（默认禁用） |
| `isLogPanelEnabled` | 查询日志面板是否启用 |

### **3.2 基本用法 — 输出日志**

使用 `SLOG` 系列便捷宏输出各级别日志，宏会自动捕获源文件名和行号：

```objc
#import <AliPlayerKit/LogMacros.h>

// 输出各级别日志（自动捕获 __FILE_NAME__ 和 __LINE__）
SLOGV(@"viewDidLoad called");
SLOGD(@"配置播放器: videoId=%@", videoId);
SLOGI(@"开始播放视频: %@", videoTitle);
SLOGW(@"缓冲中，当前进度: %.1f%%", progress * 100);
SLOGE(@"播放失败，错误码: %ld", (long)errorCode);
```

**便捷宏列表**：

| 宏 | 级别 | 说明 |
|----|------|------|
| `SLOGV(fmt, ...)` | Verbose | 最详细级别日志 |
| `SLOGD(fmt, ...)` | Debug | 调试信息 |
| `SLOGI(fmt, ...)` | Info | 一般信息 |
| `SLOGW(fmt, ...)` | Warn | 潜在问题 |
| `SLOGE(fmt, ...)` | Error | 错误信息 |

> **说明**：`SLOG` 宏内部调用 `LogHub` 的 `logLevel:file:line:message:error:` 方法，自动通过 `__FILE_NAME__` 和 `__LINE__` 捕获源码位置，无需手动传入 tag。

也可以直接调用 `LogHub` 实例方法，手动指定 tag：

```objc
// 使用 tag 标识日志来源
[[LogHub sharedHub] i:@"PlayerVC" msg:@"开始播放"];
[[LogHub sharedHub] e:@"MediaPlayer" msg:@"播放失败" error:error];
```

### **3.3 基本用法 — 配置日志级别**

通过 `LogHub` 直接配置日志属性：

```objc
LogHub *logHub = [LogHub sharedHub];

#ifdef DEBUG
    // 开发环境：详细日志 + 控制台输出
    logHub.logEnabled = YES;
    logHub.consoleLogEnabled = YES;
    logHub.logLevel = LogLevelVerbose;
#else
    // 生产环境：精简日志 + 关闭控制台
    logHub.logEnabled = YES;
    logHub.consoleLogEnabled = NO;
    logHub.logLevel = LogLevelInfo;
#endif
```

**三重控制机制**：

| 控制层 | 属性 | 说明 |
|--------|------|------|
| 总开关 | `logEnabled` | 关闭后所有日志静默（包括观察者通知） |
| 级别过滤 | `logLevel` | 低于该级别的日志被忽略（默认 `LogLevelInfo`） |
| 控制台开关 | `consoleLogEnabled` | 控制是否通过 NSLog 输出到 Xcode Console |

> **说明**：关闭 `consoleLogEnabled` 后，日志仍会通过观察者通知分发，仅抑制控制台输出。关闭 `logEnabled` 后，所有日志请求被完全忽略，观察者也不会收到通知。

### **3.4 高级用法 — 注册日志观察者**

通过实现 `LogObserver` 协议自定义日志处理：

```objc
// 创建并注册文件日志观察者
FileLogObserver *fileObserver = [[FileLogObserver alloc] init];
[[LogHub sharedHub] addObserver:fileObserver];

// 移除观察者（不再需要时）
[[LogHub sharedHub] removeObserver:fileObserver];
```

> **注意**：`LogHub` 以**弱引用**方式持有观察者（底层基于 `NSHashTable weakObjectsHashTable`），观察者销毁后会自动从列表中移除，不会造成循环引用。但仍建议在合适的时机（如 `viewWillDisappear:`）主动调用 `removeObserver:`，避免在对象即将销毁前的窗口期内继续收到日志回调。

### **3.5 高级用法 — 日志面板**

`LogPanelSlot` 是一个内置的调试插槽，可在播放器视图中实时展示关键日志信息：

```objc
// 启用日志面板（建议仅在调试场景中启用）
[AliPlayerKit setLogPanelEnabled:YES];
```

| 交互 | 说明 |
|------|------|
| 点击标题栏 | 展开/折叠日志内容区 |
| 点击"清除"按钮 | 清空已展示的日志 |
| 长按日志区域 | 将日志内容拷贝到剪贴板 |

> **说明**：日志面板仅显示 Debug 及以上级别的日志。需要在 `rebuildSlots` 之前设置 `setLogPanelEnabled:`。在 Minimal 场景中不可见。

---

## **4. 自定义开发**

### **4.1 日志观察者协议 (LogObserver)**

```objc
@protocol LogObserver <NSObject>

@required

/// 日志输出回调
/// @param logInfo 日志信息对象，包含级别、标签、消息和时间戳
/// @warning 回调在后台串行队列执行，如需更新 UI 请 dispatch 到主线程
- (void)onLog:(LogInfo *)logInfo;

@end
```

### **4.2 LogInfo 数据模型**

| 属性 | 类型 | 说明 |
|------|------|------|
| `level` | `LogLevel` | 日志级别（readonly） |
| `tag` | `NSString *` | 日志标签（readonly） |
| `message` | `NSString *` | 日志消息内容（readonly） |
| `timestamp` | `NSDate *` | 日志生成时间戳（readonly） |
| `threadName` | `NSString *` | 生成日志的线程名称（readonly） |
| `fileName` | `NSString *` | 源文件名，如 `@"MyClass.m"`（readonly） |
| `line` | `NSInteger` | 源代码行号（readonly） |
| `error` | `NSError *` | 关联的错误对象，可为 nil（readonly） |

| 方法 | 说明 |
|------|------|
| `formattedString` | 获取格式化的日志字符串 |
| `initWithLevel:fileName:line:message:error:threadName:timestamp:` | 指定初始化方法 |
| `initWithLevel:tag:message:` | 便捷初始化方法（自动捕获时间戳和线程名） |

**格式化输出格式**：

```text
2024-04-22 10:30:00.123 I/AliPlayerKit [version] [FileName:line] [threadName] : message
```

如果存在错误，将附加额外一行：

```text
Error: domain=xxx code=xxx userInfo=xxx
```

### **4.3 自定义文件日志观察者示例**

以下是一个文件日志观察者的完整实现：

```objc
@interface MyFileLogObserver : NSObject <LogObserver>
- (instancetype)initWithLogDirectory:(NSString *)directory;
@end

@implementation MyFileLogObserver {
    NSString *_logFilePath;
    dispatch_queue_t _writeQueue;
    NSFileHandle *_fileHandle;
}

- (instancetype)initWithLogDirectory:(NSString *)directory {
    self = [super init];
    if (self) {
        _writeQueue = dispatch_queue_create("com.example.filelog",
                                            DISPATCH_QUEUE_SERIAL);
        [self setupLogFileAtDirectory:directory];
    }
    return self;
}

- (void)setupLogFileAtDirectory:(NSString *)directory {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:directory]) {
        [fm createDirectoryAtPath:directory
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *fileName = [NSString stringWithFormat:@"player_%@.log",
                          [formatter stringFromDate:[NSDate date]]];
    _logFilePath = [directory stringByAppendingPathComponent:fileName];

    if (![fm fileExistsAtPath:_logFilePath]) {
        [fm createFileAtPath:_logFilePath contents:nil attributes:nil];
    }
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
    [_fileHandle seekToEndOfFile];
}

#pragma mark - LogObserver

- (void)onLog:(LogInfo *)logInfo {
    NSString *formatted = [logInfo formattedString];

    dispatch_async(_writeQueue, ^{
        NSString *line = [formatted stringByAppendingString:@"\n"];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        @try {
            [self->_fileHandle writeData:data];
        } @catch (NSException *exception) {
            // 忽略写入异常
        }
    });
}

- (void)dealloc {
    [_fileHandle closeFile];
}

@end
```

> **说明**：`onLog:` 回调已在后台串行队列执行，但文件 I/O 仍建议使用独立的写入队列，避免阻塞日志分发队列影响其他观察者。

### **4.4 完整集成示例**

```objc
// AppDelegate.m
#import <AliPlayerKit/AliPlayerKit.h>

@interface AppDelegate ()
@property (nonatomic, strong) MyFileLogObserver *fileLogObserver;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 初始化 AliPlayerKit
    [AliPlayerKit setup];

    // 2. 配置日志系统
#ifdef DEBUG
    [AliPlayerKit setLogLevel:LogLevelVerbose];
    [AliPlayerKit enableConsoleLog:YES];
    // 可选：启用日志面板
    [AliPlayerKit setLogPanelEnabled:YES];
#else
    [AliPlayerKit setLogLevel:LogLevelInfo];
    [AliPlayerKit enableConsoleLog:NO];

    // 3. 注册文件日志观察者（仅生产环境）
    NSString *logDir = [NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject
        stringByAppendingPathComponent:@"PlayerLogs"];
    self.fileLogObserver = [[MyFileLogObserver alloc] initWithLogDirectory:logDir];
    [[LogHub sharedHub] addObserver:self.fileLogObserver];
#endif

    return YES;
}

@end
```

> **参考**：`PlayerKitUsages/UsageLogSystem` 模块提供了完整的日志系统使用示例，包含 `FileLogObserver` 文件日志观察者和 UI 日志展示。

---

## **5. 最佳实践**

### **5.1 环境配置建议**

| 环境 | 总开关 | 控制台 | 级别 | 观察者 | 日志面板 |
|------|--------|--------|------|--------|---------|
| 开发调试 | YES | YES | Verbose | 可选（UI 面板） | 可选 |
| 内部测试 | YES | YES | Debug | 文件日志 | NO |
| 生产环境 | YES | NO | Info | 文件日志 + 远程上报 | NO |
| 敏感场景 | NO | — | — | — | NO |

### **5.2 常见错误**

#### **错误 1：观察者回调中直接更新 UI**

```objc
// ✗ 错误：onLog: 在后台串行队列执行，直接更新 UI 会崩溃
- (void)onLog:(LogInfo *)logInfo {
    self.logLabel.text = [logInfo formattedString];  // 崩溃！
}

// ✓ 正确：切换到主线程更新 UI
- (void)onLog:(LogInfo *)logInfo {
    NSString *formatted = [logInfo formattedString];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logLabel.text = formatted;
    });
}
```

#### **错误 2：观察者中同步阻塞操作**

```objc
// ✗ 错误：在回调中同步写文件，阻塞日志分发队列
- (void)onLog:(LogInfo *)logInfo {
    NSString *log = [logInfo formattedString];
    [log writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// ✓ 正确：异步写入文件
- (void)onLog:(LogInfo *)logInfo {
    NSString *log = [logInfo formattedString];
    dispatch_async(_writeQueue, ^{
        // 异步写入...
    });
}
```

#### **建议：及时移除观察者，避免收到无意义回调**

```objc
// LogHub 弱引用观察者，不移除不会造成循环引用，但可能在页面消失后仍收到日志回调
- (void)viewDidLoad {
    [[LogHub sharedHub] addObserver:self];
}

// ✓ 推荐：在生命周期结束时主动移除
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[LogHub sharedHub] removeObserver:self];
}
```

> **说明**：与通知系统的 Dispatcher 类似，`LogHub` 以**弱引用**方式持有观察者，因此不会造成内存泄漏；调用 `removeObserver:` 主要是为了避免在观察者生命周期结束后继续收到无意义的日志回调。

---

## **6. API 速查**

### **6.1 日志级别 (LogLevel)**

| 级别 | 枚举值 | 数值 | 说明 |
|-----|--------|------|------|
| Verbose | `LogLevelVerbose` | 0 | 最详细，开发调试 |
| Debug | `LogLevelDebug` | 1 | 调试信息 |
| Info | `LogLevelInfo` | 2 | **默认级别**，生产推荐 |
| Warn | `LogLevelWarn` | 3 | 潜在问题 |
| Error | `LogLevelError` | 4 | 错误信息 |
| None | `LogLevelNone` | 100 | 禁用所有日志 |

> **说明**：`LogLevel.h` 同时提供了 `LogLevelToString()` 内联函数，将级别转为缩写字符串（V/D/I/W/E/N）。

### **6.2 LogHub 核心 API**

| 属性 / 方法 | 类型 | 说明 |
|-------------|------|------|
| `+sharedHub` | 类方法 | 获取单例 |
| `logEnabled` | `BOOL` | 日志总开关（默认 YES） |
| `logLevel` | `LogLevel` | 日志级别（默认 `LogLevelInfo`） |
| `consoleLogEnabled` | `BOOL` | 控制台开关（默认 YES） |
| `v:msg:` | 实例方法 | 输出 Verbose 日志 |
| `d:msg:` | 实例方法 | 输出 Debug 日志 |
| `i:msg:` | 实例方法 | 输出 Info 日志 |
| `w:msg:` | 实例方法 | 输出 Warn 日志 |
| `e:msg:` | 实例方法 | 输出 Error 日志 |
| `e:msg:error:` | 实例方法 | 输出 Error 日志，附带 `NSError` |
| `log:tag:msg:` | 实例方法 | 按指定级别输出 |
| `logLevel:file:line:message:error:` | 实例方法 | 核心日志方法（供 SLOG 宏使用） |
| `addObserver:` | 实例方法 | 添加观察者（**弱引用**，重复添加无效果） |
| `removeObserver:` | 实例方法 | 移除观察者 |
| `+levelToString:` | 类方法 | 级别转字符串（V/D/I/W/E/N） |
| `+stringToLevel:` | 类方法 | 字符串转级别（不区分大小写，无法识别时返回 `LogLevelInfo`） |

### **6.3 AliPlayerKit 日志快捷 API**

| 方法 | 说明 |
|------|------|
| `+setLogLevel:` | 设置日志级别（需在 `setup` 之后调用） |
| `+logLevel` | 获取当前日志级别 |
| `+enableConsoleLog:` | 启用/禁用控制台日志输出 |
| `+isConsoleLogEnabled` | 查询控制台日志是否启用 |
| `+setDebugModeEnabled:` | 开启/关闭调试模式 |
| `+isDebugModeEnabled` | 查询调试模式是否开启 |
| `+setLogPanelEnabled:` | 启用/禁用日志面板插槽 |
| `+isLogPanelEnabled` | 查询日志面板是否启用 |

### **6.4 SLOG 便捷宏**

| 宏 | 级别 | 展开形式 |
|----|------|---------|
| `SLOGV(fmt, ...)` | Verbose | `[[LogHub sharedHub] logLevel:LogLevelVerbose file:@(__FILE_NAME__) line:__LINE__ message:... error:nil]` |
| `SLOGD(fmt, ...)` | Debug | 同上，级别为 Debug |
| `SLOGI(fmt, ...)` | Info | 同上，级别为 Info |
| `SLOGW(fmt, ...)` | Warn | 同上，级别为 Warn |
| `SLOGE(fmt, ...)` | Error | 同上，级别为 Error |

### **6.5 LogInfo 属性**

| 属性 | 类型 | 说明 |
|------|------|------|
| `level` | `LogLevel` | 日志级别 |
| `tag` | `NSString *` | 日志标签 |
| `message` | `NSString *` | 日志消息内容 |
| `timestamp` | `NSDate *` | 日志生成时间戳 |
| `threadName` | `NSString *` | 线程名称 |
| `fileName` | `NSString *` | 源文件名 |
| `line` | `NSInteger` | 源代码行号 |
| `error` | `NSError *` | 关联的错误对象（nullable） |
| `formattedString` | 方法 | 获取格式化的日志字符串 |

### **6.6 LogObserver 协议**

| 方法 | 必选 | 说明 |
|------|------|------|
| `onLog:` | 是（`@required`） | 日志输出回调，在后台串行队列执行 |
