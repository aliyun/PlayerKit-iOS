# **Log System**

The **Log System** is a foundational module of AliPlayerKit. Through the unified log center `LogHub`, it provides core capabilities such as log output, level filtering, and an observer mechanism, enabling visualization and traceability of player runtime information.

---

## **1. Concepts**

### **1.1 What is LogHub?**

**LogHub** is the unified entry point for all log output in AliPlayerKit, designed as a singleton. It wraps the iOS native logging API (`NSLog`) and adds the following core capabilities on top of the original functionality:

| Capability | Description |
|-----|------|
| Log Switch | Controls whether log output is enabled (master switch) |
| Console Switch | Controls whether logs are output to the Xcode Console |
| Level Filtering | Only outputs logs at or above the specified level |
| Observer Mechanism | Supports external observers to receive log output for custom handling (e.g., writing to files) |

### **1.2 What is a Log Observer?**

A **Log Observer (LogObserver)** is a callback protocol for receiving log output from `LogHub`. By implementing this protocol, you can customize log handling, for example:

- Writing logs to files for troubleshooting and providing to the technical support team
- Uploading logs to a remote server for remote log collection
- Displaying logs in the UI for a debug panel

### **1.3 Hybrid Threading Model**

`LogHub` uses a hybrid threading model:

| Operation | Thread |
|------|------|
| Thread name and timestamp capture | Synchronous on the calling thread |
| Console output (NSLog) | Synchronous on the calling thread |
| Observer notifications | Asynchronous dispatch on a background serial queue |

> **Note**: The `LogObserver.onLog:` callback executes on a **background serial queue**. Switch to the main thread if you need to update the UI.

---

## **2. Features**

### **2.1 Core Capabilities**

| Capability | Description |
|-----|------|
| Multi-level Logging | Supports five levels: Verbose, Debug, Info, Warn, Error |
| Triple Control | Master switch + level filtering + console switch for precise output control |
| Observer Mechanism | Supports registering custom observers for log persistence, remote reporting, etc. |
| Convenience Macros | Provides `SLOGV/D/I/W/E` macros that automatically capture source location |
| Log Panel | Displays logs in real-time within the player view via `LogPanelSlot` (debug only) |
| Global Shortcut API | Quickly configure log level and console output via `AliPlayerKit` class methods |

### **2.2 Core Components**

| Component | Type | Description |
|------|------|------|
| `LogHub` | Singleton | Log center, unified log output entry point |
| `LogLevel` | Enum | Log level definitions |
| `LogInfo` | Data Class | Log information model, encapsulating complete information for a single log entry |
| `LogObserver` | Protocol | Log observer interface |
| `LogPanelSlot` | Slot | Player-embedded log panel for real-time display of key logs |

---

## **3. Usage**

### **3.1 Basic Usage - Global Shortcut Configuration**

Quickly configure the log system via `AliPlayerKit` class methods (recommended approach):

```objc
// Configure after setup in AppDelegate
[AliPlayerKit setup];

// Set log level
[AliPlayerKit setLogLevel:LogLevelVerbose];

// Enable/disable console logging
[AliPlayerKit enableConsoleLog:YES];
```

| AliPlayerKit Method | Description |
|-------------------|------|
| `setLogLevel:` | Set the log level; logs below this level are ignored (default `LogLevelInfo`) |
| `logLevel` | Get the current log level |
| `enableConsoleLog:` | Enable/disable console output (enabled by default) |
| `isConsoleLogEnabled` | Query whether console logging is enabled |
| `setDebugModeEnabled:` | Enable/disable debug mode |
| `isDebugModeEnabled` | Query whether debug mode is enabled |
| `setLogPanelEnabled:` | Enable/disable the log panel slot (disabled by default) |
| `isLogPanelEnabled` | Query whether the log panel is enabled |

### **3.2 Basic Usage - Output Logs**

Use the `SLOG` series of convenience macros to output logs at various levels. The macros automatically capture the source file name and line number:

```objc
#import <AliPlayerKit/LogMacros.h>

// Output logs at various levels (automatically captures __FILE_NAME__ and __LINE__)
SLOGV(@"viewDidLoad called");
SLOGD(@"Configuring player: videoId=%@", videoId);
SLOGI(@"Starting video playback: %@", videoTitle);
SLOGW(@"Buffering, current progress: %.1f%%", progress * 100);
SLOGE(@"Playback failed, error code: %ld", (long)errorCode);
```

