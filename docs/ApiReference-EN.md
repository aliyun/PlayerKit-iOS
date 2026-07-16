> 📚 **Recommended Reading Path**
>
> [Core Features](./CoreFeatures-EN.md) → [Integration](./Integration-EN.md) → [Quick Start](./QuickStart-EN.md) → **API Reference**

---

# **AliPlayerKit API Reference**

AliPlayerKit provides a rich set of APIs that allow developers to directly control player behavior. This document provides detailed descriptions of the main interfaces in the AliPlayerKit iOS version.

> 🤖 **AI-Friendly Note**
>
> AliPlayerKit provides comprehensive code comments for all core APIs (including classes and methods). In Xcode, you can view related documentation via Quick Help (Option + Click) to improve development efficiency; this also makes the APIs more friendly to AI programming tools.

---

## **1. Core Class Overview**

| Class | Type | Responsibility | Lifecycle |
|-------|------|----------------|-----------|
| `AliPlayerKit` | Global Entry | SDK initialization, global configuration, factory/preloader management | App lifecycle |
| `AliPlayerView` | View Container | Player view management, slot system host | Same as UIView |
| `AliPlayerController` | Player Controller | Playback control, state management, strategy coordination | Manual destroy to release |
| `AliPlayerModel` | Data Model | Encapsulates video source and playback parameters | Value object, no independent lifecycle |
| `PlayerStateStore` | State Store | Read-only access to current player state | Follows Controller |
| `PlayerViewState` | View State | Read-only access to UI layer state (fullscreen, controls visibility) | Follows AliPlayerView |
| `SlotManager` | Slot Manager | Slot registration, visibility control, element-level management | Follows AliPlayerView |
| `StrategyManager` | Strategy Manager | Strategy registration/start-stop/reset | Follows Controller |
| `StrategyRegistry` | Strategy Registry | Global default strategy factory management (singleton) | App lifecycle |
| `LogHub` | Log Hub | Log output and observer management (singleton) | App lifecycle |
| `LocaleManager` | Locale Manager | Multi-language support and Provider injection (singleton) | App lifecycle |

---

## **2. AliPlayerKit (Global API)**

`AliPlayerKit` is a global configuration class that provides SDK initialization and global configuration capabilities. This class cannot be instantiated; all methods are class methods.

### **2.1 Initialization Methods**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)setup` | - | `void` | Initialize the SDK; internally uses dispatch_once to guarantee idempotency. Recommended to call at app launch |
| `+ (BOOL)isInitialized` | - | `BOOL` | Query whether initialization has completed successfully |
| `+ (void)setOnGlobalInitBlock:` | `OnGlobalInitBlock` block | `void` | Set a custom configuration callback after global initialization completes; must be called before setup |

### **2.2 Status Query and Version Info**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (NSString *)getPlayerKitVersion` | - | `NSString *` | Get the PlayerKit version number |
| `+ (NSString *)getSdkVersion` | - | `NSString *` | Get the underlying AliPlayer SDK version number |

### **2.3 Debug Configuration**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)setDebugModeEnabled:` | `BOOL` enabled | `void` | Enable or disable debug mode |
| `+ (BOOL)isDebugModeEnabled` | - | `BOOL` | Query whether debug mode is enabled |
| `+ (void)setLogPanelEnabled:` | `BOOL` enabled | `void` | Enable or disable the log panel (only enable in debug scenarios) |
| `+ (BOOL)isLogPanelEnabled` | - | `BOOL` | Query whether the log panel is enabled |

### **2.4 Log Configuration**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)setLogLevel:` | `LogLevel` level | `void` | Set the log level; logs below this level are ignored (default: Info) |
| `+ (LogLevel)logLevel` | - | `LogLevel` | Get the current log level |
| `+ (void)enableConsoleLog:` | `BOOL` enable | `void` | Enable or disable console log output |
| `+ (BOOL)isConsoleLogEnabled` | - | `BOOL` | Query whether console logging is enabled |

### **2.5 Player Factory**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)setPlayerFactory:` | `id<PlayerFactory>` factory | `void` | Set a custom player factory; pass nil to restore the default |
| `+ (id<PlayerFactory>)playerFactory` | - | `id<PlayerFactory>` | Get the current player factory |

### **2.6 Preloading**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)setPreloader:` | `id<PlayerPreloader>` preloader | `void` | Set a custom preloader; pass nil to restore the default |
| `+ (id<PlayerPreloader>)preloader` | - | `id<PlayerPreloader>` | Get the current preloader |

### **2.7 Cache Management**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)clearCaches` | - | `void` | Clear local media cache; must be called after setup |

### **2.8 Internationalization**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ (void)setLanguageCode:` | `NSString *` languageCode | `void` | Manually specify the language (supports `zh-Hans`, `en`) |
| `+ (void)setLocaleProvider:` | `id<LocaleProvider>` provider | `void` | Inject a custom locale Provider (highest priority) |
| `+ (void)resetLocaleToSystemLanguage` | - | `void` | Reset to follow system language |
| `+ (NSString *)currentLanguageCode` | - | `NSString *` | Get the currently active language code |

---

## **3. AliPlayerView (View API)**

`AliPlayerView` is the player view container, responsible for managing controller binding and the slot system. The rendering view is created and managed internally by `PlayerSurfaceSlot`.

### **3.1 Properties**

| Property | Type | Description |
|----------|------|-------------|
| `controller` | `AliPlayerController *` (weak, readonly) | The associated player controller |
| `viewState` | `PlayerViewState *` (readonly) | UI state preserved across videos (fullscreen, controls visibility) |
| `slotManager` | `SlotManager *` (readonly) | Slot manager; can be pre-configured before attach |
| `fullscreenTransition` | `id<FullscreenTransition>` | Fullscreen transition animation implementation; defaults to a standalone Window rotation approach |
| `onBackPressed` | `void (^)(void)` (nullable) | Back button event callback |

> **Note**: `onBackPressed` is triggered in non-fullscreen state (in fullscreen, the back action is handled internally by the player to exit fullscreen). If this callback is not set, the player will attempt default navigation behavior (pop / dismiss) through the responder chain.

### **3.2 Controller Binding**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- (void)attach:` | `AliPlayerController *` controller | `void` | Bind the controller and activate the slot system |
| `- (void)detach` | - | `void` | Unbind the controller without destroying it |

**When to call**:

- `attach:` — Bind after the controller has called `configure:`; the slot system builds automatically based on slotManager configuration
- `detach` — Call when the view is about to be destroyed or when rebinding to a different controller

