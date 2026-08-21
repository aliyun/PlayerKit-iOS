> 📚 **推荐阅读路径**
>
> [核心能力](./CoreFeatures.md) → [集成准备](./Integration.md) → [快速开始](./QuickStart.md) → **API 参考**

---

# **AliPlayerKit API 参考**

AliPlayerKit 提供了丰富的 API 接口，方便开发者直接控制播放器的行为。本文档提供 AliPlayerKit iOS 版本主要接口的详细说明。

> 🤖 **AI 友好提示**
>
> AliPlayerKit 为所有核心 API（包括类和方法）提供了完善的代码注释。在 Xcode 中，可通过 Quick Help（Option + Click）查看相关说明，从而提升开发效率；同时，也使 API 对 AI 编程工具更加友好。

---

## **1. 核心类概览**

| 类名 | 类型 | 职责 | 生命周期 |
|------|------|------|----------|
| `AliPlayerKit` | 全局入口 | SDK 初始化、全局配置、工厂/预加载器管理 | App 生命周期 |
| `AliPlayerView` | 视图容器 | 播放器视图管理、插槽系统宿主 | 与 UIView 一致 |
| `AliPlayerController` | 播放控制器 | 播放控制、状态管理、策略协调 | 手动 destroy 释放 |
| `AliPlayerModel` | 数据模型 | 封装视频源和播放参数 | 值对象，无独立生命周期 |
| `PlayerStateStore` | 状态存储 | 只读访问播放器当前状态 | 跟随 Controller |
| `PlayerViewState` | 视图状态 | 只读访问 UI 层状态（全屏、控制栏可见性） | 跟随 AliPlayerView |
| `SlotManager` | 插槽管理器 | 插槽注册、可见性控制、元素级管理 | 跟随 AliPlayerView |
| `StrategyManager` | 策略管理器 | 策略注册/启停/重置 | 跟随 Controller |
| `StrategyRegistry` | 策略注册表 | 全局默认策略工厂管理（单例） | App 生命周期 |
| `LogHub` | 日志中心 | 日志输出与观察者管理（单例） | App 生命周期 |
| `LocaleManager` | 本地化管理 | 多语言支持与 Provider 注入（单例） | App 生命周期 |

---

## **2. AliPlayerKit（全局 API）**

`AliPlayerKit` 是全局设置类，提供 SDK 初始化和全局配置能力。此类不可实例化，所有方法均为类方法。

### **2.1 初始化方法**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)setup` | - | `void` | 初始化 SDK，内部 dispatch_once 保证幂等，建议在 App 启动时调用 |
| `+ (BOOL)isInitialized` | - | `BOOL` | 查询是否已成功初始化 |
| `+ (void)setOnGlobalInitBlock:` | `OnGlobalInitBlock` block | `void` | 设置全局初始化完成后的自定义配置回调，必须在 setup 之前调用 |

### **2.2 状态查询与版本信息**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (NSString *)getPlayerKitVersion` | - | `NSString *` | 获取 PlayerKit 版本号 |
| `+ (NSString *)getSdkVersion` | - | `NSString *` | 获取底层 AliPlayer SDK 版本号 |

### **2.3 调试配置**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)setDebugModeEnabled:` | `BOOL` enabled | `void` | 设置调试模式开关 |
| `+ (BOOL)isDebugModeEnabled` | - | `BOOL` | 查询调试模式是否开启 |
| `+ (void)setLogPanelEnabled:` | `BOOL` enabled | `void` | 设置日志面板开关（仅调试场景启用） |
| `+ (BOOL)isLogPanelEnabled` | - | `BOOL` | 查询日志面板是否启用 |

### **2.4 日志配置**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)setLogLevel:` | `LogLevel` level | `void` | 设置日志级别，低于该级别的日志被忽略（默认 Info） |
| `+ (LogLevel)logLevel` | - | `LogLevel` | 获取当前日志级别 |
| `+ (void)enableConsoleLog:` | `BOOL` enable | `void` | 启用/禁用控制台日志输出 |
| `+ (BOOL)isConsoleLogEnabled` | - | `BOOL` | 查询控制台日志是否开启 |

### **2.5 播放器工厂**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)setPlayerFactory:` | `id<PlayerFactory>` factory | `void` | 设置自定义播放器工厂，传 nil 恢复默认 |
| `+ (id<PlayerFactory>)playerFactory` | - | `id<PlayerFactory>` | 获取当前播放器工厂 |

### **2.6 预加载**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)setPreloader:` | `id<PlayerPreloader>` preloader | `void` | 设置自定义预加载器，传 nil 恢复默认 |
| `+ (id<PlayerPreloader>)preloader` | - | `id<PlayerPreloader>` | 获取当前预加载器 |

### **2.7 缓存管理**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)clearCaches` | - | `void` | 清除播放器本地媒体缓存，需在 setup 之后调用 |

### **2.8 国际化**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ (void)setLanguageCode:` | `NSString *` languageCode | `void` | 手动指定语言（支持 `zh-Hans`、`en`） |
| `+ (void)setLocaleProvider:` | `id<LocaleProvider>` provider | `void` | 注入自定义本地化 Provider（优先级最高） |
| `+ (void)resetLocaleToSystemLanguage` | - | `void` | 重置为跟随系统语言 |
| `+ (NSString *)currentLanguageCode` | - | `NSString *` | 获取当前生效的语言代码 |

---

## **3. AliPlayerView（视图 API）**

`AliPlayerView` 是播放器视图容器，负责管理控制器绑定和插槽系统。渲染视图由内部 `PlayerSurfaceSlot` 创建并管理。

### **3.1 属性**

| 属性 | 类型 | 说明 |
|------|------|------|
| `controller` | `AliPlayerController *`（weak, readonly） | 关联的播放器控制器 |
| `viewState` | `PlayerViewState *`（readonly） | 跨视频保留的 UI 状态（全屏、控制栏可见性） |
| `slotManager` | `SlotManager *`（readonly） | 插槽管理器，可在 attach 前预配置 |
| `fullscreenTransition` | `id<FullscreenTransition>` | 全屏过渡动画实现，默认使用独立 Window 旋转方案 |
| `onBackPressed` | `void (^)(void)`（nullable） | 返回键事件回调 |

> **说明**：`onBackPressed` 在非全屏状态下触发（全屏下返回操作由播放器内部自动处理，退出全屏）。若未设置此回调，播放器将通过 responder chain 尝试默认导航行为（pop / dismiss）。

### **3.2 控制器绑定**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (void)attach:` | `AliPlayerController *` controller | `void` | 绑定控制器并激活插槽系统 |
| `- (void)detach` | - | `void` | 解绑控制器，不销毁 controller |

**调用时机**：

- `attach:` — 在 controller 已调用 `configure:` 后绑定，插槽系统根据 slotManager 配置自动构建
- `detach` — 视图即将销毁或需换绑控制器时调用

---

## **4. AliPlayerController（控制器 API）**