**Convenience Macro List**:

| Macro | Level | Description |
|----|------|------|
| `SLOGV(fmt, ...)` | Verbose | Most detailed level |
| `SLOGD(fmt, ...)` | Debug | Debug information |
| `SLOGI(fmt, ...)` | Info | General information |
| `SLOGW(fmt, ...)` | Warn | Potential issues |
| `SLOGE(fmt, ...)` | Error | Error information |

> **Note**: The `SLOG` macros internally call `LogHub`'s `logLevel:file:line:message:error:` method, automatically capturing the source location via `__FILE_NAME__` and `__LINE__`, eliminating the need to manually pass a tag.

You can also call `LogHub` instance methods directly, specifying the tag manually:

```objc
// Use a tag to identify the log source
[[LogHub sharedHub] i:@"PlayerVC" msg:@"Starting playback"];
[[LogHub sharedHub] e:@"MediaPlayer" msg:@"Playback failed" error:error];
```

### **3.3 Basic Usage - Configure Log Level**

Configure log properties directly via `LogHub`:

```objc
LogHub *logHub = [LogHub sharedHub];

#ifdef DEBUG
    // Development: verbose logging + console output
    logHub.logEnabled = YES;
    logHub.consoleLogEnabled = YES;
    logHub.logLevel = LogLevelVerbose;
#else
    // Production: minimal logging + console disabled
    logHub.logEnabled = YES;
    logHub.consoleLogEnabled = NO;
    logHub.logLevel = LogLevelInfo;
#endif
```

**Triple Control Mechanism**:

| Control Layer | Property | Description |
|--------|------|------|
| Master Switch | `logEnabled` | When disabled, all logs are silenced (including observer notifications) |
| Level Filtering | `logLevel` | Logs below this level are ignored (default `LogLevelInfo`) |
| Console Switch | `consoleLogEnabled` | Controls whether output goes to the Xcode Console via NSLog |

> **Note**: After disabling `consoleLogEnabled`, logs are still distributed via observer notifications; only console output is suppressed. After disabling `logEnabled`, all log requests are completely ignored, and observers will not receive notifications either.

### **3.4 Advanced Usage - Register a Log Observer**

Customize log handling by implementing the `LogObserver` protocol:

```objc
// Create and register a file log observer
FileLogObserver *fileObserver = [[FileLogObserver alloc] init];
[[LogHub sharedHub] addObserver:fileObserver];

// Remove the observer (when no longer needed)
[[LogHub sharedHub] removeObserver:fileObserver];
```

> **Note**: `LogHub` holds observers with a **weak reference** (backed by `NSHashTable weakObjectsHashTable`). An observer is automatically removed from the list once it is deallocated, so there is no risk of a retain cycle. It is still recommended to call `removeObserver:` proactively at the appropriate time (e.g., in `viewWillDisappear:`) to avoid receiving log callbacks during the window right before the object is deallocated.

### **3.5 Advanced Usage - Log Panel**

`LogPanelSlot` is a built-in debug slot that displays key log information in real-time within the player view:

```objc
// Enable the log panel (recommended only for debug scenarios)
[AliPlayerKit setLogPanelEnabled:YES];
```

| Interaction | Description |
|------|------|
| Tap the title bar | Expand/collapse the log content area |
| Tap the "Clear" button | Clear displayed logs |
| Long press the log area | Copy log content to the clipboard |

> **Note**: The log panel only displays logs at Debug level and above. `setLogPanelEnabled:` must be set before `rebuildSlots`. Not visible in the Minimal scenario.

---

## **4. Custom Development**

### **4.1 Log Observer Protocol (LogObserver)**

```objc
@protocol LogObserver <NSObject>

@required

/// Log output callback
/// @param logInfo Log information object containing level, tag, message, and timestamp
/// @warning The callback executes on a background serial queue; dispatch to the main thread if you need to update the UI
- (void)onLog:(LogInfo *)logInfo;

@end
```

### **4.2 LogInfo Data Model**

