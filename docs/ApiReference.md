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
| `SlotManager` | 插槽管理器 | 插槽注册、可见性控制、元素级管理 | 跟随 AliPlayerView |
| `StrategyManager` | 策略管理器 | 策略注册/启停/重置 | 跟随 Controller |

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
| `coverUrl` | `NSString *`（nullable） | `nil` | 封面图 URL |
| `videoTitle` | `NSString *`（nullable） | `nil` | 视频标题 |
| `autoPlay` | `BOOL` | `YES` | 是否自动播放 |
| `traceId` | `NSString *`（nullable） | `nil` | 跟踪标识符（用于播放质量监控） |
| `startTime` | `NSInteger` | `0` | 起播位置（毫秒） |
| `hardwareDecode` | `BOOL` | `YES` | 是否启用硬件解码 |
| `allowScreenSleep` | `BOOL` | `NO` | 是否允许屏幕休眠 |
| `disableScreenshot` | `BOOL` | `NO` | 是否禁止截屏/录屏（iOS 特有） |
| `onPlayerConfigBlock` | `void (^)(id<MediaPlayer>)` | `nil` | 实例级自定义配置回调 |

### **5.2 创建方法**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- (instancetype)initWithVideoSource:` | `VideoSource *` videoSource | `AliPlayerModel *` | 通过视频源创建模型（指定初始化方法） |

---

## **6. 关键协议**

### **6.1 PlayerNotificationDelegate（播放器通知代理）**

播放器状态变化回调协议，所有方法均在主线程派发，均为 `@optional`。

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

### **6.2 MediaPlayer（播放器协议）**

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

### **6.3 PlayerLifecycleStrategy（生命周期策略协议）**

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
| `ReusePoolLifecycleStrategy` | LIFO 复用池 | 短视频列表 |
| `IdScopedPoolLifecycleStrategy` | ID 绑定 + LRU 淘汰 | 视频预加载 |
| `SingletonLifecycleStrategy` | 全局唯一实例 | 内存敏感场景 |

### **6.4 SlotProtocol（插槽协议）**

定义插槽生命周期回调。

| 方法 | 参数 | 说明 |
|------|------|------|
| `- onAttach:` | `id<SlotHost>` host | 插槽挂载到宿主 |
| `- onDetach` | - | 插槽从宿主分离 |
| `- onBindData:` | `AliPlayerModel *` model | 播放数据绑定 |
| `- onUnbindData` | - | 播放数据解绑 |

---

## **7. 插槽系统**

### **7.1 SlotManager（插槽管理器）**

`SlotManager` 是插槽系统的统一管理入口，通过 `AliPlayerView.slotManager` 获取。

**注册方法**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- registerSlotType:provider:` | type, `SlotProvider` block | 注册/替换插槽 Provider |
| `- unregisterSlotType:` | `SlotType` type | 注销插槽 Provider |
| `- isRegistered:` | `SlotType` type | 检查是否已注册 |
| `- registerCustomSlotType:provider:` | `CustomSlotType *` type, provider | 注册自定义插槽 |
| `- unregisterCustomSlotType:` | `CustomSlotType *` type | 注销自定义插槽 |

**插槽可见性**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- hideSlot:` | `SlotType` type | 隐藏整个插槽 |
| `- showSlot:` | `SlotType` type | 显示已隐藏的插槽 |
| `- isSlotHidden:` | `SlotType` type | 检查插槽是否隐藏 |

**元素级可见性**

| 方法 | 参数 | 说明 |
|------|------|------|
| `- hideElements:forSlot:` | `NSUInteger` mask, `SlotType` type | 隐藏插槽内特定元素（位掩码） |
| `- showElements:forSlot:` | `NSUInteger` mask, `SlotType` type | 显示之前隐藏的元素 |
| `- setHiddenElementMask:forSlot:` | `NSUInteger` mask, `SlotType` type | 替换隐藏元素掩码（覆盖式） |
| `- setAllHiddenElementMasks:` | `NSDictionary *` config | 批量设置所有隐藏元素 |
| `- clearAllElementMasks` | - | 清空所有元素可见性配置 |