---

## **4. AliPlayerController (Controller API)**

`AliPlayerController` is the playback controller, serving as the unified entry point for playback operations. It encapsulates the player's creation, configuration, and control logic.

### **4.1 Properties**

| Property | Type | Description |
|----------|------|-------------|
| `playerModel` | `AliPlayerModel *` (readonly, nullable) | Current playback configuration model |
| `playerState` | `PlayerState` (readonly) | Current player state |
| `currentPosition` | `NSInteger` (readonly) | Current playback position (milliseconds) |
| `duration` | `NSInteger` (readonly) | Total video duration (milliseconds) |
| `stateStore` | `PlayerStateStore *` (readonly) | State store |
| `strategyManager` | `StrategyManager *` (readonly) | Strategy manager |
| `lifecycleStrategy` | `id<PlayerLifecycleStrategy>` (readonly) | Current lifecycle strategy |
| `autoLifecycleManagement` | `BOOL` | Whether to automatically manage foreground/background lifecycle (default YES) |
| `controlsVisibilityLocked` | `BOOL` | Controls visibility lock flag |

> **Note**: When `controlsVisibilityLocked` is set to `YES`, `setControlsVisible:NO` requests will be ignored and the control bar will remain visible. This is used in interaction scenarios such as progress bar dragging where the control bar must always be displayed.

### **4.2 Constructors**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- (instancetype)init` | - | Create a controller with the default lifecycle strategy |
| `- (instancetype)initWithLifecycleStrategy:` | `id<PlayerLifecycleStrategy>` strategy | Create a controller with a custom lifecycle strategy |

### **4.3 Configuration and Playback Control**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- (void)configure:` | `AliPlayerModel *` model | `void` | Configure the player and prepare for playback |
| `- (void)play` | - | `void` | Start or resume playback |
| `- (void)pause` | - | `void` | Pause playback |
| `- (void)toggle` | - | `void` | Toggle play/pause state |
| `- (void)replay` | - | `void` | Replay from the beginning |
| `- (void)stop` | - | `void` | Stop playback |
| `- (void)seekTo:` | `NSInteger` position (milliseconds) | `void` | Seek to the specified position |
| `- (void)setRate:` | `float` rate | `void` | Set playback speed (1.0 is normal) |
| `- (void)setLoop:` | `BOOL` loop | `void` | Set whether to loop playback |
| `- (void)setMuted:` | `BOOL` muted | `void` | Set whether to mute |
| `- (void)setMirrorMode:` | `MirrorMode` mirrorMode | `void` | Set mirror mode |
| `- (void)setScaleMode:` | `ScaleMode` scaleMode | `void` | Set scale mode |
| `- (void)setRotateMode:` | `RotateMode` rotateMode | `void` | Set rotation angle |
| `- (void)selectTrack:` | `TrackQuality *` quality | `void` | Switch quality track |
| `- (void)snapshot` | - | `void` | Capture the current video frame |

### **4.4 UI Control**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- (void)setControlsVisible:` | `BOOL` visible | `void` | Set controls visibility |
| `- (void)setFullscreen:` | `BOOL` fullscreen | `void` | Set fullscreen mode (with animation) |
| `- (void)setFullscreen:animated:` | `BOOL` fullscreen, `BOOL` animated | `void` | Set fullscreen mode (optionally animated) |

### **4.5 Lifecycle Methods**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- (void)onResume` | - | `void` | Resume playback (called when returning from background to foreground) |
| `- (void)onPause` | - | `void` | Pause playback (called when entering background) |
| `- (void)destroy` | - | `void` | Destroy the player and release all resources |

### **4.6 Notification Delegates**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- (void)addNotificationDelegate:` | `id<PlayerNotificationDelegate>` delegate | `void` | Add a notification delegate (held with weak reference) |
| `- (void)removeNotificationDelegate:` | `id<PlayerNotificationDelegate>` delegate | `void` | Remove a notification delegate |

---

## **5. AliPlayerModel (Model API)**

`AliPlayerModel` is the player configuration model that encapsulates all configuration information required for playback.

### **5.1 Properties**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `videoSource` | `VideoSource *` (readonly) | - | Video data source (required) |
| `sceneType` | `SceneType` | `SceneTypeVOD` | Playback scene type |
| `coverUrl` | `NSString *` (nullable) | `nil` | Cover image URL |
| `videoTitle` | `NSString *` (nullable) | `nil` | Video title |
| `autoPlay` | `BOOL` | `YES` | Whether to auto-play |
| `traceId` | `NSString *` (nullable) | `nil` | Trace identifier (for playback quality monitoring) |
| `startTime` | `NSInteger` | `0` | Start position (milliseconds) |
| `hardwareDecode` | `BOOL` | `YES` | Whether to enable hardware decoding |
| `allowScreenSleep` | `BOOL` | `NO` | Whether to allow screen sleep |
| `disableScreenshot` | `BOOL` | `NO` | Whether to disable screenshot/screen recording (iOS-specific) |
| `onPlayerConfigBlock` | `void (^)(id<MediaPlayer>)` | `nil` | Instance-level custom configuration callback |

### **5.2 Creation Methods**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- (instancetype)initWithVideoSource:` | `VideoSource *` videoSource | `AliPlayerModel *` | Create a model with a video source (designated initializer) |

---

## **6. Notification System**

AliPlayerKit uses a **Dispatcher + Delegate** pattern for event communication between components. Each `AliPlayerController` holds an independent Dispatcher instance, so events from different player instances do not interfere with each other. All callbacks are dispatched on the main thread.

On iOS, event distribution is implemented through three independent notification protocols:

| Notification Protocol | Responsibility | Typical Events |
|----------------------|----------------|----------------|
| `PlayerNotificationDelegate` | Player state and playback events | State changes, progress updates, first frame rendered, errors, fullscreen toggle |
| `GestureNotificationDelegate` | Gesture interaction events | Single tap, long press for speed, brightness/volume drag |
| `SlotActionNotificationDelegate` | Inter-slot action events | Settings menu toggle, speed panel/quality panel display |

### **6.1 PlayerNotificationDelegate (Player Notification Delegate)**

Player state change callback protocol; all methods are `@optional`.

**Playback State**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidChangeState:` | `PlayerState` state | Player state changed |
| `- playerDidPreparedWithDuration:` | `NSInteger` duration (milliseconds) | Preparation complete; playback can begin |
| `- playerDidRenderFirstFrame` | - | First frame rendered |
| `- playerDidCompletion` | - | Playback reached the end |

**Playback Progress**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidUpdateCurrentPosition:duration:bufferedPosition:` | position, duration, bufferedPosition (milliseconds) | Periodically reports playback progress |