`AliPlayerController` 是播放控制器，作为播放操作的统一入口，封装播放器的创建、配置和控制逻辑。

### **4.1 属性**

| 属性 | 类型 | 说明 |
|------|------|------|
| `playerModel` | `AliPlayerModel *`（readonly, nullable） | 当前播放配置模型 |
| `playerState` | `PlayerState`（readonly） | 当前播放器状态 |
| `currentPosition` | `NSInteger`（readonly） | 当前播放位置（毫秒） |
| `duration` | `NSInteger`（readonly） | 视频总时长（毫秒） |
| `stateStore` | `PlayerStateStore *`（readonly） | 状态存储 |
| `strategyManager` | `StrategyManager *`（readonly） | 策略管理器 |
| `lifecycleStrategy` | `id<PlayerLifecycleStrategy>`（readonly） | 当前生命周期策略 |
| `autoLifecycleManagement` | `BOOL` | 是否自动管理前后台生命周期（默认 YES） |
| `controlsVisibilityLocked` | `BOOL` | 控制栏可见性锁定标志 |

> **说明**：`controlsVisibilityLocked` 设为 `YES` 时，`setControlsVisible:NO` 请求会被忽略，控制栏持续保持可见状态。用于进度条拖动等需要操作栏始终显示的交互场景。

### **4.2 构造方法**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- (instancetype)init` | - | 使用默认生命周期策略创建控制器 |
| `- (instancetype)initWithLifecycleStrategy:` | `id<PlayerLifecycleStrategy>` strategy | 使用自定义生命周期策略创建控制器 |

### **4.3 配置与播放控制**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (void)configure:` | `AliPlayerModel *` model | `void` | 配置播放器并准备播放 |
| `- (void)play` | - | `void` | 开始或恢复播放 |
| `- (void)pause` | - | `void` | 暂停播放 |
| `- (void)toggle` | - | `void` | 切换播放/暂停状态 |
| `- (void)replay` | - | `void` | 从头重新播放 |
| `- (void)stop` | - | `void` | 停止播放 |
| `- (void)seekTo:` | `NSInteger` position（毫秒） | `void` | 跳转到指定位置 |
| `- (void)setRate:` | `float` rate | `void` | 设置播放速度（1.0 正常） |
| `- (void)setLoop:` | `BOOL` loop | `void` | 设置是否循环播放 |
| `- (void)setMuted:` | `BOOL` muted | `void` | 设置是否静音 |
| `- (void)setMirrorMode:` | `MirrorMode` mirrorMode | `void` | 设置镜像模式 |
| `- (void)setScaleMode:` | `ScaleMode` scaleMode | `void` | 设置缩放模式 |
| `- (void)setRotateMode:` | `RotateMode` rotateMode | `void` | 设置旋转角度 |
| `- (void)selectTrack:` | `TrackQuality *` quality | `void` | 切换清晰度 |
| `- (void)snapshot` | - | `void` | 截取当前视频画面 |
| `- (void)setThumbnailUrl:` | `NSString *` url | `void` | 动态设置缩略图 URL（仅支持 VTT 雪碧图格式） |
| `- (void)requestThumbnailAtPosition:` | `int64_t` positionMs（毫秒） | `void` | 请求指定位置的缩略图 |

### **4.4 UI 控制**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (void)setControlsVisible:` | `BOOL` visible | `void` | 设置控制栏可见性 |
| `- (void)setFullscreen:` | `BOOL` fullscreen | `void` | 设置全屏模式（带动画） |
| `- (void)setFullscreen:animated:` | `BOOL` fullscreen, `BOOL` animated | `void` | 设置全屏模式（可选动画） |

### **4.5 生命周期方法**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (void)onResume` | - | `void` | 恢复播放（从后台回到前台时调用） |
| `- (void)onPause` | - | `void` | 暂停播放（进入后台时调用） |
| `- (void)destroy` | - | `void` | 销毁播放器，释放所有资源 |

### **4.6 通知代理**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (void)addNotificationDelegate:` | `id<PlayerNotificationDelegate>` delegate | `void` | 添加通知代理（弱引用持有） |
| `- (void)removeNotificationDelegate:` | `id<PlayerNotificationDelegate>` delegate | `void` | 移除通知代理 |

---

## **5. AliPlayerModel（模型 API）**

`AliPlayerModel` 是播放器配置模型，封装播放所需的全部配置信息。

### **5.1 属性**

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `videoSource` | `VideoSource *`（readonly） | - | 视频数据源（必填） |
| `sceneType` | `SceneType` | `SceneTypeVOD` | 播放场景类型 |
| `coverUrl` | `NSString *`（nullable） | `nil` | 封面图 URL。Vid 播放时可从 MediaInfo 自动获取 |
| `thumbnailUrl` | `NSString *`（nullable） | `nil` | 缩略图 URL（Seek 预览用）。Vid 播放时 SDK 自动获取，URL 播放时需手动设置 |
| `videoTitle` | `NSString *`（nullable） | `nil` | 视频标题。Vid 播放时可从 MediaInfo 自动获取 |
| `autoPlay` | `BOOL` | `YES` | 是否自动播放 |
| `traceId` | `NSString *`（nullable） | `nil` | 跟踪标识符（用于播放质量监控） |
| `startTime` | `NSInteger` | `0` | 起播位置（毫秒） |
| `hardwareDecode` | `BOOL` | `YES` | 是否启用硬件解码 |
| `allowScreenSleep` | `BOOL` | `NO` | 是否允许屏幕休眠 |
| `disableScreenshot` | `BOOL` | `NO` | 是否禁止截屏/录屏（iOS 特有） |
| `onPlayerConfigBlock` | `void (^)(id<MediaPlayer>)` | `nil` | 实例级自定义配置回调 |
| `chapters` | `NSArray<ChapterInfo *> *`（nullable） | `nil` | 章节信息列表（仅 SceneTypeAIVod 场景有效） |

### **5.2 创建方法**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (instancetype)initWithVideoSource:` | `VideoSource *` videoSource | `AliPlayerModel *` | 通过视频源创建模型（指定初始化方法） |

---

## **6. 通知系统**

AliPlayerKit 采用 **Dispatcher + Delegate** 模式实现组件间的事件通信。每个 `AliPlayerController` 持有独立的 Dispatcher 实例，不同播放器实例的事件互不干扰。所有回调均在主线程派发。

iOS 端通过三组独立的通知协议实现分类事件分发：

| 通知协议 | 职责 | 典型事件 |
|---------|------|---------|
| `PlayerNotificationDelegate` | 播放器状态与播放事件 | 状态变化、进度更新、首帧渲染、错误、全屏切换 |
| `GestureNotificationDelegate` | 手势交互事件 | 单击、长按倍速、亮度/音量拖拽 |
| `SlotActionNotificationDelegate` | 插槽间操作事件 | 设置菜单切换、倍速面板/画质面板显示 |

