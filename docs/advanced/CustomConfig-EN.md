# **Custom Config**

**Custom Config** is the extension configuration mechanism of AliPlayerKit. AliPlayerKit comes with built-in best-practice configurations, and most scenarios require no additional setup for an optimal experience. When the player capabilities you need are not directly exposed through AliPlayerKit interfaces, you can use the custom configuration mechanism to call the underlying AliPlayer SDK APIs directly.

---

## **1. Concept Introduction**

### **1.1 What is Custom Config?**

AliPlayerKit provides a high-level abstraction on top of the underlying AliPlayer SDK, with built-in best-practice configurations. However, the underlying SDK offers richer capabilities (such as custom buffering strategies, Referer-based hotlink protection, HTTP Header injection, etc.) that are not all directly exposed through AliPlayerKit.

The custom configuration mechanism provides two callback entry points, allowing developers to access underlying objects at critical moments and call native APIs directly:

| Level | Interface | Trigger Timing | Typical Scenarios |
|-------|-----------|----------------|-------------------|
| **Global Config** | `+setOnGlobalInitBlock:` | After `+setup` completes internal initialization (once only) | Global log level, HTTP/2 multiplexing, and other global behaviors |
| **Instance Config** | `onPlayerConfigBlock` | Before `prepare` during each `configure:` call | Buffering strategy, Referer, HTTP Header, and other instance behaviors |

### **1.2 Three-Layer Configuration System**

The complete configuration system of AliPlayerKit includes three layers:

```text
┌─────────────────────────────────────────────────────────┐
│            1. Global Config (OnGlobalInitBlock)           │
│       Executed once at app launch, affects all instances  │
├─────────────────────────────────────────────────────────┤
│            2. Model Config (AliPlayerModel)               │
│      Set playback parameters via properties on configure: │
├─────────────────────────────────────────────────────────┤
│          3. Instance Config (onPlayerConfigBlock)         │
│    Callback to underlying player before prepare on each   │
│    configure: call                                        │
└─────────────────────────────────────────────────────────┘
```

---

## **2. Global Config**

### **2.1 Applicable Scenarios**

- Setting global Options (e.g., global log level)
- Enabling HTTP/2 multiplexing
- Configuring global DNS resolution strategies
- Other global behaviors that need to take effect before any player instance is created

### **2.2 Mechanism**

- Register a callback Block via `+[AliPlayerKit setOnGlobalInitBlock:]`
- The callback is triggered after `+setup` completes internal initialization, **executed only once**
- After execution, the Block is set to nil and will not be triggered again
- At this point, the underlying SDK is ready and global APIs can be safely called

### **2.3 Usage**

Register the callback **before** calling `+setup` in `application:didFinishLaunchingWithOptions:`:

```objc
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. Register global custom config callback (must be called before setup)
    [AliPlayerKit setOnGlobalInitBlock:^{
        // Example: Enable HTTP/2 multiplexing
        [AliPlayerFactory setOption:ALLOW_H2_MULTIPLEX value:1];

        // Example: Set global log level
        // [AliPlayerFactory setLogLevel:AF_LOG_LEVEL_INFO];
    }];

    // 2. Initialize (triggers the registered callback after internal initialization)
    [AliPlayerKit setup];

    return YES;
}
```

### **2.4 Configuration Timing**

```text
application:didFinishLaunchingWithOptions:
    │
    ├── [AliPlayerKit setOnGlobalInitBlock:block]   ← Register callback
    │
    └── [AliPlayerKit setup]
            │
            ├── [GlobalManager setup]    ← Underlying SDK initialization
            │
            ├── sInitialized = YES
            │
            └── block()                  ← Trigger global config callback (once only)
```

### **2.5 Notes**

| Key Point | Description |
|-----------|-------------|
| Call Order | `setOnGlobalInitBlock:` must be called **before** `+setup` |
| Execution Count | Global config is executed only once; `+setup` internally uses `dispatch_once` for protection |
| Pass nil to Clear | Passing `nil` cancels the registered callback |
| Idempotency | Calling `+setup` multiple times only executes once; subsequent calls will not trigger the callback again |