**Errors and Snapshots**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidEncounterError:` | `NSError *` error | Playback error occurred |
| `- playerDidCompleteSnapshot:` | `UIImage *` (nullable) | Snapshot completed |

**Video Information**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidChangeVideoWidth:height:` | `NSInteger` width, height | Video dimensions changed |

**UI State**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidChangeFullscreen:` | `BOOL` isFullscreen | Fullscreen state changed |
| `- playerDidChangeControlsVisible:` | `BOOL` visible | Controls visibility changed |

**Loading State**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidLoadingBegin` | - | Buffering started |
| `- playerDidLoadingEnd` | - | Buffering ended |
| `- playerDidUpdateLoadingProgress:` | `float` progress (0-100) | Buffering progress updated |

**Display Mode**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidChangeMirrorMode:` | `MirrorMode` mirrorMode | Mirror mode changed |
| `- playerDidChangeScaleMode:` | `ScaleMode` scaleMode | Scale mode changed |
| `- playerDidChangeRotateMode:` | `RotateMode` rotateMode | Rotate mode changed |

**Tracks**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- playerDidTrackReady:` | `NSArray<TrackQuality *> *` tracks | Available track information is ready |
| `- playerDidTrackChanged:` | `TrackQuality *` quality | Track switch completed |

### **6.2 GestureNotificationDelegate (Gesture Notification Delegate)**

Gesture interaction event callback protocol; all methods are `@optional`. Multicast dispatched by `GestureNotificationDispatcher`.

**Single Tap**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- gestureDidSingleTap` | - | Single tap gesture triggered (typically used to toggle controls visibility) |

**Long Press (Speed)**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- gestureDidBeginLongPress` | - | Long press started (fast-forward playback activated) |
| `- gestureDidEndLongPress` | - | Long press ended (playback speed restored) |

**Brightness (Left vertical drag)**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- gestureDidUpdateBrightnessWithPercent:` | `CGFloat` currentPercent (0.0~1.0) | Brightness adjustment in progress |
| `- gestureDidEndBrightnessAdjust` | - | Brightness adjustment ended |

**Volume (Right vertical drag)**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- gestureDidUpdateVolumeWithPercent:` | `CGFloat` currentPercent (0.0~1.0) | Volume adjustment in progress |
| `- gestureDidEndVolumeAdjust` | - | Volume adjustment ended |

### **6.3 SlotActionNotificationDelegate (Slot Action Notification Delegate)**

Inter-slot action event notification protocol, used to decouple direct method calls between slots. All methods are `@optional` and dispatched asynchronously on the main thread.

| Method | Parameters | Description |
|--------|------------|-------------|
| `- slotDidRequestToggleSettingMenu` | - | Request to toggle settings menu visibility (typically triggered by TopBarSlot) |
| `- slotDidRequestShowSpeedPanel` | - | Request to show speed selection panel (typically triggered by BottomBarSlot) |
| `- slotDidRequestShowQualityPanel` | - | Request to show quality selection panel (typically triggered by BottomBarSlot) |

---

## **7. Player Protocols**

### **7.1 MediaPlayer (Player Protocol)**

Defines the core player operation interface; instances are created via `PlayerFactory`.

**Properties**

| Property | Type | Description |
|----------|------|-------------|
| `playerId` | `NSString *` (readonly) | Unique player identifier |
| `state` | `PlayerState` (readonly) | Current playback state |
| `currentPosition` | `NSInteger` (readonly) | Current position (milliseconds) |
| `duration` | `NSInteger` (readonly) | Total duration (milliseconds) |
| `speed` | `float` (readonly) | Current playback rate |
| `loop` | `BOOL` (readonly) | Whether looping is enabled |
| `muted` | `BOOL` (readonly) | Whether muted |
| `mirrorMode` | `MirrorMode` (readonly) | Current mirror mode |
| `scaleMode` | `ScaleMode` (readonly) | Current scale mode |
| `rotateMode` | `RotateMode` (readonly) | Current rotation angle |
| `stateStore` | `PlayerStateStore *` (readonly) | State store |
| `playerView` | `UIView *` (nullable) | Player rendering view, injected by the lifecycle strategy on create/recycle |
| `notificationDispatcher` | `PlayerNotificationDispatcher *` (nullable) | Event notification dispatcher |

**Playback Control**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- setDataSource:` | `AliPlayerModel *` model | Set the video data source |
| `- prepare` | - | Asynchronously prepare player resources |
| `- start` | - | Start playback |
| `- pause` | - | Pause |
| `- toggle` | - | Toggle play/pause |
| `- replay` | - | Replay from the beginning |
| `- seekTo:` | `NSInteger` position (milliseconds) | Seek to the specified position |
| `- stop` | - | Stop |
| `- destroy` | - | Destroy the player and release resources |

**Playback Settings**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- setSpeed:` | `float` speed | Set playback rate (0.5 ~ 2.0) |
| `- setLoop:` | `BOOL` loop | Set loop playback |
| `- setMuted:` | `BOOL` muted | Set mute |
| `- setMirrorMode:` | `MirrorMode` mode | Set mirror mode |
| `- setScaleMode:` | `ScaleMode` mode | Set scale mode |
| `- setRotateMode:` | `RotateMode` mode | Set rotation angle |
| `- selectTrack:` | `TrackQuality *` quality | Switch quality track |
| `- snapshot` | - | Capture the current frame |

### **7.2 PlayerLifecycleStrategy (Lifecycle Strategy Protocol)**

