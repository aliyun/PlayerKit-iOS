# **日志系统 (Log System)**

**日志系统 (Log System)** 是 AliPlayerKit 的基础支撑模块。它通过统一的日志中心 `LogHub`，提供日志输出、级别控制、监听器机制等核心能力，实现播放器运行时信息的可视化与可追溯。

---

## **1. 概念介绍**

### **1.1 什么是 LogHub？**

**LogHub** 是 AliPlayerKit 框架中所有日志输出的统一入口，采用单例模式设计。它封装了 iOS 原生日志 API（`os_log` / `NSLog`），在保留原有功能的基础上，增加了以下核心能力：

| 能力 | 说明 |
|-----|------|
| 日志开关 | 控制日志输出是否启用（总开关） |
| 控制台开关 | 控制日志是否输出到 Xcode Console |
| 级别过滤 | 只输出指定级别及以上的日志 |
| 监听器机制 | 支持外部监听日志输出，实现自定义处理（如写入文件） |

### **1.2 什么是日志监听器？**

**日志监听器 (LogListener)** 是用于接收 LogHub 输出日志的回调协议。通过实现该协议，可以自定义日志的处理方式，例如：

- 将日志写入文件，便于问题排查时提供给技术支持团队
- 将日志上传到远程服务器，实现远程日志收集
- 在 UI 上展示日志，用于调试面板

---

## **2. 功能特性**

### **2.1 核心能力**

| 能力 | 说明 |
|-----|------|
| 多级别日志 | 支持 Verbose、Debug、Info、Warning、Error 五个级别 |
| 三重控制 | 全局开关 + 级别过滤 + 控制台开关，精确控制输出范围 |
| 监听器机制 | 支持注册自定义监听器，实现日志持久化、远程上报等 |
| 便捷宏 | 提供 `APKLogV/D/I/W/E` 宏简化日志调用 |
| 性能日志 | 提供性能时间日志输出，便于性能分析 |
| SDK 日志集成 | 通过 `AliPlayerLoggerProtocol` 统一管理播放器 SDK 日志 |

### **2.2 内置组件**

| 组件 | 类型 | 说明 |
|------|------|------|
| `LogHub` | 单例 | 日志中心，统一日志输出入口 |
| `AliPlayerLogLevel` | 枚举 | 日志级别定义 |
| `AliPlayerLogInfo` | 数据类 | 日志信息模型，封装单条日志完整信息 |
| `AliPlayerLogListenerProtocol` | 协议 | 日志监听器接口 |
| `AliPlayerLoggerProtocol` | 协议 | 播放器 SDK 日志接口 |
| `AliPlayerDefaultLogger` | 实现类 | 默认播放器日志实现 |

---

## **3. 使用方式**

### **3.1 基本用法 — 输出日志**

使用便捷宏输出各级别日志：

```objc
#import <AliPlayerKit/LogHub.h>

// 输出各级别日志
APKLogV(@"PlayerVC", @"viewDidLoad");
APKLogD(@"PlayerVC", @"配置播放器: videoId=%@", videoId);
APKLogI(@"PlayerVC", @"开始播放视频: %@", videoTitle);
APKLogW(@"PlayerVC", @"缓冲中，当前进度: %.1f%%", progress * 100);
APKLogE(@"PlayerVC", @"播放失败，错误码: %ld", (long)errorCode);

// 性能时间日志
NSTimeInterval startTime = CACurrentMediaTime();
// ... 耗时操作 ...
NSTimeInterval costTime = (CACurrentMediaTime() - startTime) * 1000;
APKLogT(@"loadVideoSource", costTime);
```

**便捷宏列表**：

| 宏 | 级别 | 说明 |
|----|------|------|
| `APKLogV(tag, fmt, ...)` | Verbose | 最详细级别日志 |
| `APKLogD(tag, fmt, ...)` | Debug | 调试信息 |
| `APKLogI(tag, fmt, ...)` | Info | 一般信息（默认级别） |
| `APKLogW(tag, fmt, ...)` | Warning | 潜在问题 |
| `APKLogE(tag, fmt, ...)` | Error | 错误信息 |
| `APKLogT(method, costTime)` | — | 性能时间日志 |

### **3.2 基本用法 — 配置日志级别**

根据运行环境配置不同的日志级别：

```objc
// 在 AppDelegate 中配置
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [AliPlayerKit setup];

    // 配置日志系统
    LogHub *logHub = [LogHub sharedHub];

#ifdef DEBUG
    // 开发环境：详细日志 + 控制台输出
    logHub.enableLog = YES;
    logHub.enableConsoleOutput = YES;
    logHub.logLevel = AliPlayerLogLevelVerbose;
#else
    // 生产环境：精简日志 + 关闭控制台
    logHub.enableLog = YES;
    logHub.enableConsoleOutput = NO;
    logHub.logLevel = AliPlayerLogLevelInfo;
#endif

    return YES;
}
```