---

## **3. Instance Config (Player Config)**

### **3.1 Applicable Scenarios**

- Custom buffering strategies (`maxBufferDuration`, `highBufferDuration`, etc.)
- Setting Referer-based hotlink protection
- Configuring HTTP Headers
- Setting instance-level Options
- Other player interfaces not directly exposed by AliPlayerKit

### **3.2 Mechanism**

- Set a callback Block via `AliPlayerModel.onPlayerConfigBlock`
- Triggered each time `[controller configure:model]` is called
- The callback executes after `setDataSource:` and before `prepare`
- The callback parameter is an underlying player instance conforming to the `MediaPlayer` protocol

### **3.3 Usage**

Set `onPlayerConfigBlock` when building an `AliPlayerModel`:

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

// Set instance-level custom config callback
model.onPlayerConfigBlock = ^(id<MediaPlayer> player) {
    // Example 1: Custom buffering strategy
    AVPConfig *config = [player getConfig];
    config.maxBufferDuration = 50000;       // Max buffer duration 50s
    config.highBufferDuration = 3000;       // High watermark buffer 3s
    config.startBufferDuration = 500;       // Startup buffer 500ms
    [player setConfig:config];

    // Example 2: Set Referer-based hotlink protection
    AVPConfig *refConfig = [player getConfig];
    refConfig.referer = @"https://your-domain.com";
    [player setConfig:refConfig];

    // Example 3: Set instance-level Option
    // [player setOption:key value:value];
};

// Configure and play
[controller configure:model];
```

### **3.4 Configuration Timing**

```text
[controller configure:model]
    │
    ├── lifecycleStrategy.acquire()             ← Acquire player instance
    │
    ├── [mediaPlayer setDataSource:model]       ← Set video source
    │
    ├── model.onPlayerConfigBlock(mediaPlayer)  ← Trigger instance config callback
    │
    ├── [strategyManager start/reset]           ← Strategy system starts
    │
    └── [mediaPlayer prepare]                   ← Begin preparing playback