Defines the acquisition and recycling behavior of player instances.

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- setupWithFactory:` | `id<PlayerFactory>` factory | `void` | Inject the player factory (must be called first) |
| `- acquirePlayer` | - | `id<MediaPlayer>` | Acquire a player instance |
| `- recyclePlayer:force:` | player, `BOOL` force | `void` | Recycle a player instance |
| `- clear` | - | `void` | Release all cached instances |
| `- preloadWithCount:` (@optional) | `NSInteger` count | `void` | Preload a specified number of instances into the pool |
| `- acquirePlayerWithUniqueId:` (@optional) | `NSString *` uniqueId | `id<MediaPlayer>` | Acquire by ID (IdScoped strategy only) |
| `- recyclePlayer:uniqueId:force:` (@optional) | player, uniqueId, force | `void` | Recycle by ID (IdScoped strategy only) |

**Built-in Strategy Implementations**

| Strategy Class | Behavior | Applicable Scenarios |
|----------------|----------|----------------------|
| `DefaultLifecycleStrategy` | Creates new instance each time; destroys on recycle | Standard video playback |
| `SingletonLifecycleStrategy` | Global single instance (`sharedInstance` singleton) | List playback, memory-sensitive scenarios |
| `ReusePoolLifecycleStrategy` | LIFO reuse pool | Short video lists |
| `IdScopedPoolLifecycleStrategy` | ID-bound + LRU eviction | Video preloading |

### **7.3 FullscreenTransition (Fullscreen Transition Protocol)**

Defines the transition behavior for entering/exiting fullscreen for the player view.

| Method / Property | Parameters | Description |
|-------------------|------------|-------------|
| `- enterFullscreenWithPlayerView:animated:completion:` | playerView, animated, completion | Enter fullscreen |
| `- exitFullscreenWithPlayerView:animated:completion:` | playerView, animated, completion | Exit fullscreen |
| `isInFullscreen` (readonly) | - | Whether currently in fullscreen |

The default implementation `DefaultFullscreenTransition` uses a standalone Window rotation approach. Custom implementations can be injected via `playerView.fullscreenTransition`.

---

## **8. Slot System**

### **8.1 SlotProtocol (Slot Protocol)**

Defines slot lifecycle callbacks.

| Method | Parameters | Description |
|--------|------------|-------------|
| `- onAttach:` | `id<SlotHost>` host | Slot attached to host |
| `- onDetach` | - | Slot detached from host |
| `- onBindData:` | `AliPlayerModel *` model | Playback data bound |
| `- onUnbindData` | - | Playback data unbound |

### **8.2 BaseSlot (Slot Base Class)**

Abstract base class for all built-in slots (`UIView` subclass), implementing `SlotProtocol` and providing common capabilities.

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `host` | `id<SlotHost>` (weak, readonly) | The host this slot is attached to |
| `slotType` | `SlotType` | Slot type identifier (injected by SlotHostLayout) |
| `safeAreaEdges` | `SlotSafeAreaEdge` | Safe area edges to respect (default: All) |
| `deferContentCreation` | `BOOL` | Deferred content creation toggle |
| `contentReady` | `BOOL` (readonly) | Whether content is ready |
| `touchPassthrough` | `BOOL` | Touch passthrough toggle (default: YES) |
| `- setupContentView` | - | Override in subclasses to add custom UI elements |
| `- show` / `- hide` | - | Show/hide the slot |
| `- showWithAnimation:` / `- hideWithAnimation:` | `BOOL` animated | Show/hide with animation |
| `- isShowing` | - | Returns whether currently visible |
| `- dismiss` | - | Properly remove the slot via the host |
| `- onRegisterElements` | - | Override in subclasses to declare the bitmask of default visible elements |
| `- isElementVisible:` | `NSUInteger` element | Query the final visibility of a specific element |
| `- currentSceneType` | - | Safely read the current scene type |
| `- ensureContentReady` | - | Ensure deferred content has been created |

### **8.3 SlotManager (Slot Manager)**

`SlotManager` is the unified management entry point for the slot system, accessed via `AliPlayerView.slotManager`.

**Registration Methods**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- registerSlotType:provider:` | type, `SlotProvider` block | Register/replace a slot Provider |
| `- unregisterSlotType:` | `SlotType` type | Unregister a slot Provider |
| `- isRegistered:` | `SlotType` type | Check whether a slot is registered |
| `- registerCustomSlotType:provider:` | `CustomSlotType *` type, provider | Register a custom slot |
| `- unregisterCustomSlotType:` | `CustomSlotType *` type | Unregister a custom slot |
| `- isCustomSlotRegistered:` | `CustomSlotType *` type | Check whether a custom slot is registered |
| `- customSlotTypes` | - | Get all registered custom slot types |

**Slot Visibility**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- hideSlot:` | `SlotType` type | Hide an entire slot |
| `- showSlot:` | `SlotType` type | Show a previously hidden slot |
| `- isSlotHidden:` | `SlotType` type | Check whether a slot is hidden |

**Scene-based Visibility Configuration**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- registerSlotConfig:` | `SlotConfig *` config | `void` | Register a scene-based visibility configuration for a slot type (replaces any existing configuration for the same type) |
| `- unregisterSlotConfigForType:` | `SlotType` slotType | `void` | Remove the scene-based visibility configuration for a slot type; once removed, the slot is visible by default in all scenes (controlled only by `hideSlot:`) |
| `- slotConfigForType:` | `SlotType` type | `nullable SlotConfig *` | Get the scene-based visibility configuration for a slot type; returns nil if not configured |

**Element-Level Visibility**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- hideElements:forSlot:` | `NSUInteger` mask, `SlotType` type | Hide specific elements within a slot (bitmask) |
| `- showElements:forSlot:` | `NSUInteger` mask, `SlotType` type | Show previously hidden elements |
| `- setHiddenElementMask:forSlot:` | `NSUInteger` mask, `SlotType` type | Replace the hidden element mask (override mode) |
| `- hiddenElementMaskForSlot:` | `SlotType` type | Get the hidden element bitmask for a slot; returns 0 if not configured |
| `- shownElementMaskForSlot:` | `SlotType` type | Get the shown element bitmask for a slot; returns 0 if not configured |
| `- setAllHiddenElementMasks:` | `NSDictionary *` config | Batch set all hidden elements |
| `- clearAllElementMasks` | - | Clear all element visibility configurations |

**Runtime Access**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- slotViewForType:` | `SlotType` type | `UIView<SlotProtocol> *` | Get the mounted slot view |
| `- rebuildSlots` | - | `void` | Rebuild all slots |
| `- clearAll` | - | `void` | Reset to initial state |

### **8.4 SlotType (Slot Types)**

| Constant | Value | Description |
|----------|-------|-------------|
| `SlotTypePlayerSurface` | 10 | Player rendering view layer (bottommost) |
| `SlotTypeGestureControl` | 20 | Gesture recognition and control layer |
| `SlotTypeLandscapeHint` | 30 | Landscape hint layer |
| `SlotTypeCover` | 40 | Video cover image layer |
| `SlotTypeCenterDisplay` | 50 | Center display layer (speed/brightness/volume) |
| `SlotTypePlayState` | 60 | Play state indicator layer (loading/error/completed) |
| `SlotTypeLogPanel` | 70 | Log panel layer |
| `SlotTypeTopBar` | 80 | Top navigation bar layer |
| `SlotTypeBottomBar` | 90 | Bottom control bar layer |
| `SlotTypeSettingMenu` | 100 | Settings menu layer |
| `SlotTypeOptionPanel` | 110 | Option panel layer (speed/quality) |

