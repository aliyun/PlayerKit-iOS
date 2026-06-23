# **自定义配置 (Custom Config)**

**自定义配置 (Custom Config)** 是 AliPlayerKit 的扩展配置机制。AliPlayerKit 已内置最佳实践配置，大多数场景无需额外设置即可获得优质体验。当需要的播放器能力未通过 AliPlayerKit 接口直接提供时，可通过自定义配置机制直接调用底层 AliPlayer SDK 的 API 来实现。

---

## **1. 概念介绍**

### **1.1 什么是自定义配置？**

AliPlayerKit 在底层 AliPlayer SDK 之上提供了高层封装，已内置最佳实践配置。但底层 SDK 提供了更丰富的能力（如自定义缓冲策略、Referer 防盗链、HTTP Header 注入等），这些能力并非都通过 AliPlayerKit 直接透出。

自定义配置机制提供了两个回调入口，让开发者在关键时机获取底层对象并直接调用原生 API：

| 层级 | 接口 | 调用时机 | 典型场景 |
|------|------|----------|----------|
| **全局配置** | `+setOnGlobalInitBlock:` | `+setup` 内部初始化完成后（仅一次） | 全局日志级别、HTTP/2 多路复用等全局行为 |
| **实例配置** | `onPlayerConfigBlock` | 每次 `configure:` 时 `prepare` 前 | 缓冲策略、Referer、HTTP Header 等实例行为 |

### **1.2 三层配置体系**

AliPlayerKit 的完整配置体系包含三个层级：

```text
┌─────────────────────────────────────────────────────────┐
│              1. 全局配置 (OnGlobalInitBlock)              │
│         应用启动时执行一次，影响所有播放器实例                │
├─────────────────────────────────────────────────────────┤
│              2. 模型配置 (AliPlayerModel)                 │
│         每次 configure: 时通过属性设置播放参数               │
├─────────────────────────────────────────────────────────┤
│           3. 实例配置 (onPlayerConfigBlock)               │
│       每次 configure: 时在 prepare 前回调底层播放器          │
└─────────────────────────────────────────────────────────┘
```

---

## **2. 全局配置（Global Config）**

### **2.1 适用场景**

- 设置全局 Option（如全局日志级别）
- 启用 HTTP/2 多路复用
- 配置全局 DNS 解析策略
- 其他需要在所有播放器实例创建前生效的全局行为

### **2.2 机制说明**

- 通过 `+[AliPlayerKit setOnGlobalInitBlock:]` 注册回调 Block
- 回调在 `+setup` 完成内部初始化后触发，**仅执行一次**
- 执行后 Block 被置 nil，后续不再触发
- 此时底层 SDK 已就绪，可安全调用全局 API

### **2.3 使用方式**

在 `application:didFinishLaunchingWithOptions:` 中，调用 `+setup` **之前**注册回调：

```objc
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 注册全局自定义配置回调（必须在 setup 之前调用）
    [AliPlayerKit setOnGlobalInitBlock:^{
        // 示例：启用 HTTP/2 多路复用
        [AliPlayerFactory setOption:ALLOW_H2_MULTIPLEX value:1];

        // 示例：设置全局日志级别
        // [AliPlayerFactory setLogLevel:AF_LOG_LEVEL_INFO];
    }];

    // 2. 初始化（内部完成初始化后触发上面注册的回调）
    [AliPlayerKit setup];

    return YES;
}
```

### **2.4 配置时序**

```text
application:didFinishLaunchingWithOptions:
    │
    ├── [AliPlayerKit setOnGlobalInitBlock:block]   ← 注册回调
    │
    └── [AliPlayerKit setup]
            │
            ├── [GlobalManager setup]    ← 底层 SDK 初始化
            │
            ├── sInitialized = YES
            │
            └── block()                  ← 触发全局配置回调（仅一次）
```

### **2.5 注意事项**

| 要点 | 说明 |
|------|------|
| 调用顺序 | `setOnGlobalInitBlock:` 必须在 `+setup` **之前**调用 |
| 执行次数 | 全局配置仅执行一次，`+setup` 内部使用 `dispatch_once` 保护 |
| 传 nil 清除 | 传入 `nil` 可取消已注册的回调 |
| 幂等性 | `+setup` 多次调用只执行一次，第二次调用不会再触发回调 |