```

### **3.5 Notes**

| Key Point | Description |
|-----------|-------------|
| Trigger Frequency | Triggered on every `configure:` call, suitable for dynamic configuration scenarios |
| Execution Timing | After `setDataSource:` and before `prepare` — the optimal time for custom configuration |
| Callback Parameter | An `id<MediaPlayer>` instance with access to all underlying SDK interfaces |
| Optional | `onPlayerConfigBlock` can be left unset without affecting normal playback |
| Avoid Async | The callback executes synchronously; do not perform time-consuming or asynchronous operations within it |

---

## **4. Built-in Configuration Items**

### **4.1 AliPlayerKit Global Configuration**

Built-in configuration items set directly via `AliPlayerKit` class methods:

| Configuration | Method | Description |
|---------------|--------|-------------|
| Initialization | `+setup` | Initialize the SDK; `dispatch_once` ensures idempotency |
| Initialization Status | `+isInitialized` | Query whether the SDK has completed initialization |
| Global Config Callback | `+setOnGlobalInitBlock:` | Register a custom config callback after global initialization |
| Debug Mode | `+setDebugModeEnabled:` / `+isDebugModeEnabled` | Enable/disable debug mode (default `NO`) |
| Log Panel | `+setLogPanelEnabled:` / `+isLogPanelEnabled` | Whether to display the log panel in the player view (default `NO`) |
| Log Level | `+setLogLevel:` / `+logLevel` | SDK log output level (default `LogLevelInfo`) |
| Console Log | `+enableConsoleLog:` / `+isConsoleLogEnabled` | Whether to output logs to the console (default `YES`) |
| Player Factory | `+setPlayerFactory:` / `+playerFactory` | Custom player creation factory; pass `nil` to restore default |
| Preloader | `+setPreloader:` / `+preloader` | Custom preloader; pass `nil` to restore default |
| Clear Cache | `+clearCaches` | Clear local media cache (must be called after `setup`) |
| Language Setting | `+setLanguageCode:` | Manually specify language code (`zh-Hans` / `en`) |
| Custom Translation | `+setLocaleProvider:` | Inject a custom localization Provider |
| Follow System Language | `+resetLocaleToSystemLanguage` | Restore to follow system preferred language |
| Current Language | `+currentLanguageCode` | Get the currently active language code |
| Version Info | `+getPlayerKitVersion` / `+getSdkVersion` | Get AliPlayerKit / underlying SDK version number |

### **4.2 AliPlayerModel Instance Configuration**

Instance-level configuration items set via `AliPlayerModel` properties:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `videoSource` | `VideoSource *` | — | Required, video data source (`readonly`, set via `initWithVideoSource:`) |
| `sceneType` | `SceneType` | `SceneTypeVOD` | Playback scene, affects slot UI and gesture behavior |
| `coverUrl` | `NSString *` | `nil` | Video cover image URL |
| `videoTitle` | `NSString *` | `nil` | Title displayed in TopBar |
| `autoPlay` | `BOOL` | `YES` | Whether to automatically start playback after configuration |
| `traceId` | `NSString *` | `nil` | Playback quality monitoring identifier (business-side unique ID) |
| `startTime` | `NSInteger` | `0` | Playback start position (milliseconds); negative values auto-corrected to 0 |
| `hardwareDecode` | `BOOL` | `YES` | Whether to enable hardware decoding |
| `allowScreenSleep` | `BOOL` | `NO` | Whether to allow screen sleep during playback |
| `disableScreenshot` | `BOOL` | `NO` | iOS-specific, disable screenshot/screen recording |
| `onPlayerConfigBlock` | `void (^)(id<MediaPlayer>)` | `nil` | Instance-level custom config callback |

### **4.3 AliPlayerController Runtime Configuration**

Configuration dynamically adjusted at runtime via `AliPlayerController` methods:

| Method / Property | Type | Description |
|-------------------|------|-------------|
| `-setRate:` | `float` | Playback speed (1.0 normal, 0.5 half speed, 2.0 double speed) |
| `-setLoop:` | `BOOL` | Whether to loop playback |
| `-setMuted:` | `BOOL` | Whether to mute |
| `-setMirrorMode:` | `MirrorMode` | Mirror mode (`None` / `Horizontal` / `Vertical`) |
| `-setScaleMode:` | `ScaleMode` | Scale mode (`FitXY` / `FitCenter` / `CenterCrop`) |
| `-setRotateMode:` | `RotateMode` | Rotation angle (`0` / `90` / `180` / `270` degrees) |
| `-setControlsVisible:` | `BOOL` | Show/hide control bar |
| `controlsVisibilityLocked` | `BOOL` | Lock control bar visibility (`YES` causes `setControlsVisible:NO` to be ignored) |
| `-setFullscreen:` | `BOOL` | Enter/exit fullscreen (with animation by default) |
| `-setFullscreen:animated:` | `BOOL, BOOL` | Enter/exit fullscreen (animation controllable) |
| `-selectTrack:` | `TrackQuality *` | Switch quality/resolution |
| `-snapshot` | — | Capture current video frame |
| `-toggle` | — | Toggle play/pause state |
| `-replay` | — | Replay from the beginning |
| `-stop` | — | Stop playback |
| `autoLifecycleManagement` | `BOOL` | Automatically manage pause/resume on background/foreground transitions (default `YES`) |

---

## **5. Configuration Priority**

### **5.1 Priority Rules**

When the same configuration item is set at different levels, the following priority applies:

```text
Instance Config (onPlayerConfigBlock) > AliPlayerModel Properties > Global Config > SDK Defaults
```

### **5.2 Configuration Scope**

| Level | Scope | Lifecycle |
|-------|-------|-----------|
| Global Config | All player instances | Application-level (executed once only) |
| Model Properties | Single player instance | Single `configure:` call |
| Instance Config Callback | Single player instance | Triggered on each `configure:` call |
| Controller Methods | Single player instance | Takes effect dynamically at runtime |

---

## **6. Complete Configuration Example**

### **6.1 Comprehensive Example**

```objc
// ===== Global Config (in AppDelegate, once only) =====
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Global custom config
    [AliPlayerKit setOnGlobalInitBlock:^{
        // Enable HTTP/2 multiplexing
        [AliPlayerFactory setOption:ALLOW_H2_MULTIPLEX value:1];
    }];

    // Initialize
    [AliPlayerKit setup];

    // Global built-in config (must be called after setup)
    [AliPlayerKit setLogLevel:LogLevelWarn];
    [AliPlayerKit enableConsoleLog:YES];

    return YES;
}