### **6.1 PlayerNotificationDelegate（播放器通知代理）**

播放器状态变化回调协议，所有方法均为 `@optional`。

**播放状态**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidChangeState:` | `PlayerState` state | 播放器状态变化 |
| `- playerDidPreparedWithDuration:` | `NSInteger` duration（毫秒） | 准备完成，可开始播放 |
| `- playerDidRenderFirstFrame` | - | 首帧渲染完成 |
| `- playerDidCompletion` | - | 播放到达末尾 |

**播放进度**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidUpdateCurrentPosition:duration:bufferedPosition:` | position, duration, bufferedPosition（毫秒） | 定期报告播放进度 |

**错误与截图**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidEncounterError:` | `NSError *` error | 播放错误 |
| `- playerDidCompleteSnapshot:` | `UIImage *`（nullable） | 截图完成 |

**视频信息**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidChangeVideoWidth:height:` | `NSInteger` width, height | 视频尺寸变化 |

**UI 状态**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidChangeFullscreen:` | `BOOL` isFullscreen | 全屏状态变化 |
| `- playerDidChangeControlsVisible:` | `BOOL` visible | 控制栏可见性变化 |

**加载状态**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidLoadingBegin` | - | 开始缓冲加载 |
| `- playerDidLoadingEnd` | - | 缓冲加载结束 |
| `- playerDidUpdateLoadingProgress:` | `float` progress（0-100） | 缓冲进度更新 |

**显示模式**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidChangeMirrorMode:` | `MirrorMode` mirrorMode | 镜像模式变化 |
| `- playerDidChangeScaleMode:` | `ScaleMode` scaleMode | 缩放模式变化 |
| `- playerDidChangeRotateMode:` | `RotateMode` rotateMode | 旋转模式变化 |

**轨道**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidTrackReady:` | `NSArray<TrackQuality *> *` tracks | 可用轨道信息就绪 |
| `- playerDidTrackChanged:` | `TrackQuality *` quality | 轨道切换完成 |

**VID 媒体信息就绪**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidReadyCoverUrl:` | `NSString *` coverUrl | 封面图 URL 就绪（Vid 播放时从 MediaInfo 自动提取） |
| `- playerDidReadyVideoTitle:` | `NSString *` videoTitle | 视频标题就绪（Vid 播放时从 MediaInfo 自动提取） |
| `- playerDidReadyThumbnailUrl:` | `NSString *` thumbnailUrl | 缩略图 URL 就绪（Vid 播放时从 MediaInfo 自动提取） |

**缩略图**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- playerDidRetrieveThumbnail:image:` | `int64_t` positionMs, `UIImage *` image | 缩略图获取成功 |

### **6.2 GestureNotificationDelegate（手势通知代理）**

手势交互事件回调协议，所有方法均为 `@optional`。由 `GestureNotificationDispatcher` 多播分发。

**单击**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- gestureDidSingleTap` | - | 单击手势触发（通常用于切换控制栏显隐） |

**长按（倍速）**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- gestureDidBeginLongPress` | - | 长按开始（倍速播放激活） |
| `- gestureDidEndLongPress` | - | 长按结束（倍速播放恢复） |

**亮度（左侧垂直拖动）**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- gestureDidUpdateBrightnessWithPercent:` | `CGFloat` currentPercent（0.0~1.0） | 亮度调节中 |
| `- gestureDidEndBrightnessAdjust` | - | 亮度调节结束 |

**音量（右侧垂直拖动）**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- gestureDidUpdateVolumeWithPercent:` | `CGFloat` currentPercent（0.0~1.0） | 音量调节中 |
| `- gestureDidEndVolumeAdjust` | - | 音量调节结束 |

### **6.3 SlotActionNotificationDelegate（插槽操作通知代理）**

插槽间操作事件通知协议，用于解耦插槽之间的直接方法调用。所有方法均为 `@optional`，异步派发到主线程。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- slotDidRequestToggleSettingMenu` | - | 请求切换设置菜单显隐（通常由 TopBarSlot 触发） |
| `- slotDidRequestShowSpeedPanel` | - | 请求显示倍速选择面板（通常由 BottomBarSlot 触发） |
| `- slotDidRequestShowQualityPanel` | - | 请求显示画质选择面板（通常由 BottomBarSlot 触发） |
| `- slotDidBeginSeekPreview` | - | 用户开始拖动进度条（BottomBarSlot 触发） |
| `- slotDidUpdateSeekPreview:duration:` | `int64_t` targetPositionMs, `int64_t` durationMs | 拖动期间目标位置变化 |
| `- slotDidEndSeekPreview` | - | 用户结束拖动进度条 |
| `- slotDidRequestShowChapterPanel` | - | 请求显示章节面板（BottomBarSlot 触发） |

---

## **7. 播放器协议**

### **7.1 MediaPlayer（播放器协议）**

定义播放器核心操作接口，通过 `PlayerFactory` 创建实例。

**属性**

| 属性 | 类型 | 说明 |
|------|------|------|
| `playerId` | `NSString *`（readonly） | 播放器唯一标识 |
| `state` | `PlayerState`（readonly） | 当前播放状态 |
| `currentPosition` | `NSInteger`（readonly） | 当前位置（毫秒） |
| `duration` | `NSInteger`（readonly） | 总时长（毫秒） |
| `speed` | `float`（readonly） | 当前播放速率 |
| `loop` | `BOOL`（readonly） | 是否循环 |
| `muted` | `BOOL`（readonly） | 是否静音 |
| `mirrorMode` | `MirrorMode`（readonly） | 当前镜像模式 |
| `scaleMode` | `ScaleMode`（readonly） | 当前缩放模式 |
| `rotateMode` | `RotateMode`（readonly） | 当前旋转角度 |
| `stateStore` | `PlayerStateStore *`（readonly） | 状态存储 |
| `playerView` | `UIView *`（nullable） | 播放器渲染视图，由生命周期策略在创建/回收时注入 |
| `notificationDispatcher` | `PlayerNotificationDispatcher *`（nullable） | 事件通知分发器 |

**播放控制**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- setDataSource:` | `AliPlayerModel *` model | 设置视频数据源 |
| `- prepare` | - | 异步准备播放器资源 |
| `- start` | - | 开始播放 |
| `- pause` | - | 暂停 |
| `- toggle` | - | 切换播放/暂停 |
| `- replay` | - | 从头重播 |
| `- seekTo:` | `NSInteger` position（毫秒） | 跳转到指定位置 |
| `- stop` | - | 停止 |
| `- destroy` | - | 销毁播放器，释放资源 |