---

## **3. 实例配置（Player Config）**

### **3.1 适用场景**

- 自定义缓冲策略（`maxBufferDuration`、`highBufferDuration` 等）
- 设置 Referer 防盗链
- 配置 HTTP Header
- 设置实例级 Option
- 其他 AliPlayerKit 未直接透出的播放器接口

### **3.2 机制说明**

- 通过 `AliPlayerModel.onPlayerConfigBlock` 设置回调 Block
- 每次调用 `[controller configure:model]` 时触发
- 回调在 `setDataSource:` 之后、`prepare` 之前执行
- 回调参数为遵循 `MediaPlayer` 协议的底层播放器实例

### **3.3 使用方式**

在构建 `AliPlayerModel` 时设置 `onPlayerConfigBlock`：

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

// 设置实例级自定义配置回调
model.onPlayerConfigBlock = ^(id<MediaPlayer> player) {
    // 示例 1：自定义缓冲策略
    AVPConfig *config = [player getConfig];
    config.maxBufferDuration = 50000;       // 最大缓冲时长 50s
    config.highBufferDuration = 3000;       // 高水位缓冲 3s
    config.startBufferDuration = 500;       // 起播缓冲 500ms
    [player setConfig:config];

    // 示例 2：设置 Referer 防盗链
    AVPConfig *refConfig = [player getConfig];
    refConfig.referer = @"https://your-domain.com";
    [player setConfig:refConfig];

    // 示例 3：设置实例级 Option
    // [player setOption:key value:value];
};

// 配置并播放
[controller configure:model];
```

### **3.4 配置时序**

```text
[controller configure:model]
    │
    ├── lifecycleStrategy.acquire()             ← 获取播放器实例
    │
    ├── [mediaPlayer setDataSource:model]       ← 配置视频源
    │
    ├── model.onPlayerConfigBlock(mediaPlayer)  ← 触发实例配置回调
    │
    ├── [strategyManager start/reset]           ← 策略系统启动
    │
    └── [mediaPlayer prepare]                   ← 开始准备播放