### **8.5 CustomSlotType (Custom Slot Type)**

Used to insert custom business slots between built-in slots. Built-in `SlotType` enum values are arranged at intervals of 10 (10, 20, ...110); `CustomSlotType` specifies the insertion position via the `order` field.

| Property / Method | Description |
|-------------------|-------------|
| `key` (readonly) | Unique identifier for registration, lookup, and equality comparison |
| `order` (readonly) | Sort value determining the slot's Z-axis position (lower values are further back) |
| `+ typeWithKey:order:` | Create a custom slot type instance |

```objc
// Insert a custom slot between TopBar(80) and BottomBar(90)
CustomSlotType *type = [CustomSlotType typeWithKey:@"myCustomSlot" order:85];
[playerView.slotManager registerCustomSlotType:type provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomSlotView alloc] initWithFrame:parentView.bounds];
}];
```

### **8.6 SlotElements (Slot Element Bitmasks)**

Used with `SlotManager`'s `hideElements:forSlot:` / `showElements:forSlot:` methods to achieve fine-grained visibility control over individual UI elements within a slot.

**TopBarElement (Top Bar Elements)**

| Constant | Bit | Description |
|----------|-----|-------------|
| `TopBarElementBack` | 1 << 0 | Back button |
| `TopBarElementTitle` | 1 << 1 | Title text |
| `TopBarElementDownload` | 1 << 2 | Download button |
| `TopBarElementSnapshot` | 1 << 3 | Snapshot button |
| `TopBarElementSettings` | 1 << 4 | Settings button |

**BottomBarElement (Bottom Bar Elements)**

| Constant | Bit | Description |
|----------|-----|-------------|
| `BottomBarElementPlay` | 1 << 0 | Play/pause button |
| `BottomBarElementProgress` | 1 << 1 | Progress bar |
| `BottomBarElementRefresh` | 1 << 2 | Refresh button |
| `BottomBarElementSpeed` | 1 << 3 | Speed button (visible only in landscape layout) |

**SettingMenuElement (Settings Menu Elements)**

| Constant | Bit | Description |
|----------|-----|-------------|
| `SettingMenuElementSpeed` | 1 << 0 | Speed option |
| `SettingMenuElementTrackInfo` | 1 << 1 | Quality information |
| `SettingMenuElementLoop` | 1 << 2 | Loop playback |
| `SettingMenuElementMute` | 1 << 3 | Mute |
| `SettingMenuElementMirrorMode` | 1 << 4 | Mirror mode |
| `SettingMenuElementRotateMode` | 1 << 5 | Rotate mode |
| `SettingMenuElementScaleMode` | 1 << 6 | Scale mode |
| `SettingMenuElementSubtitle` | 1 << 7 | Subtitle |

**CenterDisplayElement (Center Display Layer Elements)**

| Constant | Bit | Description |
|----------|-----|-------------|
| `CenterDisplayElementVolume` | 1 << 0 | Volume indicator |
| `CenterDisplayElementBrightness` | 1 << 1 | Brightness indicator |
| `CenterDisplayElementSpeed` | 1 << 2 | Speed indicator |

**GestureElement (Gesture Control Elements)**

> **Note**: These constants control enabling/disabling of gesture interactions, not the visibility of UI elements. When a gesture bit is set to hidden, that gesture will be disabled.

| Constant | Bit | Description |
|----------|-----|-------------|
| `GestureElementSingleTap` | 1 << 0 | Single tap gesture |
| `GestureElementDoubleTap` | 1 << 1 | Double tap gesture |
| `GestureElementLongPress` | 1 << 2 | Long press gesture |
| `GestureElementHorizontalDrag` | 1 << 3 | Horizontal drag (progress) |
| `GestureElementLeftVerticalDrag` | 1 << 4 | Left vertical drag (brightness) |
| `GestureElementRightVerticalDrag` | 1 << 5 | Right vertical drag (volume) |

**PlayStateElement (Play State Layer Elements)**

| Constant | Bit | Description |
|----------|-----|-------------|
| `PlayStateElementErrorMessage` | 1 << 0 | Error message |
| `PlayStateElementLoadingMessage` | 1 << 1 | Loading message |

---

## **9. State Store**

### **9.1 PlayerStateStore**

`PlayerStateStore` holds a read-only snapshot of the current playback state, accessed via `AliPlayerController.stateStore`.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `playState` | `PlayerState` | `PlayerStateIdle` | Current playback state |
| `duration` | `NSInteger` | 0 | Total duration (milliseconds) |
| `currentPosition` | `NSInteger` | 0 | Current position (milliseconds) |
| `bufferedPosition` | `NSInteger` | 0 | Buffered position (milliseconds) |
| `speed` | `float` | 1.0 | Current playback speed |
| `loop` | `BOOL` | NO | Whether looping is enabled |
| `muted` | `BOOL` | NO | Whether muted |
| `mirrorMode` | `MirrorMode` | `MirrorModeNone` | Mirror mode |
| `scaleMode` | `ScaleMode` | `ScaleModeCenterCrop` | Scale mode |
| `rotateMode` | `RotateMode` | `RotateModeDegree0` | Rotation angle |
| `videoWidth` | `NSInteger` | 0 | Original video width |
| `videoHeight` | `NSInteger` | 0 | Original video height |
| `trackQualityList` | `NSArray<TrackQuality *> *` | nil | Available quality list |
| `selectedTrackQuality` | `TrackQuality *` | nil | Currently selected quality |

### **9.2 PlayerViewState**

`PlayerViewState` holds persistent state related to the UI layer, accessed via `AliPlayerView.viewState`. Preserved across video switches; state updates include automatic deduplication.

| Property / Method | Type | Default | Description |
|-------------------|------|---------|-------------|
| `fullscreen` | `BOOL` (readonly) | `NO` | Whether in fullscreen mode |
| `controlsVisible` | `BOOL` (readonly) | `NO` | Whether controls are visible |
| `- reset` | - | - | Reset all state to defaults |
| `- updateFullscreen:` | `BOOL` fullscreen | - | Update fullscreen state |
| `- updateControlsVisible:` | `BOOL` controlsVisible | - | Update controls visibility |

---

## **10. Video Source**

### **10.1 VideoSource (Video Source Model)**