**播放设置**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- setSpeed:` | `float` speed | 设置播放速率（0.5 ~ 2.0） |
| `- setLoop:` | `BOOL` loop | 设置循环播放 |
| `- setMuted:` | `BOOL` muted | 设置静音 |
| `- setMirrorMode:` | `MirrorMode` mode | 设置镜像模式 |
| `- setScaleMode:` | `ScaleMode` mode | 设置缩放模式 |
| `- setRotateMode:` | `RotateMode` mode | 设置旋转角度 |
| `- selectTrack:` | `TrackQuality *` quality | 切换清晰度 |
| `- snapshot` | - | 截取当前帧 |

### **7.2 PlayerLifecycleStrategy（生命周期策略协议）**

定义播放器实例的获取与回收行为。

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- setupWithFactory:` | `id<PlayerFactory>` factory | `void` | 注入播放器工厂（必须首先调用） |
| `- acquirePlayer` | - | `id<MediaPlayer>` | 获取播放器实例 |
| `- recyclePlayer:force:` | player, `BOOL` force | `void` | 回收播放器实例 |
| `- clear` | - | `void` | 释放所有缓存实例 |
| `- preloadWithCount:`（@optional） | `NSInteger` count | `void` | 预加载指定数量实例到池中 |
| `- acquirePlayerWithUniqueId:`（@optional） | `NSString *` uniqueId | `id<MediaPlayer>` | 按 ID 获取（IdScoped 策略专用） |
| `- recyclePlayer:uniqueId:force:`（@optional） | player, uniqueId, force | `void` | 按 ID 回收（IdScoped 策略专用） |

**内置策略实现**

| 策略类 | 行为 | 适用场景 |
|--------|------|----------|
| `DefaultLifecycleStrategy` | 每次新建，回收即销毁 | 普通视频播放 |
| `SingletonLifecycleStrategy` | 全局唯一实例（`sharedInstance` 单例） | 列表播放、内存敏感场景 |
| `ReusePoolLifecycleStrategy` | LIFO 复用池 | 短视频列表 |
| `IdScopedPoolLifecycleStrategy` | ID 绑定 + LRU 淘汰 | 视频预加载 |

### **7.3 FullscreenTransition（全屏过渡协议）**

定义播放器视图进入/退出全屏的过渡行为。

| 方法 / 属性 | 参数 | 说明 |
|------------|------|------|
| `- enterFullscreenWithPlayerView:animated:completion:` | playerView, animated, completion | 进入全屏 |
| `- exitFullscreenWithPlayerView:animated:completion:` | playerView, animated, completion | 退出全屏 |
| `isInFullscreen`（readonly） | - | 当前是否处于全屏状态 |

默认实现 `DefaultFullscreenTransition` 采用独立 Window 旋转方案。可通过 `playerView.fullscreenTransition` 注入自定义实现。

---

## **8. 插槽系统**

### **8.1 SlotProtocol（插槽协议）**

定义插槽生命周期回调。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- onAttach:` | `id<SlotHost>` host | 插槽挂载到宿主 |
| `- onDetach` | - | 插槽从宿主分离 |
| `- onBindData:` | `AliPlayerModel *` model | 播放数据绑定 |
| `- onUnbindData` | - | 播放数据解绑 |

### **8.2 BaseSlot（插槽基类）**

所有内置插槽的抽象基类（`UIView` 子类），实现 `SlotProtocol` 协议并提供通用能力。

| 属性 / 方法 | 类型 | 说明 |
|------------|------|------|
| `host` | `id<SlotHost>`（weak, readonly） | 所附属的宿主 |
| `slotType` | `SlotType` | 插槽类型标识（由 SlotHostLayout 注入） |
| `safeAreaEdges` | `SlotSafeAreaEdge` | 需要避让的安全区域边缘（默认 All） |
| `deferContentCreation` | `BOOL` | 延迟内容创建开关 |
| `contentReady` | `BOOL`（readonly） | 内容是否已就绪 |
| `touchPassthrough` | `BOOL` | 触摸穿透开关（默认 YES） |
| `- setupContentView` | - | 子类重写以添加自定义 UI 元素 |
| `- show` / `- hide` | - | 显示/隐藏插槽 |
| `- showWithAnimation:` / `- hideWithAnimation:` | `BOOL` animated | 带动画的显示/隐藏 |
| `- isShowing` | - | 返回当前是否可见 |
| `- dismiss` | - | 通过宿主正确移除插槽 |
| `- onRegisterElements` | - | 子类重写声明默认可见元素的位掩码 |
| `- isElementVisible:` | `NSUInteger` element | 查询指定元素的最终可见性 |
| `- currentSceneType` | - | 安全读取当前场景类型 |
| `- ensureContentReady` | - | 确保延迟创建的内容已就绪 |

### **8.3 SlotManager（插槽管理器）**

`SlotManager` 是插槽系统的统一管理入口，通过 `AliPlayerView.slotManager` 获取。

**注册方法**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- registerSlotType:provider:` | type, `SlotProvider` block | 注册/替换插槽 Provider |
| `- unregisterSlotType:` | `SlotType` type | 注销插槽 Provider |
| `- isRegistered:` | `SlotType` type | 检查是否已注册 |
| `- registerCustomSlotType:provider:` | `CustomSlotType *` type, provider | 注册自定义插槽 |
| `- unregisterCustomSlotType:` | `CustomSlotType *` type | 注销自定义插槽 |
| `- isCustomSlotRegistered:` | `CustomSlotType *` type | 检查自定义插槽是否已注册 |
| `- customSlotTypes` | - | 获取所有已注册的自定义插槽类型 |

**插槽可见性**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- hideSlot:` | `SlotType` type | 隐藏整个插槽 |
| `- showSlot:` | `SlotType` type | 显示已隐藏的插槽 |
| `- isSlotHidden:` | `SlotType` type | 检查插槽是否隐藏 |

**场景可见性配置**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- registerSlotConfig:` | `SlotConfig *` config | `void` | 为插槽类型注册场景可见性配置（同类型已存在配置会被替换） |
| `- unregisterSlotConfigForType:` | `SlotType` slotType | `void` | 移除指定插槽类型的场景可见性配置，移除后该插槽在所有场景下默认可见（仅受 `hideSlot:` 控制） |
| `- slotConfigForType:` | `SlotType` type | `nullable SlotConfig *` | 获取指定插槽类型的场景可见性配置，未配置返回 nil |

**元素级可见性**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- hideElements:forSlot:` | `NSUInteger` mask, `SlotType` type | 隐藏插槽内特定元素（位掩码） |
| `- showElements:forSlot:` | `NSUInteger` mask, `SlotType` type | 显示之前隐藏的元素 |
| `- setHiddenElementMask:forSlot:` | `NSUInteger` mask, `SlotType` type | 替换隐藏元素掩码（覆盖式） |
| `- hiddenElementMaskForSlot:` | `SlotType` type | 获取指定插槽的隐藏元素位掩码，无配置返回 0 |
| `- shownElementMaskForSlot:` | `SlotType` type | 获取指定插槽的显示元素位掩码，无配置返回 0 |
| `- setAllHiddenElementMasks:` | `NSDictionary *` config | 批量设置所有隐藏元素 |
| `- clearAllElementMasks` | - | 清空所有元素可见性配置 |

**运行时访问**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- slotViewForType:` | `SlotType` type | `UIView<SlotProtocol> *` | 获取已挂载的插槽视图 |
| `- rebuildSlots` | - | `void` | 重建所有插槽 |
| `- clearAll` | - | `void` | 重置到初始状态 |