**运行时访问**

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `- slotViewForType:` | `SlotType` type | `UIView<SlotProtocol> *` | 获取已挂载的插槽视图 |
| `- rebuildSlots` | - | `void` | 重建所有插槽 |
| `- clearAll` | - | `void` | 重置到初始状态 |

### **7.2 SlotType（插槽类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `SlotTypePlayerSurface` | 0 | 播放器渲染视图层（最底层） |
| `SlotTypeFullscreen` | 10 | 全屏控制层 |
| `SlotTypeGestureControl` | 20 | 手势识别和控制层 |
| `SlotTypeLandscapeHint` | 30 | 横屏提示层 |
| `SlotTypeCover` | 40 | 视频封面图层 |
| `SlotTypeCenterDisplay` | 50 | 中心展示层（倍速/亮度/音量） |
| `SlotTypePlayState` | 60 | 播放状态指示层（加载/错误/完成） |
| `SlotTypeLogPanel` | 70 | 日志面板层 |
| `SlotTypeTopBar` | 80 | 顶部导航栏层 |
| `SlotTypeBottomBar` | 90 | 底部控制栏层 |
| `SlotTypeSettingMenu` | 100 | 设置菜单层 |
| `SlotTypeOptionPanel` | 110 | 选项面板层（倍速/清晰度） |

---

## **8. 状态存储**

### **8.1 PlayerStateStore**

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

---

## **9. 视频源**

### **9.1 VideoSource（视频源模型）**

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

### **9.2 VideoSourceType（视频源类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `VideoSourceTypeVidAuth` | 0 | VID + PlayAuth 播放凭证（推荐） |
| `VideoSourceTypeVidSts` | 1 | VID + STS 临时凭证 |
| `VideoSourceTypeUrl` | 2 | URL 直接播放 |

---

## **10. 关键枚举与常量**

### **10.1 PlayerState（播放器状态）**

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

### **10.2 SceneType（场景类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `SceneTypeVOD` | 0 | 视频点播场景 |
| `SceneTypeLive` | 1 | 直播场景 |
| `SceneTypeVideoList` | 2 | 视频列表/短视频流场景 |
| `SceneTypeRestricted` | 3 | 受限播放场景 |
| `SceneTypeMinimal` | 4 | 极简播放页场景 |

### **10.3 ScaleMode（缩放模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `ScaleModeFitXY` | 0 | 拉伸填充视图 |
| `ScaleModeFitCenter` | 1 | 等比缩放适应视图（可能留黑边） |
| `ScaleModeCenterCrop` | 2 | 等比缩放裁剪填充 |

### **10.4 MirrorMode（镜像模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `MirrorModeNone` | 0 | 无镜像 |
| `MirrorModeHorizontal` | 1 | 水平镜像 |
| `MirrorModeVertical` | 2 | 垂直镜像 |

### **10.5 RotateMode（旋转模式）**

| 常量 | 值 | 说明 |
|------|---|------|
| `RotateModeDegree0` | 0 | 0 度 |
| `RotateModeDegree90` | 90 | 90 度 |
| `RotateModeDegree180` | 180 | 180 度 |
| `RotateModeDegree270` | 270 | 270 度 |

### **10.6 LogLevel（日志级别）**

| 常量 | 值 | 说明 |
|------|---|------|
| `LogLevelVerbose` | 0 | 最详细调试信息 |
| `LogLevelDebug` | 1 | 调试级别 |
| `LogLevelInfo` | 2 | 信息级别（默认） |
| `LogLevelWarn` | 3 | 警告级别 |
| `LogLevelError` | 4 | 错误级别 |
| `LogLevelNone` | 100 | 禁用所有日志 |

### **10.7 TrackType（轨道类型）**

| 常量 | 值 | 说明 |
|------|---|------|
| `TrackTypeUnknown` | 0 | 未知 |
| `TrackTypeVideo` | 1 | 视频轨道 |
| `TrackTypeAudio` | 2 | 音频轨道 |
| `TrackTypeSubtitle` | 3 | 字幕轨道 |
| `TrackTypeVOD` | 4 | VOD 轨道 |

---

以上内容为 AliPlayerKit iOS 版本的主要 API 接口说明。

如需进一步了解播放器各子系统的设计与使用方式，可参考 **[advanced/](./advanced/)** 目录下的相关文档。