| Property | Type | Description |
|----------|------|-------------|
| `sourceType` | `VideoSourceType` | Video source type |
| `uniqueId` | `NSString *` (nullable) | Unique identifier (returns vid for VidAuth/VidSts, url for URL) |
| `url` | `NSString *` (nullable) | Video URL (valid for URL type) |
| `vid` | `NSString *` (nullable) | Video ID (valid for VidAuth/VidSts) |
| `playAuth` | `NSString *` (nullable) | Play authorization token (valid for VidAuth) |
| `accessKeyId` | `NSString *` (nullable) | STS AccessKeyId |
| `accessKeySecret` | `NSString *` (nullable) | STS AccessKeySecret |
| `securityToken` | `NSString *` (nullable) | STS SecurityToken |
| `region` | `NSString *` (nullable) | Region identifier |

**Factory Methods**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ vidAuthSourceWithVid:playAuth:` | vid, playAuth | `VideoSource *` | Create a VidAuth video source (recommended) |
| `+ vidStsSourceWithVid:accessKeyId:accessKeySecret:securityToken:region:` | vid, keyId, secret, token, region | `VideoSource *` | Create a VidSts video source |
| `+ urlSourceWithUrl:` | url | `VideoSource *` | Create a URL video source |
| `- (BOOL)isValid` | - | `BOOL` | Validate whether the configuration is valid |

### **10.2 VideoSourceType (Video Source Types)**

| Constant | Value | Description |
|----------|-------|-------------|
| `VideoSourceTypeVidAuth` | 0 | VID + PlayAuth credential (recommended) |
| `VideoSourceTypeVidSts` | 1 | VID + STS temporary credential |
| `VideoSourceTypeUrl` | 2 | Direct URL playback |

---

## **11. Strategy System**

### **11.1 StrategyProtocol (Strategy Protocol)**

Defines the lifecycle contract for strategies. Strategy names must be globally unique.

| Method | Parameters | Description |
|--------|------------|-------------|
| `- strategyName` (@required) | - | Unique strategy identifier name |
| `- strategyDidStart:` (@required) | `StrategyContext *` context | Strategy started; binds to player context |
| `- strategyDidStop` (@required) | - | Strategy stopped; unbinds from context |
| `- strategyDidReset:` (@required) | `StrategyContext *` context | Strategy reset (called when video source switches) |

### **11.2 StrategyContext (Strategy Context)**

Provides read-only player environment information to strategies; created by `StrategyManager` and passed in when the strategy starts.

| Property | Type | Description |
|----------|------|-------------|
| `controller` | `AliPlayerController *` (weak, readonly) | Associated player controller |
| `playerModel` | `AliPlayerModel *` (readonly) | Current playback configuration model |
| `stateStore` | `PlayerStateStore *` (readonly, nullable) | Player state store |

> **Note**: This object is no longer valid after `strategyDidStop` and should not be used further.

### **11.3 BaseStrategy (Strategy Base Class)**

Abstract base class for strategies, implementing `StrategyProtocol` and `PlayerNotificationDelegate`. Automatically handles subscription and unsubscription of player events.

| Property / Method | Description |
|-------------------|-------------|
| `context` (readonly, nullable) | Current strategy context (only valid between start and stop) |
| `- resetInternalState` | Hook method for subclasses to reset internal state (e.g., clear counters, timers) |

**Lifecycle flow**: `strategyDidStart:` → save context → register notification delegate → `strategyDidReset:` → update context → call `resetInternalState` → `strategyDidStop` → unregister notification delegate → clear context

> **Note**: Subclasses must override the `strategyName` method. If overriding `strategyDidStart:` / `strategyDidStop` / `strategyDidReset:`, you must call `super`.

### **11.4 StrategyManager (Strategy Manager)**

Each `AliPlayerController` owns a `StrategyManager` instance. Strategies are executed in registration order, and each strategy's lifecycle calls are isolated via `@try/@catch`.

| Method | Parameters | Description |
|--------|------------|-------------|
| `- registerStrategy:` | `id<StrategyProtocol>` strategy | Register a strategy (strategies with the same name will be stopped and replaced) |
| `- unregisterStrategyWithName:` | `NSString *` name | Unregister a strategy by name |
| `- strategyWithName:` | `NSString *` name | Find a strategy by name |
| `- startWithController:playerModel:` | controller, playerModel | Start all registered strategies |
| `- resetWithPlayerModel:` | `AliPlayerModel *` playerModel | Reset all strategies (when video source switches) |
| `- stop` | - | Stop all strategies |
| `- destroy` | - | Stop and remove all strategies |

| Property | Type | Description |
|----------|------|-------------|
| `strategyCount` | `NSUInteger` (readonly) | Number of currently registered strategies |
| `started` | `BOOL` (readonly) | Whether the manager has been started |

### **11.5 StrategyRegistry (Global Strategy Registry)**

Global strategy registry (singleton) that maintains a set of strategy factory Blocks. Whenever a new `AliPlayerController` is created, `applyToManager:` instantiates all registered factories and injects them into the controller's `StrategyManager`.

| Method | Parameters | Description |
|--------|------------|-------------|
| `+ sharedRegistry` | - | Get the global registry singleton |
| `- addGlobalStrategyFactory:` | `StrategyFactory` factory | Add a global strategy factory |
| `- clearGlobalStrategies` | - | Remove all global strategy factories (including built-in strategies) |
| `- applyToManager:` | `StrategyManager *` manager | Instantiate all global strategies and register them with the specified manager |
| `- resetToDefault` | - | Restore to default built-in strategy configuration |

> **Note**: Built-in strategies (`FirstFrameStrategy`, `StutterDetectStrategy`, `TrafficProtectionStrategy`) are automatically registered on first access.

### **11.6 Built-in Strategies**

**FirstFrameStrategy (First Frame Timing)**

Measures the time from player preparation start to first frame rendering, divided into the preparation phase (Preparing → Prepared) and the rendering phase (Prepared → FirstFrameRendered).

| Property | Type | Description |
|----------|------|-------------|
| `delegate` | `id<FirstFrameStrategyDelegate>` (weak) | Callback delegate |

`FirstFrameStrategyDelegate` callbacks:

| Method | Parameters | Description |
|--------|------------|-------------|
| `- firstFrameStrategy:didRenderFirstFrameWithPrepareTime:renderTime:totalTime:` | strategy, prepareTimeMs, renderTimeMs, totalTimeMs | First frame rendered |

**StutterDetectStrategy (Stutter Detection)**

Detects stutters by monitoring Loading events (Loading events before first frame rendering are excluded from statistics).

| Property | Type | Description |
|----------|------|-------------|
| `stutterCount` | `NSInteger` (readonly) | Stutter count in the current session |
| `totalStutterDurationMs` | `NSInteger` (readonly) | Total stutter duration in the current session (milliseconds) |
| `stutterThresholdMs` | `NSInteger` (readonly) | Stutter threshold (milliseconds), default 0 |
| `delegate` | `id<StutterDetectStrategyDelegate>` (weak) | Callback delegate |
| `- initWithThreshold:` | `NSInteger` thresholdMs | Create a stutter detection strategy (with threshold) |

`StutterDetectStrategyDelegate` callbacks:

| Method | Parameters | Description |
|--------|------------|-------------|
| `- stutterDetectStrategy:didStutter:` | strategy, durationMs | A stutter was detected |
| `- stutterDetectStrategy:didAnalyzeSession:validPlayDuration:totalStutterDuration:stutterCount:` | strategy, stayDurationMs, validPlayDurationMs, totalStutterDurationMs, stutterCount | Playback session analysis completed |

**TrafficProtectionStrategy (Traffic Protection)**

Monitors network state changes and detects cellular network playback. Only performs detection and logging; does not automatically pause playback.

| Property | Type | Description |
|----------|------|-------------|
| `isOnCellularNetwork` | `BOOL` (readonly) | Whether currently on a cellular network |
| `delegate` | `id<TrafficProtectionStrategyDelegate>` (weak) | Callback delegate |

`TrafficProtectionStrategyDelegate` callbacks:

| Method | Parameters | Description |
|--------|------------|-------------|
| `- trafficProtectionStrategyDidDetectCellularNetwork:` | strategy | Cellular network playback detected |
| `- trafficProtectionStrategyDidDetectWifiNetwork:` | strategy | Network switched back to Wi-Fi |

---

## **12. Log System**

### **12.1 LogHub (Log Hub)**

Log management hub (singleton) that provides unified management of log output and observer registration. Uses a hybrid threading model: console output executes synchronously on the calling thread, while observer notifications are dispatched asynchronously to a background serial queue.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `logEnabled` | `BOOL` | `YES` | Whether log output is enabled |
| `logLevel` | `LogLevel` | `LogLevelInfo` | Minimum log output level |
| `consoleLogEnabled` | `BOOL` | `YES` | Whether console (NSLog) output is enabled |

**Observer Management**

| Method | Parameters | Description |
|--------|------------|-------------|
| `+ sharedHub` | - | Get the shared LogHub singleton |
| `- addObserver:` | `id<LogObserver>` observer | Add a log observer (held with weak reference) |
| `- removeObserver:` | `id<LogObserver>` observer | Remove a log observer |

**Log Output**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- v:msg:` | tag, message | Output Verbose level log |
| `- d:msg:` | tag, message | Output Debug level log |
| `- i:msg:` | tag, message | Output Info level log |
| `- w:msg:` | tag, message | Output Warn level log |
| `- e:msg:` | tag, message | Output Error level log |
| `- e:msg:error:` | tag, message, error (nullable) | Output Error level log (with error object) |
| `- log:tag:msg:` | level, tag, message | Output log at the specified level |