### **8.4 SlotType（插槽类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `SlotTypePlayerSurface` | 10 | 播放器渲染视图层（最底层） |
| `SlotTypeGestureControl` | 20 | 手势识别和控制层 |
| `SlotTypeLandscapeHint` | 30 | 横屏提示层 |
| `SlotTypeCover` | 40 | 视频封面图层 |
| `SlotTypeCenterDisplay` | 50 | 中心展示层（倍速/亮度/音量） |
| `SlotTypePlayState` | 60 | 播放状态指示层（加载/错误/完成） |
| `SlotTypeLogPanel` | 70 | 日志面板层 |
| `SlotTypeTopBar` | 80 | 顶部导航栏层 |
| `SlotTypeSeekThumbnail` | 85 | 拖动预览缩略图层 |
| `SlotTypeBottomBar` | 90 | 底部控制栏层 |
| `SlotTypeSettingMenu` | 100 | 设置菜单层 |
| `SlotTypeOptionPanel` | 110 | 选项面板层（倍速/清晰度） |
| `SlotTypeChapterPanel` | 115 | 章节面板层 |

### **8.5 CustomSlotType（自定义插槽类型）**

用于在内置插槽之间插入业务自定义插槽。内置 `SlotType` 枚举值按间隔 10 排列（10, 20, ...110），`CustomSlotType` 通过 `order` 字段指定插入位置。

| 属性 / 方法 | 说明 |
|------------|------|
| `key`（readonly） | 唯一标识，用于注册、查找和相等判断 |
| `order`（readonly） | 排序值，决定插槽在 Z 轴上的位置（值越小越靠下） |
| `+ typeWithKey:order:` | 创建自定义插槽类型实例 |

```objc
// 在 TopBar(80) 和 BottomBar(90) 之间插入自定义插槽
CustomSlotType *type = [CustomSlotType typeWithKey:@"myCustomSlot" order:85];
[playerView.slotManager registerCustomSlotType:type provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomSlotView alloc] initWithFrame:parentView.bounds];
}];
```

### **8.6 SlotElements（插槽元素位掩码）**

配合 `SlotManager` 的 `hideElements:forSlot:` / `showElements:forSlot:` 方法使用，实现对插槽内单个 UI 元素的细粒度可见性控制。

**TopBarElement（顶部栏元素）**

| 常量 | 位 | 说明 |
|------|---|------|
| `TopBarElementBack` | 1 << 0 | 返回按钮 |
| `TopBarElementTitle` | 1 << 1 | 标题文本 |
| `TopBarElementDownload` | 1 << 2 | 下载按钮 |
| `TopBarElementSnapshot` | 1 << 3 | 截图按钮 |
| `TopBarElementSettings` | 1 << 4 | 设置按钮 |

**BottomBarElement（底部栏元素）**

| 常量 | 位 | 说明 |
|------|---|------|
| `BottomBarElementPlay` | 1 << 0 | 播放/暂停按钮 |
| `BottomBarElementProgress` | 1 << 1 | 进度条 |
| `BottomBarElementRefresh` | 1 << 2 | 刷新按钮 |
| `BottomBarElementSpeed` | 1 << 3 | 倍速按钮（仅横屏布局可见） |

**SettingMenuElement（设置菜单元素）**

| 常量 | 位 | 说明 |
|------|---|------|
| `SettingMenuElementSpeed` | 1 << 0 | 倍速选项 |
| `SettingMenuElementTrackInfo` | 1 << 1 | 清晰度信息 |
| `SettingMenuElementLoop` | 1 << 2 | 循环播放 |
| `SettingMenuElementMute` | 1 << 3 | 静音 |
| `SettingMenuElementMirrorMode` | 1 << 4 | 镜像模式 |
| `SettingMenuElementRotateMode` | 1 << 5 | 旋转模式 |
| `SettingMenuElementScaleMode` | 1 << 6 | 缩放模式 |
| `SettingMenuElementSubtitle` | 1 << 7 | 字幕 |

**CenterDisplayElement（中心展示层元素）**

| 常量 | 位 | 说明 |
|------|---|------|
| `CenterDisplayElementVolume` | 1 << 0 | 音量提示 |
| `CenterDisplayElementBrightness` | 1 << 1 | 亮度提示 |
| `CenterDisplayElementSpeed` | 1 << 2 | 倍速提示 |

**GestureElement（手势控制元素）**

> **说明**：这些常量控制手势交互的启用/禁用，而非 UI 元素的显隐。当某个手势位被设置为隐藏时，该手势将被禁用。

| 常量 | 位 | 说明 |
|------|---|------|
| `GestureElementSingleTap` | 1 << 0 | 单击手势 |
| `GestureElementDoubleTap` | 1 << 1 | 双击手势 |
| `GestureElementLongPress` | 1 << 2 | 长按手势 |
| `GestureElementHorizontalDrag` | 1 << 3 | 水平拖动（进度） |
| `GestureElementLeftVerticalDrag` | 1 << 4 | 左侧垂直拖动（亮度） |
| `GestureElementRightVerticalDrag` | 1 << 5 | 右侧垂直拖动（音量） |

**PlayStateElement（播放状态层元素）**

| 常量 | 位 | 说明 |
|------|---|------|
| `PlayStateElementErrorMessage` | 1 << 0 | 错误提示信息 |
| `PlayStateElementLoadingMessage` | 1 << 1 | 加载提示信息 |

---

## **9. 状态存储**

### **9.1 PlayerStateStore**

`PlayerStateStore` 持有当前播放状态的只读快照，通过 `AliPlayerController.stateStore` 获取。

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `playState` | `PlayerState` | `PlayerStateIdle` | 当前播放状态 |
| `duration` | `NSInteger` | 0 | 总时长（毫秒） |
| `currentPosition` | `NSInteger` | 0 | 当前位置（毫秒） |
| `bufferedPosition` | `NSInteger` | 0 | 已缓冲位置（毫秒） |
| `speed` | `float` | 1.0 | 当前播放速度 |
| `loop` | `BOOL` | NO | 是否循环 |
| `muted` | `BOOL` | NO | 是否静音 |
| `mirrorMode` | `MirrorMode` | `MirrorModeNone` | 镜像模式 |
| `scaleMode` | `ScaleMode` | `ScaleModeCenterCrop` | 缩放模式 |
| `rotateMode` | `RotateMode` | `RotateModeDegree0` | 旋转角度 |
| `videoWidth` | `NSInteger` | 0 | 视频原始宽度 |
| `videoHeight` | `NSInteger` | 0 | 视频原始高度 |
| `trackQualityList` | `NSArray<TrackQuality *> *` | nil | 可用清晰度列表 |
| `selectedTrackQuality` | `TrackQuality *` | nil | 当前选中清晰度 |