| Property | Type | Description |
|------|------|------|
| `level` | `LogLevel` | Log level (readonly) |
| `tag` | `NSString *` | Log tag (readonly) |
| `message` | `NSString *` | Log message content (readonly) |
| `timestamp` | `NSDate *` | Log generation timestamp (readonly) |
| `threadName` | `NSString *` | Name of the thread that generated the log (readonly) |
| `fileName` | `NSString *` | Source file name, e.g., `@"MyClass.m"` (readonly) |
| `line` | `NSInteger` | Source code line number (readonly) |
| `error` | `NSError *` | Associated error object, may be nil (readonly) |

| Method | Description |
|------|------|
| `formattedString` | Get the formatted log string |
| `initWithLevel:fileName:line:message:error:threadName:timestamp:` | Designated initializer |
| `initWithLevel:tag:message:` | Convenience initializer (automatically captures timestamp and thread name) |

**Formatted Output Format**:

```text
2024-04-22 10:30:00.123 I/AliPlayerKit [version] [FileName:line] [threadName] : message
```

If an error exists, an additional line is appended:

```text
Error: domain=xxx code=xxx userInfo=xxx
```

### **4.3 Custom File Log Observer Example**

The following is a complete implementation of a file log observer:

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
            // Ignore write exceptions
        }
    });
}

- (void)dealloc {
    [_fileHandle closeFile];
}

@end
```

> **Note**: The `onLog:` callback already executes on a background serial queue, but it is still recommended to use a separate write queue for file I/O to avoid blocking the log dispatch queue and affecting other observers.

### **4.4 Complete Integration Example**

```objc
// AppDelegate.m
#import <AliPlayerKit/AliPlayerKit.h>

@interface AppDelegate ()
@property (nonatomic, strong) MyFileLogObserver *fileLogObserver;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. Initialize AliPlayerKit
    [AliPlayerKit setup];

    // 2. Configure the log system
#ifdef DEBUG
    [AliPlayerKit setLogLevel:LogLevelVerbose];
    [AliPlayerKit enableConsoleLog:YES];
    // Optional: enable log panel
    [AliPlayerKit setLogPanelEnabled:YES];
#else
    [AliPlayerKit setLogLevel:LogLevelInfo];
    [AliPlayerKit enableConsoleLog:NO];

    // 3. Register file log observer (production only)
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

> **Reference**: The `PlayerKitUsages/UsageLogSystem` module provides a complete log system usage example, including a `FileLogObserver` file log observer and UI log display.

---

## **5. Best Practices**

### **5.1 Environment Configuration Recommendations**

| Environment | Master Switch | Console | Level | Observers | Log Panel |
|------|--------|--------|------|--------|---------|
| Development | YES | YES | Verbose | Optional (UI panel) | Optional |
| Internal Testing | YES | YES | Debug | File logging | NO |
| Production | YES | NO | Info | File logging + remote reporting | NO |
| Sensitive Scenarios | NO | - | - | - | NO |

### **5.2 Common Mistakes**

#### **Mistake 1: Updating UI directly in an observer callback**

```objc
// ✗ Wrong: onLog: executes on a background serial queue; updating UI directly will crash
- (void)onLog:(LogInfo *)logInfo {
    self.logLabel.text = [logInfo formattedString];  // Crash!
}

// ✓ Correct: Switch to the main thread to update UI
- (void)onLog:(LogInfo *)logInfo {
    NSString *formatted = [logInfo formattedString];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logLabel.text = formatted;
    });
}
```

#### **Mistake 2: Synchronous blocking operations in an observer**

```objc
// ✗ Wrong: Synchronously writing to file in the callback blocks the log dispatch queue
- (void)onLog:(LogInfo *)logInfo {
    NSString *log = [logInfo formattedString];
    [log writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// ✓ Correct: Write to file asynchronously
- (void)onLog:(LogInfo *)logInfo {
    NSString *log = [logInfo formattedString];
    dispatch_async(_writeQueue, ^{
        // Write asynchronously...
    });
}
```

#### **Recommendation: Remove observers promptly to avoid pointless callbacks**

```objc
// LogHub holds a weak reference to the observer; not removing it does not cause a retain cycle,
// but the object may still receive log callbacks after it has disappeared from screen.
- (void)viewDidLoad {
    [[LogHub sharedHub] addObserver:self];
}

// ✓ Recommended: remove proactively at the end of the lifecycle
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[LogHub sharedHub] removeObserver:self];
}
```