**Utility Methods**

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `+ levelToString:` | `LogLevel` level | `NSString *` | Convert log level to abbreviated string (V/D/I/W/E/N) |
| `+ stringToLevel:` | `NSString *` levelName | `LogLevel` | Convert level name string back to enum value |

### **12.2 LogObserver (Log Observer Protocol)**

Implement this protocol to receive all log output callbacks for custom log handling (e.g., writing to file, reporting to server).

| Method | Parameters | Description |
|--------|------------|-------------|
| `- onLog:` (@required) | `LogInfo *` logInfo | Log output callback (executed on a background thread) |

### **12.3 LogInfo (Log Information Model)**

Data model for a single log entry.

| Property | Type | Description |
|----------|------|-------------|
| `level` | `LogLevel` (readonly) | Log level |
| `tag` | `NSString *` (readonly) | Log tag |
| `message` | `NSString *` (readonly) | Log message |
| `timestamp` | `NSDate *` (readonly) | Timestamp |
| `threadName` | `NSString *` (readonly) | Thread name |
| `fileName` | `NSString *` (readonly) | Source file name |
| `line` | `NSInteger` (readonly) | Source code line number |
| `error` | `NSError *` (readonly, nullable) | Associated error object |
| `- formattedString` | - | Get the formatted log string |

---

## **13. Preload System**

### **13.1 PlayerPreloader (Preload Protocol)**