### **9.2 PlayerViewState**

`PlayerViewState` 持有与 UI 层级相关的持久状态，通过 `AliPlayerView.viewState` 获取。跨视频切换保留，状态更新包含自动去重处理。

| 属性 / 方法 | 类型 | 默认值 | 说明 |
|------------|------|--------|------|
| `fullscreen` | `BOOL`（readonly） | `NO` | 是否处于全屏模式 |
| `controlsVisible` | `BOOL`（readonly） | `NO` | 控制栏是否可见 |
| `- reset` | - | - | 重置所有状态为默认值 |
| `- updateFullscreen:` | `BOOL` fullscreen | - | 更新全屏状态 |
| `- updateControlsVisible:` | `BOOL` controlsVisible | - | 更新控制栏可见性 |

---

## **10. 视频源**

### **10.1 VideoSource（视频源模型）**

| 属性 | 类型 | 说明 |
|------|------|------|
| `sourceType` | `VideoSourceType` | 视频源类型 |
| `uniqueId` | `NSString *`（nullable） | 唯一标识（VidAuth/VidSts 返回 vid，URL 返回 url） |
| `url` | `NSString *`（nullable） | 视频 URL（URL 类型有效） |
| `vid` | `NSString *`（nullable） | 视频 ID（VidAuth/VidSts 有效） |
| `playAuth` | `NSString *`（nullable） | 播放授权码（VidAuth 有效） |
| `accessKeyId` | `NSString *`（nullable） | STS AccessKeyId |
| `accessKeySecret` | `NSString *`（nullable） | STS AccessKeySecret |
| `securityToken` | `NSString *`（nullable） | STS SecurityToken |
| `region` | `NSString *`（nullable） | 区域标识 |

**工厂方法**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ vidAuthSourceWithVid:playAuth:` | vid, playAuth | `VideoSource *` | 创建 VidAuth 视频源（推荐） |
| `+ vidStsSourceWithVid:accessKeyId:accessKeySecret:securityToken:region:` | vid, keyId, secret, token, region | `VideoSource *` | 创建 VidSts 视频源 |
| `+ urlSourceWithUrl:` | url | `VideoSource *` | 创建 URL 视频源 |
| `- (BOOL)isValid` | - | `BOOL` | 验证配置是否有效 |

### **10.2 VideoSourceType（视频源类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `VideoSourceTypeVidAuth` | 0 | VID + PlayAuth 播放凭证（推荐） |
| `VideoSourceTypeVidSts` | 1 | VID + STS 临时凭证 |
| `VideoSourceTypeUrl` | 2 | URL 直接播放 |

---

## **11. 策略系统**

### **11.1 StrategyProtocol（策略协议）**

定义策略的生命周期契约。策略名称必须全局唯一。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- strategyName`（@required） | - | 策略唯一标识名称 |
| `- strategyDidStart:`（@required） | `StrategyContext *` context | 策略启动，绑定播放器上下文 |
| `- strategyDidStop`（@required） | - | 策略停止，解绑上下文 |
| `- strategyDidReset:`（@required） | `StrategyContext *` context | 策略重置（视频源切换时调用） |

### **11.2 StrategyContext（策略上下文）**

为策略提供只读的播放器环境信息，在策略启动时由 `StrategyManager` 创建并传入。

| 属性 | 类型 | 说明 |
|------|------|------|
| `controller` | `AliPlayerController *`（weak, readonly） | 关联的播放器控制器 |
| `playerModel` | `AliPlayerModel *`（readonly） | 当前播放配置模型 |
| `stateStore` | `PlayerStateStore *`（readonly, nullable） | 播放器状态存储 |

> **注意**：此对象在 `strategyDidStop` 后不再有效，不应继续使用。

### **11.3 BaseStrategy（策略基类）**

策略抽象基类，实现 `StrategyProtocol` 和 `PlayerNotificationDelegate`，自动处理播放器事件的订阅与取消订阅。

| 属性 / 方法 | 说明 |
|------------|------|
| `context`（readonly, nullable） | 当前策略上下文（仅在 start 和 stop 之间有效） |
| `- resetInternalState` | 子类重置内部状态的钩子方法（如清零计数器、定时器） |

**生命周期流转**：`strategyDidStart:` → 保存上下文 → 注册通知代理 → `strategyDidReset:` → 更新上下文 → 调用 `resetInternalState` → `strategyDidStop` → 注销通知代理 → 清空上下文

> **说明**：子类必须覆写 `strategyName` 方法。如果覆写 `strategyDidStart:` / `strategyDidStop` / `strategyDidReset:`，必须调用 `super`。

### **11.4 StrategyManager（策略管理器）**