// ===== Instance Config (in playback page, each time) =====
- (void)startPlayback {
    VideoSource *source = [VideoSource urlSourceWithUrl:videoUrl];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

    // Model property configuration
    model.sceneType = SceneTypeVOD;
    model.videoTitle = @"精彩视频";
    model.coverUrl = coverImageUrl;
    model.autoPlay = YES;
    model.hardwareDecode = YES;
    model.startTime = resumePosition; // Resume from last position

    // Instance-level custom config (underlying SDK)
    model.onPlayerConfigBlock = ^(id<MediaPlayer> player) {
        AVPConfig *config = [player getConfig];
        config.maxBufferDuration = 50000;
        config.highBufferDuration = 3000;
        config.startBufferDuration = 500;
        config.referer = @"https://your-domain.com";
        [player setConfig:config];
    };

    [_controller configure:model];
}
```

> **Note**: Log configurations such as `setLogLevel:` and `enableConsoleLog:` must be called after `setup`, as they operate on the `LogHub` singleton instance.

---

## **7. API Quick Reference**

### **7.1 Global Config API**

| Method | Description |
|--------|-------------|
| `+[AliPlayerKit setOnGlobalInitBlock:]` | Register global config callback; pass `nil` to cancel |
| `+[AliPlayerKit setup]` | Trigger initialization and execute callback |

### **7.2 Instance Config API**

| Class | Property | Description |
|-------|----------|-------------|
| `AliPlayerModel` | `onPlayerConfigBlock` | Instance-level config callback (`void (^)(id<MediaPlayer>)`) |

### **7.3 Related Files**

| File | Description |
|------|-------------|
| `PlayerKit/Source/AliPlayerKit.h` | Global config API (`OnGlobalInitBlock` typedef) |
| `PlayerKit/Source/AliPlayerModel.h` | Instance config entry point (`onPlayerConfigBlock`) |
| `PlayerKit/Source/AliPlayerController.h` | Runtime configuration methods |
| `PlayerKit/Source/Player/MediaPlayer.h` | Underlying player protocol (callback parameter type) |

> For complete API details, see [API Reference](../ApiReference-EN.md).

---

## **8. FAQ**

### **8.1 What is the execution order of global config and instance config?**

Global config executes once at app launch (within `+setup`); instance config executes before `prepare` on each `configure:` call. They do not interfere with each other.

### **8.2 What happens if no custom config is set?**

AliPlayerKit comes with built-in best-practice configurations. It works normally without any custom configuration and is suitable for most scenarios.

### **8.3 Can I perform async operations in the instance config callback?**

Not recommended. The callback executes synchronously, and `prepare` continues only after it completes. Performing time-consuming operations in the callback will block the player startup flow.

### **8.4 Can I modify the video source in the instance config?**

Not recommended. The video source is already set via `setDataSource:` before the callback. Modifying it within the callback may lead to unpredictable behavior. The instance config callback should only be used for setting playback parameters (such as buffering strategy, Referer, etc.).

### **8.5 What happens if `setOnGlobalInitBlock:` is called after `+setup`?**

It will not take effect. `+setup` uses `dispatch_once` to guarantee single execution. If the Block is set after `+setup`, it will never be triggered.

### **8.6 Should log configuration be done before or after setup?**

`setLogLevel:` and `enableConsoleLog:` must be called **after** `+setup`, as they directly operate on the `LogHub` singleton. In contrast, `setOnGlobalInitBlock:` must be set **before** `+setup`.