```

### **3.5 注意事项**

| 要点 | 说明 |
|------|------|
| 触发频率 | 每次调用 `configure:` 都会触发，适合动态配置场景 |
| 执行时机 | 在 `setDataSource:` 之后、`prepare` 之前，是自定义配置的最佳时机 |
| 回调参数 | `id<MediaPlayer>` 实例，可调用底层 SDK 的所有接口 |
| 可选配置 | `onPlayerConfigBlock` 可不设置，不影响正常播放 |
| 避免异步 | 回调是同步执行的，不应在回调中执行耗时或异步操作 |

---

## **4. 内置配置项**

### **4.1 AliPlayerKit 全局配置**

通过 `AliPlayerKit` 类方法直接设置的内置配置项：

| 配置项 | 方法 | 说明 |
|--------|------|------|
| 初始化 | `+setup` | 初始化 SDK，`dispatch_once` 保证幂等 |
| 初始化状态 | `+isInitialized` | 查询 SDK 是否已完成初始化 |
| 全局配置回调 | `+setOnGlobalInitBlock:` | 注册全局初始化后的自定义配置回调 |
| 调试模式 | `+setDebugModeEnabled:` / `+isDebugModeEnabled` | 开启/关闭调试模式（默认 `NO`） |
| 日志面板 | `+setLogPanelEnabled:` / `+isLogPanelEnabled` | 是否在播放器视图中显示日志面板（默认 `NO`） |
| 日志级别 | `+setLogLevel:` / `+logLevel` | SDK 日志输出级别（默认 `LogLevelInfo`） |
| 控制台日志 | `+enableConsoleLog:` / `+isConsoleLogEnabled` | 是否输出日志到控制台（默认 `YES`） |
| 播放器工厂 | `+setPlayerFactory:` / `+playerFactory` | 自定义播放器创建工厂，传 `nil` 恢复默认 |
| 预加载器 | `+setPreloader:` / `+preloader` | 自定义预加载器，传 `nil` 恢复默认 |
| 清除缓存 | `+clearCaches` | 清除播放器本地媒体缓存（需在 `setup` 之后调用） |
| 语言设置 | `+setLanguageCode:` | 手动指定语言代码（`zh-Hans` / `en`） |
| 自定义翻译 | `+setLocaleProvider:` | 注入自定义本地化 Provider |
| 跟随系统语言 | `+resetLocaleToSystemLanguage` | 恢复跟随系统首选语言 |
| 当前语言 | `+currentLanguageCode` | 获取当前生效的语言代码 |
| 版本信息 | `+getPlayerKitVersion` / `+getSdkVersion` | 获取 AliPlayerKit / 底层 SDK 版本号 |

### **4.2 AliPlayerModel 实例配置**

通过 `AliPlayerModel` 属性设置的实例级配置项：

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `videoSource` | `VideoSource *` | — | 必填，播放视频数据源（`readonly`，通过 `initWithVideoSource:` 设置） |
| `sceneType` | `SceneType` | `SceneTypeVOD` | 播放场景，影响插槽 UI 和手势行为 |
| `coverUrl` | `NSString *` | `nil` | 视频封面图 URL |
| `videoTitle` | `NSString *` | `nil` | 显示在 TopBar 的标题 |
| `autoPlay` | `BOOL` | `YES` | 配置完成后是否自动开始播放 |
| `traceId` | `NSString *` | `nil` | 播放质量监控标识（业务方的唯一标识） |
| `startTime` | `NSInteger` | `0` | 播放起始位置（毫秒），负数自动修正为 0 |
| `hardwareDecode` | `BOOL` | `YES` | 是否启用硬件解码 |
| `allowScreenSleep` | `BOOL` | `NO` | 播放时是否允许屏幕休眠 |
| `disableScreenshot` | `BOOL` | `NO` | iOS 特有，禁止截屏/录屏 |
| `onPlayerConfigBlock` | `void (^)(id<MediaPlayer>)` | `nil` | 实例级自定义配置回调 |

### **4.3 AliPlayerController 运行时配置**

通过 `AliPlayerController` 方法在运行时动态调整的配置：

| 方法 / 属性 | 类型 | 说明 |
|------------|------|------|
| `-setRate:` | `float` | 播放速度（1.0 正常，0.5 半速，2.0 倍速） |
| `-setLoop:` | `BOOL` | 是否循环播放 |
| `-setMuted:` | `BOOL` | 是否静音 |
| `-setMirrorMode:` | `MirrorMode` | 镜像模式（`None` / `Horizontal` / `Vertical`） |
| `-setScaleMode:` | `ScaleMode` | 缩放模式（`FitXY` / `FitCenter` / `CenterCrop`） |
| `-setRotateMode:` | `RotateMode` | 旋转角度（`0` / `90` / `180` / `270` 度） |
| `-setControlsVisible:` | `BOOL` | 显示/隐藏控制栏 |
| `controlsVisibilityLocked` | `BOOL` | 控制栏可见性锁定（`YES` 时 `setControlsVisible:NO` 被忽略） |
| `-setFullscreen:` | `BOOL` | 进入/退出全屏（默认带动画） |
| `-setFullscreen:animated:` | `BOOL, BOOL` | 进入/退出全屏（可控制动画） |
| `-selectTrack:` | `TrackQuality *` | 切换清晰度 |
| `-snapshot` | — | 截取当前视频画面 |
| `-toggle` | — | 切换播放/暂停状态 |
| `-replay` | — | 从头重新播放 |
| `-stop` | — | 停止播放 |
| `autoLifecycleManagement` | `BOOL` | 自动管理前后台暂停/恢复（默认 `YES`） |

---

## **5. 配置优先级**

### **5.1 优先级规则**

当同一配置项在不同层级都有设置时，按以下优先级生效：

```text
实例配置（onPlayerConfigBlock） > AliPlayerModel 属性 > 全局配置 > SDK 默认值
```

### **5.2 配置生效范围**

| 层级 | 生效范围 | 生命周期 |
|------|---------|---------|
| 全局配置 | 所有播放器实例 | 应用级（仅执行一次） |
| Model 属性 | 单个播放器实例 | 单次 `configure:` 调用 |
| 实例配置回调 | 单个播放器实例 | 每次 `configure:` 时触发 |
| Controller 方法 | 单个播放器实例 | 运行时动态生效 |

---

## **6. 完整配置示例**

### **6.1 综合示例**

```objc
// ===== 全局配置（AppDelegate 中，仅一次）=====
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 全局自定义配置
    [AliPlayerKit setOnGlobalInitBlock:^{
        // 启用 HTTP/2 多路复用
        [AliPlayerFactory setOption:ALLOW_H2_MULTIPLEX value:1];
    }];

    // 初始化
    [AliPlayerKit setup];

    // 全局内置配置（需在 setup 之后调用）
    [AliPlayerKit setLogLevel:LogLevelWarn];
    [AliPlayerKit enableConsoleLog:YES];

    return YES;
}