每个 `AliPlayerController` 拥有一个 `StrategyManager` 实例。策略按注册顺序执行，每个策略的生命周期调用均通过 `@try/@catch` 隔离。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- registerStrategy:` | `id<StrategyProtocol>` strategy | 注册策略（同名策略会被停止并替换） |
| `- unregisterStrategyWithName:` | `NSString *` name | 按名称注销策略 |
| `- strategyWithName:` | `NSString *` name | 按名称查找策略 |
| `- startWithController:playerModel:` | controller, playerModel | 启动所有已注册的策略 |
| `- resetWithPlayerModel:` | `AliPlayerModel *` playerModel | 重置所有策略（视频源切换时） |
| `- stop` | - | 停止所有策略 |
| `- destroy` | - | 停止并移除所有策略 |

| 属性 | 类型 | 说明 |
|------|------|------|
| `strategyCount` | `NSUInteger`（readonly） | 当前已注册的策略数量 |
| `started` | `BOOL`（readonly） | 管理器是否已启动 |

### **11.5 StrategyRegistry（全局策略注册表）**

全局策略注册表（单例），维护一组策略工厂 Block。每当新的 `AliPlayerController` 创建时，通过 `applyToManager:` 将所有已注册的工厂实例化并注入到控制器的 `StrategyManager` 中。

| 方法 | 参数 | 说明 |
|------|------|------|
| `+ sharedRegistry` | - | 获取全局注册表单例 |
| `- addGlobalStrategyFactory:` | `StrategyFactory` factory | 添加全局策略工厂 |
| `- clearGlobalStrategies` | - | 移除所有全局策略工厂（包括内置策略） |
| `- applyToManager:` | `StrategyManager *` manager | 将所有全局策略实例化并注册到指定管理器 |
| `- resetToDefault` | - | 恢复为默认内置策略配置 |

> **说明**：内置策略（`FirstFrameStrategy`、`StutterDetectStrategy`、`TrafficProtectionStrategy`）在首次访问时自动注册。

### **11.6 内置策略**

**FirstFrameStrategy（首帧耗时监测）**

测量从播放器开始准备到首帧渲染的时间，分为准备阶段（Preparing → Prepared）和渲染阶段（Prepared → FirstFrameRendered）。

| 属性 | 类型 | 说明 |
|------|------|------|
| `delegate` | `id<FirstFrameStrategyDelegate>`（weak） | 回调代理 |

`FirstFrameStrategyDelegate` 回调：

| 方法 | 参数 | 说明 |
|------|------|------|
| `- firstFrameStrategy:didRenderFirstFrameWithPrepareTime:renderTime:totalTime:` | strategy, prepareTimeMs, renderTimeMs, totalTimeMs | 首帧渲染完成 |

**StutterDetectStrategy（卡顿检测）**

通过监听 Loading 事件检测卡顿（首帧渲染前的 Loading 不计入统计）。

| 属性 | 类型 | 说明 |
|------|------|------|
| `stutterCount` | `NSInteger`（readonly） | 当前会话的卡顿次数 |
| `totalStutterDurationMs` | `NSInteger`（readonly） | 当前会话的卡顿总时长（毫秒） |
| `stutterThresholdMs` | `NSInteger`（readonly） | 卡顿阈值（毫秒），默认 0 |
| `delegate` | `id<StutterDetectStrategyDelegate>`（weak） | 回调代理 |
| `- initWithThreshold:` | `NSInteger` thresholdMs | 创建卡顿检测策略（指定阈值） |

`StutterDetectStrategyDelegate` 回调：

| 方法 | 参数 | 说明 |
|------|------|------|
| `- stutterDetectStrategy:didStutter:` | strategy, durationMs | 检测到一次卡顿 |
| `- stutterDetectStrategy:didAnalyzeSession:validPlayDuration:totalStutterDuration:stutterCount:` | strategy, stayDurationMs, validPlayDurationMs, totalStutterDurationMs, stutterCount | 播放会话分析完成 |

**TrafficProtectionStrategy（流量保护）**

监控网络状态变化，检测蜂窝网络播放。仅进行检测和日志记录，不自动暂停播放。

| 属性 | 类型 | 说明 |
|------|------|------|
| `isOnCellularNetwork` | `BOOL`（readonly） | 当前是否处于蜂窝网络 |
| `delegate` | `id<TrafficProtectionStrategyDelegate>`（weak） | 回调代理 |

`TrafficProtectionStrategyDelegate` 回调：

| 方法 | 参数 | 说明 |
|------|------|------|
| `- trafficProtectionStrategyDidDetectCellularNetwork:` | strategy | 检测到蜂窝网络播放 |
| `- trafficProtectionStrategyDidDetectWifiNetwork:` | strategy | 检测到网络切换回 Wi-Fi |

---

## **12. 日志系统**

### **12.1 LogHub（日志中心）**

日志管理中心（单例），统一管理日志输出和观察者注册。采用混合线程模型：控制台输出在调用线程同步执行，观察者通知异步分派到后台串行队列。

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `logEnabled` | `BOOL` | `YES` | 是否启用日志输出 |
| `logLevel` | `LogLevel` | `LogLevelInfo` | 最低日志输出级别 |
| `consoleLogEnabled` | `BOOL` | `YES` | 是否启用控制台（NSLog）输出 |

**观察者管理**

| 方法 | 参数 | 说明 |
|------|------|------|
| `+ sharedHub` | - | 获取 LogHub 共享单例 |
| `- addObserver:` | `id<LogObserver>` observer | 添加日志观察者（弱引用持有） |
| `- removeObserver:` | `id<LogObserver>` observer | 移除日志观察者 |

**日志输出**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- v:msg:` | tag, message | 输出 Verbose 级别日志 |
| `- d:msg:` | tag, message | 输出 Debug 级别日志 |
| `- i:msg:` | tag, message | 输出 Info 级别日志 |
| `- w:msg:` | tag, message | 输出 Warn 级别日志 |
| `- e:msg:` | tag, message | 输出 Error 级别日志 |
| `- e:msg:error:` | tag, message, error（nullable） | 输出 Error 级别日志（附带错误对象） |
| `- log:tag:msg:` | level, tag, message | 按指定级别输出日志 |

**工具方法**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `+ levelToString:` | `LogLevel` level | `NSString *` | 将日志级别转换为缩写字符串（V/D/I/W/E/N） |
| `+ stringToLevel:` | `NSString *` levelName | `LogLevel` | 将级别名称字符串转换回枚举值 |

### **12.2 LogObserver（日志观察者协议）**

实现此协议可接收所有日志输出回调，用于自定义日志处理（如写入文件、上报服务器）。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- onLog:`（@required） | `LogInfo *` logInfo | 日志输出回调（在子线程执行） |

### **12.3 LogInfo（日志信息模型）**

单条日志条目的数据模型。

| 属性 | 类型 | 说明 |
|------|------|------|
| `level` | `LogLevel`（readonly） | 日志级别 |
| `tag` | `NSString *`（readonly） | 日志标签 |
| `message` | `NSString *`（readonly） | 日志消息 |
| `timestamp` | `NSDate *`（readonly） | 时间戳 |
| `threadName` | `NSString *`（readonly） | 线程名称 |
| `fileName` | `NSString *`（readonly） | 源文件名 |
| `line` | `NSInteger`（readonly） | 源代码行号 |
| `error` | `NSError *`（readonly, nullable） | 关联的错误对象 |
| `- formattedString` | - | 获取格式化的日志字符串 |

---

## **13. 预加载系统**

### **13.1 PlayerPreloader（预加载协议）**

封装播放器 SDK 的全局预加载功能，通过 `[AliPlayerKit preloader]` 获取。

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- addTask:delegate:` | task, delegate | `NSString *`（任务 ID） | 添加预加载任务 |
| `- cancelTask:` | `NSString *` taskId | `void` | 取消指定任务 |
| `- pauseTask:` | `NSString *` taskId | `void` | 暂停指定任务 |
| `- resumeTask:` | `NSString *` taskId | `void` | 恢复指定任务 |
| `- cancelAll` | - | `void` | 取消所有预加载任务 |

### **13.2 PlayerPreloadTask（预加载任务）**

| 属性 | 类型 | 说明 |
|------|------|------|
| `videoSource` | `VideoSource *`（readonly） | 视频数据源 |
| `preloadConfig` | `PlayerPreloadConfig *`（readonly） | 预加载配置 |
| `- initWithVideoSource:preloadConfig:` | videoSource, preloadConfig | 创建预加载任务 |

### **13.3 PlayerPreloadConfig（预加载配置）**

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `preloadDuration` | `NSInteger` | 3000 | 预加载时长（毫秒） |
| `loadStartPositionMs` | `NSInteger` | 0 | 预加载起始位置（毫秒） |
| `defaultQuality` | `NSString *` | `@"AUTO"` | 默认清晰度标识 |
| `defaultResolution` | `NSInteger` | 0 | 默认分辨率（0 不限制） |
| `defaultBandWidth` | `NSInteger` | 0 | 默认码率（0 不限制） |
| `networkTimeout` | `NSInteger` | 0 | 网络超时时间（毫秒，0 使用 SDK 默认值） |
| `networkRetryCount` | `NSInteger` | 0 | 网络重试次数（0 使用 SDK 默认值） |
| `referrer` | `NSString *`（nullable） | nil | Referrer 信息 |
| `customHeaders` | `NSArray<NSString *> *`（nullable） | nil | 自定义请求头 |