Encapsulates the player SDK's global preload functionality, accessed via `[AliPlayerKit preloader]`.

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- addTask:delegate:` | task, delegate | `NSString *` (task ID) | Add a preload task |
| `- cancelTask:` | `NSString *` taskId | `void` | Cancel a specific task |
| `- pauseTask:` | `NSString *` taskId | `void` | Pause a specific task |
| `- resumeTask:` | `NSString *` taskId | `void` | Resume a specific task |
| `- cancelAll` | - | `void` | Cancel all preload tasks |

### **13.2 PlayerPreloadTask (Preload Task)**

| Property | Type | Description |
|----------|------|-------------|
| `videoSource` | `VideoSource *` (readonly) | Video data source |
| `preloadConfig` | `PlayerPreloadConfig *` (readonly) | Preload configuration |
| `- initWithVideoSource:preloadConfig:` | videoSource, preloadConfig | Create a preload task |

### **13.3 PlayerPreloadConfig (Preload Configuration)**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `preloadDuration` | `NSInteger` | 3000 | Preload duration (milliseconds) |
| `loadStartPositionMs` | `NSInteger` | 0 | Preload start position (milliseconds) |
| `defaultQuality` | `NSString *` | `@"AUTO"` | Default quality identifier |
| `defaultResolution` | `NSInteger` | 0 | Default resolution (0 means no limit) |
| `defaultBandWidth` | `NSInteger` | 0 | Default bitrate (0 means no limit) |
| `networkTimeout` | `NSInteger` | 0 | Network timeout (milliseconds; 0 uses SDK default) |
| `networkRetryCount` | `NSInteger` | 0 | Network retry count (0 uses SDK default) |
| `referrer` | `NSString *` (nullable) | nil | Referrer information |
| `customHeaders` | `NSArray<NSString *> *` (nullable) | nil | Custom request headers |

**Creation Methods**

| Method | Parameters | Description |
|--------|------------|-------------|
| `- init` | - | Create with default configuration |
| `- initWithPreloadDuration:defaultQuality:` | preloadDuration, defaultQuality | Create with specified preload duration and default quality |

### **13.4 PreloadDelegate (Preload Delegate)**

Receives preload task status events. All methods are `@required`.

> **Note**: Callbacks may be triggered on a background thread; callers must dispatch to the main thread as needed.

| Method | Parameters | Description |
|--------|------------|-------------|
| `- preloadTaskDidComplete:source:` | taskId, source | Preload task completed |
| `- preloadTaskDidFail:source:error:` | taskId, source, error | Preload task failed |
| `- preloadTaskDidCancel:source:` | taskId, source | Preload task was cancelled |

---

## **14. Locale System**

### **14.1 LocaleManager (Locale Manager)**

Locale management (singleton) that manages multi-language support for PlayerKit.

**String Resolution Chain**:

1. Custom Provider (if injected)
2. Bundle for manually specified language (Manual mode)
3. SDK Bundle following system language
4. Return the key itself as fallback

| Property | Type | Description |
|----------|------|-------------|
| `currentLanguageCode` | `NSString *` (readonly) | Currently active language code |
| `localeMode` | `LocaleMode` (readonly) | Current language mode |
| `localeProvider` | `id<LocaleProvider>` (weak, readonly, nullable) | Currently injected custom Provider |

| Method | Parameters | Description |
|--------|------------|-------------|
| `+ sharedManager` | - | Get the singleton instance |
| `- setLanguageCode:` | `NSString *` languageCode | Set manual language (switches to Manual mode) |
| `- setLocaleProvider:` | `id<LocaleProvider>` provider (nullable) | Inject a custom Provider (weak reference; pass nil to remove) |
| `- resetToSystemLanguage` | - | Reset to follow system language |
| `- localizedStringForKey:` | `NSString *` key | Query a localized string |

### **14.2 LocaleMode (Language Mode)**

| Constant | Value | Description |
|----------|-------|-------------|
| `LocaleModeSystem` | 0 | Follow system language (default) |
| `LocaleModeManual` | 1 | Manually specified language code |

### **14.3 LocaleProvider (Locale Provider Protocol)**

Host apps can implement this protocol to provide custom translations for PlayerKit.

| Method | Parameters | Return Value | Description |
|--------|------------|--------------|-------------|
| `- localizedStringForKey:` (@optional) | `NSString *` key | `NSString *` (nullable) | Return a localized string for the given key (return nil to fall back to SDK handling) |

### **14.4 LocaleDidChangeNotification (Language Change Notification)**

When the language mode or language code changes, a `LocaleDidChangeNotification` notification is posted on the main thread. The `userInfo` contains the new language code via `LocaleLanguageCodeKey`.

---

## **15. Key Enumerations and Constants**

### **15.1 PlayerState (Player States)**

| Constant | Value | Description |
|----------|-------|-------------|
| `PlayerStateIdle` | 0 | Idle (initialization complete but no resources loaded) |
| `PlayerStatePreparing` | 1 | Preparing (asynchronously loading resources) |
| `PlayerStatePrepared` | 2 | Prepared (ready to start playback) |
| `PlayerStatePlaying` | 3 | Playing |
| `PlayerStatePaused` | 4 | Paused |
| `PlayerStateCompleted` | 5 | Completed |
| `PlayerStateStopped` | 6 | Stopped |
| `PlayerStateError` | 7 | Error state |

### **15.2 SceneType (Scene Types)**

| Constant | Value | Description |
|----------|-------|-------------|
| `SceneTypeVOD` | 0 | Video on demand |
| `SceneTypeLive` | 1 | Live streaming |
| `SceneTypeVideoList` | 2 | Video list / short video feed |
| `SceneTypeRestricted` | 3 | Restricted playback |
| `SceneTypeMinimal` | 4 | Minimal player |

### **15.3 ScaleMode (Scale Modes)**

| Constant | Value | Description |
|----------|-------|-------------|
| `ScaleModeFitXY` | 0 | Stretch to fill the view |
| `ScaleModeFitCenter` | 1 | Scale proportionally to fit the view (may show letterboxing) |
| `ScaleModeCenterCrop` | 2 | Scale proportionally and crop to fill |

### **15.4 MirrorMode (Mirror Modes)**

| Constant | Value | Description |
|----------|-------|-------------|
| `MirrorModeNone` | 0 | No mirroring |
| `MirrorModeHorizontal` | 1 | Horizontal mirroring |
| `MirrorModeVertical` | 2 | Vertical mirroring |

### **15.5 RotateMode (Rotation Modes)**

| Constant | Value | Description |
|----------|-------|-------------|
| `RotateModeDegree0` | 0 | 0 degrees |
| `RotateModeDegree90` | 90 | 90 degrees |
| `RotateModeDegree180` | 180 | 180 degrees |
| `RotateModeDegree270` | 270 | 270 degrees |

### **15.6 LogLevel (Log Levels)**

| Constant | Value | Description |
|----------|-------|-------------|
| `LogLevelVerbose` | 0 | Most detailed debug information |
| `LogLevelDebug` | 1 | Debug level |
| `LogLevelInfo` | 2 | Information level (default) |
| `LogLevelWarn` | 3 | Warning level |
| `LogLevelError` | 4 | Error level |
| `LogLevelNone` | 100 | Disable all logs |

### **15.7 TrackType (Track Types)**

| Constant | Value | Description |
|----------|-------|-------------|
| `TrackTypeUnknown` | 0 | Unknown |
| `TrackTypeVideo` | 1 | Video track |
| `TrackTypeAudio` | 2 | Audio track |
| `TrackTypeSubtitle` | 3 | Subtitle track |
| `TrackTypeVOD` | 4 | VOD track |

### **15.8 TrackQuality (Track Quality)**

`TrackQuality` describes a selectable track (resolution/audio track, etc.), used by APIs such as `selectTrack:`, `trackQualityList`, and `selectedTrackQuality`.

| Property | Type | Description |
|----------|------|-------------|
| `index` | `NSInteger` (readonly) | Track index |
| `type` | `TrackType` (readonly) | Track type |
| `width` | `NSInteger` (readonly) | Track width (pixels) |
| `height` | `NSInteger` (readonly) | Track height (pixels) |

| Method | Parameters | Description |
|--------|------------|-------------|
| `- initWithIndex:type:width:height:` | `NSInteger` index, `TrackType` type, `NSInteger` width, `NSInteger` height | Constructor |

---

The above covers the main API interfaces for the AliPlayerKit iOS version.

For further understanding of the design and usage of each player subsystem, refer to the related documents in the **[advanced/](./advanced/)** directory.