**三重控制机制**：

| 控制层 | 属性 | 说明 |
|--------|------|------|
| 总开关 | `enableLog` | 关闭后所有日志静默（包括监听器） |
| 级别过滤 | `logLevel` | 低于该级别的日志被忽略 |
| 控制台开关 | `enableConsoleOutput` | 控制是否输出到 Xcode Console |

### **3.3 高级用法 — 注册日志监听器**

通过实现 `AliPlayerLogListenerProtocol` 协议自定义日志处理：

```objc
// 创建并注册文件日志监听器
APKFileLogListener *fileListener =
    [[APKFileLogListener alloc] initWithLogDirectory:logDir];
[[LogHub sharedHub] addListener:fileListener];

// 移除监听器（不再需要时）
[[LogHub sharedHub] removeListener:fileListener];
```

> **注意**：`LogHub` 使用 `NSHashTable weakObjectsHashTable` 弱引用持有监听器，对象释放后自动移除。但建议在 `dealloc` 中主动调用 `removeListener:` 确保及时清理。

### **3.4 高级用法 — 集成播放器 SDK 日志**

通过 `AliPlayerLoggerProtocol` 统一管理播放器 SDK 的日志输出：

```objc
// 配置 SDK 日志级别
[AliPlayerKit setLogLevel:LogLevelInfo];
[AliPlayerKit enableConsoleLog:NO];
```

---

## **4. 自定义开发**

### **4.1 日志监听器协议**

```objc
@protocol AliPlayerLogListenerProtocol <NSObject>

@required

/// 当日志输出时被调用
/// @param logInfo 日志信息对象
/// @note 回调发生在日志输出的调用线程，如需更新 UI 请切换到主线程
- (void)onLog:(AliPlayerLogInfo *)logInfo;

@end
```

### **4.2 AliPlayerLogInfo 数据模型**

| 属性 | 类型 | 说明 |
|------|------|------|
| `level` | `AliPlayerLogLevel` | 日志级别 |
| `tag` | `NSString *` | 日志标签 |
| `message` | `NSString *` | 日志消息内容 |
| `error` | `NSError *` | 异常信息（如有） |
| `threadName` | `NSString *` | 线程名称 |
| `timestamp` | `NSDate *` | 时间戳 |
| `formattedMessage` | 方法 | 获取格式化的日志字符串 |

**日志格式**：

```text
yyyy-MM-dd HH:mm:ss.SSS [LEVEL] [TAG] [THREAD] message
```

**控制台输出格式**：

```text
[AliPlayerKit][INFO][AliPlayerController] configureWithModel: videoSource=url, autoPlay=YES
[AliPlayerKit][ERROR][MediaPlayer] onError: errorCode=4001, description=Network timeout
```

### **4.3 自定义文件日志监听器示例**

以下是完整的文件日志监听器实现：

```objc
@interface APKFileLogListener : NSObject <AliPlayerLogListenerProtocol>
- (instancetype)initWithLogDirectory:(NSString *)directory;
@end

@implementation APKFileLogListener {
    NSString *_logFilePath;
    dispatch_queue_t _writeQueue;
    NSFileHandle *_fileHandle;
}

- (instancetype)initWithLogDirectory:(NSString *)directory {
    self = [super init];
    if (self) {
        _writeQueue = dispatch_queue_create("com.aliyun.playerkit.filelog",
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

#pragma mark - AliPlayerLogListenerProtocol

- (void)onLog:(AliPlayerLogInfo *)logInfo {
    NSString *formatted = [logInfo formattedMessage];

    // 异步写入文件，避免阻塞调用线程
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

### **4.4 完整集成示例**

```objc
// AppDelegate.m
#import <AliPlayerKit/LogHub.h>

@interface AppDelegate ()
@property (nonatomic, strong) APKFileLogListener *fileLogListener;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 初始化 AliPlayerKit
    [AliPlayerKit setup];

    // 2. 配置日志系统
    LogHub *logHub = [LogHub sharedHub];

#ifdef DEBUG
    logHub.enableLog = YES;
    logHub.enableConsoleOutput = YES;
    logHub.logLevel = AliPlayerLogLevelVerbose;
#else
    logHub.enableLog = YES;
    logHub.enableConsoleOutput = NO;
    logHub.logLevel = AliPlayerLogLevelInfo;

    // 3. 注册文件日志监听器（仅生产环境）
    NSString *logDir = [NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject
        stringByAppendingPathComponent:@"PlayerLogs"];
    self.fileLogListener = [[APKFileLogListener alloc] initWithLogDirectory:logDir];
    [logHub addListener:self.fileLogListener];