**创建方法**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- init` | - | 使用默认配置创建 |
| `- initWithPreloadDuration:defaultQuality:` | preloadDuration, defaultQuality | 指定预加载时长和默认清晰度创建 |

### **13.4 PreloadDelegate（预加载代理）**

接收预加载任务的状态事件。所有方法均为 `@required`。

> **注意**：回调可能在后台线程触发，上层需自行分派到主线程处理。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- preloadTaskDidComplete:source:` | taskId, source | 预加载任务完成 |
| `- preloadTaskDidFail:source:error:` | taskId, source, error | 预加载任务失败 |
| `- preloadTaskDidCancel:source:` | taskId, source | 预加载任务被取消 |

---

## **14. 本地化系统**

### **14.1 LocaleManager（本地化管理器）**

本地化管理（单例），管理 PlayerKit 的多语言支持。

**字符串解析链**（Resolution Chain）：

1. Custom Provider（若已注入）
2. 手动指定语言的 Bundle（Manual 模式）
3. 跟随系统语言的 SDK Bundle
4. 返回 key 本身作为 fallback

| 属性 | 类型 | 说明 |
|------|------|------|
| `currentLanguageCode` | `NSString *`（readonly） | 当前生效的语言代码 |
| `localeMode` | `LocaleMode`（readonly） | 当前语言模式 |
| `localeProvider` | `id<LocaleProvider>`（weak, readonly, nullable） | 当前注入的自定义 Provider |

| 方法 | 参数 | 说明 |
|------|------|------|
| `+ sharedManager` | - | 获取单例实例 |
| `- setLanguageCode:` | `NSString *` languageCode | 设置手动语言（切换为 Manual 模式） |
| `- setLocaleProvider:` | `id<LocaleProvider>` provider（nullable） | 注入自定义 Provider（弱引用，传 nil 移除） |
| `- resetToSystemLanguage` | - | 重置为跟随系统语言 |
| `- localizedStringForKey:` | `NSString *` key | 查询本地化字符串 |

### **14.2 LocaleMode（语言模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `LocaleModeSystem` | 0 | 跟随系统语言（默认） |
| `LocaleModeManual` | 1 | 手动指定语言代码 |

### **14.3 LocaleProvider（本地化 Provider 协议）**

宿主 App 可实现此协议，为 PlayerKit 提供自定义翻译。

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- localizedStringForKey:`（@optional） | `NSString *` key | `NSString *`（nullable） | 为指定 key 返回本地化字符串（返回 nil 表示由 SDK 降级处理） |

### **14.4 LocaleDidChangeNotification（语言变更通知）**

当语言模式或语言代码发生变化时，在主线程发送 `LocaleDidChangeNotification` 通知。`userInfo` 中通过 `LocaleLanguageCodeKey` 携带新的语言代码。

---

## **15. 关键枚举与常量**

### **15.1 PlayerState（播放器状态）**

| 常量 | 值 | 说明 |
|------|---|------|
| `PlayerStateIdle` | 0 | 空闲（初始化完成但未加载资源） |
| `PlayerStatePreparing` | 1 | 准备中（异步加载资源） |
| `PlayerStatePrepared` | 2 | 已准备（可以开始播放） |
| `PlayerStatePlaying` | 3 | 播放中 |
| `PlayerStatePaused` | 4 | 已暂停 |
| `PlayerStateCompleted` | 5 | 已完播 |
| `PlayerStateStopped` | 6 | 已停止 |
| `PlayerStateError` | 7 | 错误状态 |

### **15.2 SceneType（场景类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `SceneTypeVOD` | 0 | 视频点播场景 |
| `SceneTypeLive` | 1 | 直播场景 |
| `SceneTypeVideoList` | 2 | 视频列表/短视频流场景 |
| `SceneTypeRestricted` | 3 | 受限播放场景 |
| `SceneTypeMinimal` | 4 | 极简播放页场景 |
| `SceneTypeAIVod` | 5 | AI 视频点播场景 |

### **15.3 ScaleMode（缩放模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `ScaleModeFitXY` | 0 | 拉伸填充视图 |
| `ScaleModeFitCenter` | 1 | 等比缩放适应视图（可能留黑边） |
| `ScaleModeCenterCrop` | 2 | 等比缩放裁剪填充 |

### **15.4 MirrorMode（镜像模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `MirrorModeNone` | 0 | 无镜像 |
| `MirrorModeHorizontal` | 1 | 水平镜像 |
| `MirrorModeVertical` | 2 | 垂直镜像 |

### **15.5 RotateMode（旋转模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `RotateModeDegree0` | 0 | 0 度 |
| `RotateModeDegree90` | 90 | 90 度 |
| `RotateModeDegree180` | 180 | 180 度 |
| `RotateModeDegree270` | 270 | 270 度 |

### **15.6 LogLevel（日志级别）**

| 常量 | 值 | 说明 |
|------|---|------|
| `LogLevelVerbose` | 0 | 最详细调试信息 |
| `LogLevelDebug` | 1 | 调试级别 |
| `LogLevelInfo` | 2 | 信息级别（默认） |
| `LogLevelWarn` | 3 | 警告级别 |
| `LogLevelError` | 4 | 错误级别 |
| `LogLevelNone` | 100 | 禁用所有日志 |

### **15.7 TrackType（轨道类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `TrackTypeUnknown` | 0 | 未知 |
| `TrackTypeVideo` | 1 | 视频轨道 |
| `TrackTypeAudio` | 2 | 音频轨道 |
| `TrackTypeSubtitle` | 3 | 字幕轨道 |
| `TrackTypeVOD` | 4 | VOD 轨道 |

### **15.8 TrackQuality（轨道清晰度）**

`TrackQuality` 描述一条可选的轨道（清晰度/音轨等），用于 `selectTrack:`、`trackQualityList`、`selectedTrackQuality` 等 API。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `NSInteger`（readonly） | 轨道索引 |
| `type` | `TrackType`（readonly） | 轨道类型 |
| `width` | `NSInteger`（readonly） | 轨道宽度（像素） |
| `height` | `NSInteger`（readonly） | 轨道高度（像素） |

| 方法 | 参数 | 说明 |
|------|------|------|
| `- initWithIndex:type:width:height:` | `NSInteger` index, `TrackType` type, `NSInteger` width, `NSInteger` height | 构造方法 |

---

以上内容为 AliPlayerKit iOS 版本的主要 API 接口说明。

如需进一步了解播放器各子系统的设计与使用方式，可参考 **[advanced/](./advanced/)** 目录下的相关文档。