> **Note**: Like the notification system's Dispatcher, `LogHub` holds observers with a **weak reference**, so there is no memory leak risk. Calling `removeObserver:` is mainly to avoid receiving pointless log callbacks after the observer's lifecycle has ended.

---

## **6. API Reference**

### **6.1 Log Level (LogLevel)**

| Level | Enum Value | Numeric Value | Description |
|-----|--------|------|------|
| Verbose | `LogLevelVerbose` | 0 | Most detailed, for development debugging |
| Debug | `LogLevelDebug` | 1 | Debug information |
| Info | `LogLevelInfo` | 2 | **Default level**, recommended for production |
| Warn | `LogLevelWarn` | 3 | Potential issues |
| Error | `LogLevelError` | 4 | Error information |
| None | `LogLevelNone` | 100 | Disables all logging |

> **Note**: `LogLevel.h` also provides the `LogLevelToString()` inline function, which converts a level to its abbreviated string (V/D/I/W/E/N).

### **6.2 LogHub Core API**

| Property / Method | Type | Description |
|-------------|------|------|
| `+sharedHub` | Class method | Get the singleton instance |
| `logEnabled` | `BOOL` | Master log switch (default YES) |
| `logLevel` | `LogLevel` | Log level (default `LogLevelInfo`) |
| `consoleLogEnabled` | `BOOL` | Console switch (default YES) |
| `v:msg:` | Instance method | Output a Verbose log |
| `d:msg:` | Instance method | Output a Debug log |
| `i:msg:` | Instance method | Output an Info log |
| `w:msg:` | Instance method | Output a Warn log |
| `e:msg:` | Instance method | Output an Error log |
| `e:msg:error:` | Instance method | Output an Error log with an `NSError` |
| `log:tag:msg:` | Instance method | Output at a specified level |
| `logLevel:file:line:message:error:` | Instance method | Core log method (used by SLOG macros) |
| `addObserver:` | Instance method | Add an observer (**weak reference**, duplicate additions have no effect) |
| `removeObserver:` | Instance method | Remove an observer |
| `+levelToString:` | Class method | Convert level to string (V/D/I/W/E/N) |
| `+stringToLevel:` | Class method | Convert string to level (case-insensitive, returns `LogLevelInfo` if unrecognized) |

### **6.3 AliPlayerKit Log Shortcut API**

| Method | Description |
|------|------|
| `+setLogLevel:` | Set the log level (must be called after `setup`) |
| `+logLevel` | Get the current log level |
| `+enableConsoleLog:` | Enable/disable console log output |
| `+isConsoleLogEnabled` | Query whether console logging is enabled |
| `+setDebugModeEnabled:` | Enable/disable debug mode |
| `+isDebugModeEnabled` | Query whether debug mode is enabled |
| `+setLogPanelEnabled:` | Enable/disable the log panel slot |
| `+isLogPanelEnabled` | Query whether the log panel is enabled |

### **6.4 SLOG Convenience Macros**

| Macro | Level | Expansion |
|----|------|---------|
| `SLOGV(fmt, ...)` | Verbose | `[[LogHub sharedHub] logLevel:LogLevelVerbose file:@(__FILE_NAME__) line:__LINE__ message:... error:nil]` |
| `SLOGD(fmt, ...)` | Debug | Same as above, with Debug level |
| `SLOGI(fmt, ...)` | Info | Same as above, with Info level |
| `SLOGW(fmt, ...)` | Warn | Same as above, with Warn level |
| `SLOGE(fmt, ...)` | Error | Same as above, with Error level |

### **6.5 LogInfo Properties**

| Property | Type | Description |
|------|------|------|
| `level` | `LogLevel` | Log level |
| `tag` | `NSString *` | Log tag |
| `message` | `NSString *` | Log message content |
| `timestamp` | `NSDate *` | Log generation timestamp |
| `threadName` | `NSString *` | Thread name |
| `fileName` | `NSString *` | Source file name |
| `line` | `NSInteger` | Source code line number |
| `error` | `NSError *` | Associated error object (nullable) |
| `formattedString` | Method | Get the formatted log string |

### **6.6 LogObserver Protocol**

| Method | Required | Description |
|------|------|------|
| `onLog:` | Yes (`@required`) | Log output callback, executes on a background serial queue |