// ===== 实例配置（播放页中，每次播放）=====
- (void)startPlayback {
    VideoSource *source = [VideoSource urlSourceWithUrl:videoUrl];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

    // Model 属性配置
    model.sceneType = SceneTypeVOD;
    model.videoTitle = @"精彩视频";
    model.coverUrl = coverImageUrl;
    model.autoPlay = YES;
    model.hardwareDecode = YES;
    model.startTime = resumePosition; // 断点续播

    // 实例级自定义配置（底层 SDK）
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

> **注意**：`setLogLevel:` 和 `enableConsoleLog:` 等日志配置需在 `setup` 之后调用，因为它们操作的是 `LogHub` 单例实例。

---

## **7. API 速查**

### **7.1 全局配置 API**

| 方法 | 说明 |
|------|------|
| `+[AliPlayerKit setOnGlobalInitBlock:]` | 注册全局配置回调，传 `nil` 取消 |
| `+[AliPlayerKit setup]` | 触发初始化，执行回调 |

### **7.2 实例配置 API**

| 类 | 属性 | 说明 |
|----|------|------|
| `AliPlayerModel` | `onPlayerConfigBlock` | 实例级配置回调（`void (^)(id<MediaPlayer>)`） |

### **7.3 相关文件**

| 文件 | 说明 |
|------|------|
| `PlayerKit/Source/AliPlayerKit.h` | 全局配置 API（`OnGlobalInitBlock` typedef） |
| `PlayerKit/Source/AliPlayerModel.h` | 实例配置入口（`onPlayerConfigBlock`） |
| `PlayerKit/Source/AliPlayerController.h` | 运行时配置方法 |
| `PlayerKit/Source/Player/MediaPlayer.h` | 底层播放器协议（回调参数类型） |

> 完整 API 详见 [API 参考](../ApiReference.md)。

---

## **8. 常见问题**

### **8.1 全局配置和实例配置的执行顺序是什么？**

全局配置在应用启动时（`+setup` 内）执行一次；实例配置在每次 `configure:` 时的 `prepare` 前执行。两者互不干扰。

### **8.2 如果不设置自定义配置会怎样？**

AliPlayerKit 已内置最佳实践配置，不设置任何自定义配置即可正常使用，适合大多数场景。

### **8.3 实例配置回调中可以做异步操作吗？**

不建议。回调是同步执行的，完成后才会继续执行 `prepare`。如果在回调中执行耗时操作，会阻塞播放器的启动流程。

### **8.4 可以在实例配置中修改视频源吗？**

不建议。视频源在回调前已通过 `setDataSource:` 设置完成，在回调中修改可能导致不可预期的行为。实例配置回调应仅用于设置播放参数（如缓冲策略、Referer 等）。

### **8.5 `setOnGlobalInitBlock:` 在 `+setup` 之后调用会怎样？**

不会生效。`+setup` 使用 `dispatch_once` 保证只执行一次，如果 Block 在 `+setup` 之后设置，将永远不会被触发。

### **8.6 日志配置应该在 setup 之前还是之后？**

`setLogLevel:` 和 `enableConsoleLog:` 需在 `+setup` **之后**调用，因为它们直接操作 `LogHub` 单例。而 `setOnGlobalInitBlock:` 必须在 `+setup` **之前**设置。