#endif

    // 4. 配置播放器 SDK 日志
    [AliPlayerKit setLogLevel:LogLevelInfo];
    [AliPlayerKit enableConsoleLog:NO];

    return YES;
}

@end
```

---

## **5. 最佳实践**

### **5.1 环境配置建议**

| 环境 | 总开关 | 控制台 | 级别 | 监听器 |
|------|--------|--------|------|--------|
| 开发调试 | YES | YES | Verbose | 可选（UI 面板） |
| 内部测试 | YES | YES | Debug | 文件日志 |
| 生产环境 | YES | NO | Info | 文件日志 + 远程上报 |
| 敏感场景 | NO | — | — | — |

### **5.2 Release 模式优化**

通过条件编译在 Release 模式下关闭低级别日志宏，实现零开销：

```objc
#ifdef DEBUG
    #define APKLogV(tag, fmt, ...) \
        [[LogHub sharedHub] verbose:tag message:fmt, ##__VA_ARGS__]
    #define APKLogD(tag, fmt, ...) \
        [[LogHub sharedHub] debug:tag message:fmt, ##__VA_ARGS__]
#else
    #define APKLogV(tag, fmt, ...) ((void)0)
    #define APKLogD(tag, fmt, ...) ((void)0)
#endif
```

### **5.3 常见错误**

#### **错误 1：监听器中阻塞操作导致卡顿**

```objc
// ❌ 错误：在回调中同步写文件
- (void)onLog:(AliPlayerLogInfo *)logInfo {
    NSString *log = [logInfo formattedMessage];
    [log writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// ✅ 正确：异步写入文件
- (void)onLog:(AliPlayerLogInfo *)logInfo {
    NSString *log = [logInfo formattedMessage];
    dispatch_async(_writeQueue, ^{
        // 异步写入...
    });
}
```

#### **错误 2：忘记持有监听器引用**

```objc
// ❌ 错误：局部变量，方法结束后即释放（弱引用自动移除）
- (void)setupLog {
    APKFileLogListener *listener = [[APKFileLogListener alloc] init];
    [[LogHub sharedHub] addListener:listener];
    // listener 方法结束后释放，监听器自动失效
}

// ✅ 正确：使用属性持有强引用
@property (nonatomic, strong) APKFileLogListener *fileLogListener;
```

---

## **6. API 速查**

### **6.1 日志级别**

| 级别 | 枚举值 | 数值 | 说明 |
|-----|--------|------|------|
| Verbose | `AliPlayerLogLevelVerbose` | 0 | 最详细，开发调试 |
| Debug | `AliPlayerLogLevelDebug` | 1 | 调试信息 |
| Info | `AliPlayerLogLevelInfo` | 2 | **默认级别**，生产推荐 |
| Warning | `AliPlayerLogLevelWarning` | 3 | 潜在问题 |
| Error | `AliPlayerLogLevelError` | 4 | 错误信息 |
| None | `AliPlayerLogLevelNone` | 100 | 禁用所有日志 |

### **6.2 LogHub 核心 API**

| 属性 / 方法 | 类型 | 说明 |
|-------------|------|------|
| `sharedHub` | 类方法 | 获取单例 |
| `enableLog` | `BOOL` | 日志总开关（默认 YES） |
| `enableConsoleOutput` | `BOOL` | 控制台开关（默认 YES） |
| `logLevel` | `AliPlayerLogLevel` | 日志级别（默认 Info） |
| `verbose:message:` | 实例方法 | 输出 Verbose 日志 |
| `debug:message:` | 实例方法 | 输出 Debug 日志 |
| `info:message:` | 实例方法 | 输出 Info 日志 |
| `warning:message:` | 实例方法 | 输出 Warning 日志 |
| `error:message:` | 实例方法 | 输出 Error 日志 |
| `log:tag:message:` | 实例方法 | 按指定级别输出 |
| `timeProfile:costTime:` | 实例方法 | 性能时间日志 |
| `addListener:` | 实例方法 | 添加监听器（弱引用） |
| `removeListener:` | 实例方法 | 移除监听器 |
| `levelToString:` | 类方法 | 级别转字符串 |
| `stringToLevel:` | 类方法 | 字符串转级别 |

详细接口说明请参考 [API 参考文档](../ApiReference.md)。

---

## **下一步**

- [播放器生命周期策略](./PlayerLifecycleStrategy.md) — 了解播放器实例管理
- [视频源](./VideoSource.md) — 了解多视频源配置
- [API 参考](../ApiReference.md) — 完整 API 文档
