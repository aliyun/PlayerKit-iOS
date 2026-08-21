# **Notification System**

The **Notification System** is the inter-component communication infrastructure of AliPlayerKit. It adopts a **Notification Dispatcher + Delegate Protocol** pattern to distribute information such as player internal state changes, gesture interactions, and slot operations to all interested parties, achieving complete decoupling between player controllers, UI slots, and strategies.

---

## **1. Concept Introduction**

### **1.1 What is the Notification System?**

The **Notification System** is a multicast notification dispatch mechanism within PlayerKit. Each Dispatcher manages a set of weakly-referenced observers, defines callback interfaces through corresponding Delegate protocols, and observers only need to implement the methods they care about to receive the corresponding notifications.

**Core Characteristics**:

- **Multicast Dispatch**: Each Dispatcher supports registering multiple observers, broadcasting notifications to all registered observers
- **Weak Reference Management**: Observers are stored via `NSHashTable` with weak references, automatically cleaned up after object deallocation
- **Instance-Level Isolation**: Each `AliPlayerController` holds an independent Dispatcher instance, notifications from different player instances do not interfere with each other
- **Exception Isolation**: Each observer invocation is wrapped with `@try/@catch`, a single observer's exception does not affect other observers

### **1.2 Problems Solved**

| Problem | Notification System Solution |
|---------|------------------------------|
| High coupling from direct dependencies between components | Communication through Delegate protocols, no direct references between components |
| Notification confusion with multiple player instances | Each Controller holds an independent Dispatcher instance, naturally isolated |
| UI and business logic intertwined | State notifications distributed downward, separation of concerns |
| Subscriber leaks | `NSHashTable` weak reference auto-management, automatic cleanup after object deallocation |

### **1.3 Core Architecture**

The PlayerKit Notification System consists of three sets of Dispatcher + Delegate protocols:

```text
┌───────────────────────────────────────────────────────────────────┐
│                     AliPlayerController                            │
│                                                                   │
│  ┌─────────────────────────────────┐                              │
│  │ PlayerNotificationDispatcher    │──▶ PlayerNotificationDelegate │
│  └─────────────────────────────────┘                              │
│                                                                   │
│  ┌─────────────────────────────────┐                              │
│  │ GestureNotificationDispatcher   │──▶ GestureNotificationDelegate│
│  └─────────────────────────────────┘                              │
│                                                                   │
│  ┌─────────────────────────────────┐                              │
│  │ SlotActionNotificationDispatcher│──▶ SlotActionNotificationDele.│
│  └─────────────────────────────────┘                              │
└───────────────────────────────────────────────────────────────────┘
        │                   │                    │
        ▼                   ▼                    ▼
   [Observer A]        [Observer B]         [Observer C]
   (Slot/Strategy)     (Slot/Strategy)      (Slot/Strategy)
```

| Dispatcher | Delegate Protocol | Responsibility | Access Method |
|-----------|-------------------|----------------|---------------|
| `PlayerNotificationDispatcher` | `PlayerNotificationDelegate` | Player core notifications: state, progress, errors, snapshots, fullscreen, controls, loading, display modes, tracks | Via Controller's `addNotificationDelegate:` |
| `GestureNotificationDispatcher` | `GestureNotificationDelegate` | Gesture notifications: single tap, long press, brightness slide, volume slide | Injected into built-in slots by `SlotHostLayout` |
| `SlotActionNotificationDispatcher` | `SlotActionNotificationDelegate` | Slot action notifications: settings menu, speed panel, quality panel, seek preview, chapter panel | Injected into built-in slots by `SlotHostLayout` |

> **Note**: `AliPlayerController` only exposes the registration entry for `PlayerNotificationDelegate` (`addNotificationDelegate:` / `removeNotificationDelegate:`). `GestureNotificationDispatcher` and `SlotActionNotificationDispatcher` are internal slot communication mechanisms, automatically injected by `SlotHostLayout` during slot construction, and are not publicly exposed.

> **Cross-Platform Differences**: The Android side uses a global event bus (`PlayerEventBus`) + `playerId` isolation publish-subscribe pattern. The iOS side uses instance-level Dispatcher + Delegate pattern, which better aligns with the Cocoa programming paradigm. Both sides are functionally equivalent, differing only in communication mechanism.

---

## **2. Three Dispatcher Groups**

### **2.1 PlayerNotificationDispatcher**

The player core notification dispatcher, responsible for distributing playback state changes, progress updates, error notifications, and other information to all observers.

**Core Properties and Methods:**

| Interface | Description |
|-----------|-------------|
| `playerId` | Unique identifier of the notification source player (`NSString`, read-write), written by Controller after configuring `MediaPlayer` |
| `addObserver:` | Add an observer conforming to `PlayerNotificationDelegate` (weak reference, duplicate additions have no effect) |
| `removeObserver:` | Remove a specified observer (no effect if not registered) |
| `removeAllObservers` | Remove all observers |
| `notifyObservers:` | Dispatch notification Block to all observers |
| `notifyObservers:withBlock:` | Dispatch only to observers that implement the specified selector (selector filtering) |
| `observerCount` | Return the number of currently active observers |

**Convenience Dispatch Methods (called internally by Controller):**

| Method | Trigger Scenario |
|--------|-----------------|
| `dispatchDidChangeState:` | Player state change |
| `dispatchDidPreparedWithDuration:` | Preparation complete |
| `dispatchDidRenderFirstFrame` | First frame rendered |
| `dispatchDidCompletion` | Playback complete |
| `dispatchDidUpdatePosition:duration:bufferedPosition:` | Progress update |
| `dispatchDidEncounterError:` | Error occurred |
| `dispatchDidCaptureScreenImage:` | Snapshot complete |
| `dispatchDidChangeVideoWidth:height:` | Video size change |
| `dispatchFullscreenChanged:` | Fullscreen state change |
| `dispatchDidLoadingBegin` | Buffering started |
| `dispatchDidLoadingEnd` | Buffering ended |
| `dispatchDidUpdateLoadingProgress:` | Buffering progress update |
| `dispatchDidChangeMirrorMode:` | Mirror mode change |
| `dispatchDidChangeScaleMode:` | Scale mode change |
| `dispatchDidChangeRotateMode:` | Rotation mode change |
| `dispatchDidTrackReady:` | Track info ready |
| `dispatchDidTrackChanged:` | Track switch complete |

> **Note**: `PlayerNotificationDelegate` defines 22 `@optional` callback methods, but the Dispatcher provides 17 convenience dispatch methods. The `playerDidChangeControlsVisible:` notification is dispatched by `GestureControlSlot` through the generic `notifyObservers:withBlock:` method, rather than a dedicated convenience method.

### **2.2 GestureNotificationDispatcher**

The gesture notification dispatcher, created and owned by `GestureControlSlot`. After recognizing gestures, it distributes gesture semantic information to all observers.

**Core Methods:**

| Interface | Description |
|-----------|-------------|
| `addObserver:` | Add an observer conforming to `GestureNotificationDelegate` |
| `removeObserver:` | Remove a specified observer |
| `removeAllObservers` | Remove all observers |
| `notifyObservers:` | Dispatch notification Block to all observers |
| `observerCount` | Return the number of currently active observers |

**Characteristics**:

- Callback parameters focus on "data needed for display" (e.g., brightness/volume percentages), rather than raw gesture coordinate information
- Injected by `SlotHostLayout` into slots that need to respond to gestures, such as `TopBarSlot`, `BottomBarSlot`, `CenterDisplaySlot`, during slot construction

### **2.3 SlotActionNotificationDispatcher**

The slot action notification dispatcher, created and managed by `SlotHostLayout`. Used to decouple direct method calls between slots (e.g., `TopBarSlot` / `BottomBarSlot` triggering `SettingMenuSlot`).

**Core Methods:**

| Interface | Description |
|-----------|-------------|
| `addObserver:` | Add an observer conforming to `SlotActionNotificationDelegate` |
| `removeObserver:` | Remove a specified observer |
| `removeAllObservers` | Remove all observers |
| `notifyObservers:` | **Asynchronously** dispatch notification Block to all observers |
| `observerCount` | Return the number of currently active observers |

**Characteristics**: Unlike other Dispatchers, `SlotActionNotificationDispatcher` always dispatches notifications asynchronously via `dispatch_async(dispatch_get_main_queue(), ...)`, avoiding UI freezes caused by synchronously executing heavyweight UI operations within button event handling chains.

---

## **3. Usage**

### **3.1 Register via Controller (Recommended)**

`AliPlayerController` provides convenience methods to register `PlayerNotificationDelegate` observers. This is the most common subscription approach:

```objc
@interface MyViewController () <PlayerNotificationDelegate>
@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.controller = [[AliPlayerController alloc] init];

    // Register as notification observer
    [self.controller addNotificationDelegate:self];

    // Configure and bindplayer...
    [self.controller configure:model];
    [self.playerView attach:self.controller];
}

- (void)dealloc {
    // Recommended to explicitly remove observer
    [self.controller removeNotificationDelegate:self];
    [self.controller destroy];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // Update play/pause button state
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // Update progress bar
}

- (void)playerDidEncounterError:(NSError *)error {
    // Display error message
}

@end
```

**Controller Registration Entry:**

| Method | Description |
|--------|-------------|
| `addNotificationDelegate:` | Add an observer conforming to `PlayerNotificationDelegate` protocol, held with weak reference |
| `removeNotificationDelegate:` | Remove a previously added notification observer |

> **Note**: Observers are stored via `NSHashTable` with weak references and are automatically removed from the list after the observer object is deallocated. However, it is recommended to explicitly call `removeNotificationDelegate:` in `dealloc` to ensure timely cleanup.

### **3.2 Internal Slot Communication (Advanced)**

`GestureNotificationDispatcher` and `SlotActionNotificationDispatcher` are internal slot communication mechanisms, provided to built-in slots by `SlotHostLayout` through property injection during slot construction.

Custom slots that need to receive gesture or slot action notifications can declare corresponding Dispatcher properties, which are injected by `SlotHostLayout` for use:

```objc
@interface MyCustomSlot : UIView <SlotProtocol, GestureNotificationDelegate, SlotActionNotificationDelegate>

@property (nonatomic, weak, nullable) GestureNotificationDispatcher *gestureDispatcher;
@property (nonatomic, weak, nullable) SlotActionNotificationDispatcher *slotActionDispatcher;

@end

@implementation MyCustomSlot

- (void)setGestureDispatcher:(GestureNotificationDispatcher *)gestureDispatcher {
    if (_gestureDispatcher) {
        [_gestureDispatcher removeObserver:self];
    }
    _gestureDispatcher = gestureDispatcher;
    if (_gestureDispatcher) {
        [_gestureDispatcher addObserver:self];
    }
}

- (void)setSlotActionDispatcher:(SlotActionNotificationDispatcher *)slotActionDispatcher {
    if (_slotActionDispatcher) {
        [_slotActionDispatcher removeObserver:self];
    }
    _slotActionDispatcher = slotActionDispatcher;
    if (_slotActionDispatcher) {
        [_slotActionDispatcher addObserver:self];
    }
}

#pragma mark - GestureNotificationDelegate

- (void)gestureDidSingleTap {
    // Toggle controls visibility on single tap
}

- (void)gestureDidUpdateVolumeWithPercent:(CGFloat)currentPercent {
    // Display volume adjustment UI
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidRequestToggleSettingMenu {
    // Respond to settings menu toggle request
}

@end
```

> **Note**: `GestureNotificationDispatcher` is created and owned by `GestureControlSlot` (`readonly` property), and `SlotActionNotificationDispatcher` is created and owned by `SlotHostLayout`. The Dispatcher properties of slots are declared as `weak`, and are automatically injected by `SlotHostLayout` after `rebuildSlots`.

### **3.3 Complete Code Example**

The following demonstrates how a complete player page subscribes to player notifications:

```objc
@interface PlayerPageViewController () <PlayerNotificationDelegate>
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation PlayerPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.playerView];

    self.controller = [[AliPlayerController alloc] init];

    // Register as notification observer
    [self.controller addNotificationDelegate:self];

    VideoSource *source = [VideoSource vidAuthSourceWithVid:@"vid" playAuth:@"auth"];
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
    [self.controller configure:model];
    [self.playerView attach:self.controller];
}

- (void)dealloc {
    [self.controller removeNotificationDelegate:self];
    [self.controller destroy];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    NSLog(@"Playback state changed: %ld", (long)state);
}

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    NSLog(@"Preparation complete, total duration: %ld ms", (long)duration);
}

- (void)playerDidRenderFirstFrame {
    // Hide cover image
}

- (void)playerDidCompletion {
    // Show replay button
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // Update progress bar
}

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    // Update fullscreen/non-fullscreen layout
}

- (void)playerDidChangeControlsVisible:(BOOL)visible {
    // Sync controls visibility
}

- (void)playerDidEncounterError:(NSError *)error {
    NSLog(@"Playback error: %@", error.localizedDescription);
}

@end
```

> **Reference**: The `PlayerKitUsages/UsageNotificationSystem` module provides a complete notification system usage example, demonstrating how to register a `PlayerNotificationDelegate` observer and receive playback state changes, progress updates, and other notifications in real time.

---

## **4. Notification List**

### **4.1 PlayerNotificationDelegate (22 @optional Methods)**

#### **Playback State Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidChangeState:` | When player state transitions | `state` — New `PlayerState` enum value |
| `playerDidPreparedWithDuration:` | When player preparation completes | `duration` — Total media duration (milliseconds) |
| `playerDidRenderFirstFrame` | When the first video frame rendering completes | — |
| `playerDidCompletion` | When playback reaches the end of media | — |

#### **Playback Progress Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidUpdateCurrentPosition:duration:bufferedPosition:` | Called periodically during playback | `position` — Current position (ms); `duration` — Total duration (ms); `bufferedPosition` — Buffered position (ms) |

#### **Error Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidEncounterError:` | When a playback error occurs | `error` — `NSError` object |

#### **Snapshot Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidCompleteSnapshot:` | When snapshot completes | `image` — Captured `UIImage`, nil on failure |

#### **Video Size Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidChangeVideoWidth:height:` | When video size changes | `width`/`height` — Original video dimensions (pixels) |

#### **Fullscreen and Controls Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidChangeFullscreen:` | After fullscreen transition completes | `isFullscreen` — Whether currently in fullscreen |
| `playerDidChangeControlsVisible:` | When controls visibility changes | `visible` — Whether controls should be visible |

> **Note**: `playerDidChangeControlsVisible:` is triggered by `GestureControlSlot`'s single tap gesture or auto-hide timer. All controls that need synchronized visibility should implement this method to avoid state inconsistency caused by independent toggling.

#### **Loading Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidLoadingBegin` | When network stalls or buffer is insufficient | — |
| `playerDidLoadingEnd` | When buffered data is sufficient to resume playback | — |
| `playerDidUpdateLoadingProgress:` | When buffering progress changes | `progress` — Range 0-100 (`float`) |

#### **Display Mode Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidChangeMirrorMode:` | When mirror mode changes | `mirrorMode` — New `MirrorMode` |
| `playerDidChangeScaleMode:` | When scale mode changes | `scaleMode` — New `ScaleMode` |
| `playerDidChangeRotateMode:` | When rotation mode changes | `rotateMode` — New `RotateMode` |

#### **Track Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidTrackReady:` | When available track info is ready | `tracks` — `NSArray<TrackQuality *>` |
| `playerDidTrackChanged:` | When track switch completes | `quality` — The `TrackQuality` after switching |

#### **VID Info Ready Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidReadyCoverUrl:` | After Vid playback prepared, when cover URL is extracted from MediaInfo | `coverUrl` — Cover image URL (`NSString *`) |
| `playerDidReadyVideoTitle:` | After Vid playback prepared, when title is extracted from MediaInfo | `videoTitle` — Video title (`NSString *`) |
| `playerDidReadyThumbnailUrl:` | After Vid playback prepared, when thumbnail URL is extracted from MediaInfo | `thumbnailUrl` — Thumbnail URL (`NSString *`) |

#### **Thumbnail Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `playerDidRetrieveThumbnail:image:` | After calling `requestThumbnailAtPosition:` and receiving the image | `positionMs` — Requested position (`int64_t`, milliseconds); `image` — Retrieved `UIImage` |

### **4.2 GestureNotificationDelegate (7 @optional Methods)**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `gestureDidSingleTap` | Single tap gesture triggered | — |
| `gestureDidBeginLongPress` | Long press gesture begins (speed boost activated) | — |
| `gestureDidEndLongPress` | Long press gesture ends (speed restored) | — |
| `gestureDidUpdateBrightnessWithPercent:` | Left vertical drag update | `currentPercent` — Brightness value 0.0~1.0 |
| `gestureDidEndBrightnessAdjust` | Left vertical drag ends | — |
| `gestureDidUpdateVolumeWithPercent:` | Right vertical drag update | `currentPercent` — Volume value 0.0~1.0 |
| `gestureDidEndVolumeAdjust` | Right vertical drag ends | — |

### **4.3 SlotActionNotificationDelegate (7 @optional Methods)**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `slotDidRequestToggleSettingMenu` | `TopBarSlot` settings button tapped | — |
| `slotDidRequestShowSpeedPanel` | `BottomBarSlot` speed button tapped | — |
| `slotDidRequestShowQualityPanel` | `BottomBarSlot` quality button tapped | — |

#### **Seek Preview Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `slotDidBeginSeekPreview` | When user starts dragging the seek bar (triggered by BottomBarSlot) | — |
| `slotDidUpdateSeekPreview:duration:` | When target position changes during dragging | `targetPositionMs` — Target position (`int64_t`, milliseconds); `durationMs` — Total media duration (`int64_t`, milliseconds) |
| `slotDidEndSeekPreview` | When user releases to end dragging (triggered by BottomBarSlot) | — |

#### **Chapter Panel Notifications**

| Method | Trigger Timing | Parameter Description |
|--------|---------------|----------------------|
| `slotDidRequestShowChapterPanel` | When user taps the chapter button (triggered by BottomBarSlot) | — |

> **Note**: All notifications from `SlotActionNotificationDelegate` are dispatched asynchronously via `dispatch_async(dispatch_get_main_queue(), ...)`, ensuring execution in the next RunLoop iteration to avoid UI issues caused by synchronous execution within button event handling chains.

---

## **5. Instance-Level Isolation Mechanism**

### **5.1 Design Principle**

In multi-player instance scenarios (e.g., short video vertical scrolling, picture-in-picture), notifications from different players must not interfere with each other. PlayerKit achieves notification isolation through **instance granularity** rather than global filtering.

### **5.2 Isolation Approach**

Each `AliPlayerController` holds an independent `PlayerNotificationDispatcher` instance. Once an observer registers with a Controller's Dispatcher, it will only receive notifications produced by that Controller:

```text
┌── AliPlayerController (A) ──┐     ┌── AliPlayerController (B) ──┐
│  PlayerNotificationDispatcher │     │  PlayerNotificationDispatcher │
│  ├── Observer 1               │     │  ├── Observer 3               │
│  └── Observer 2               │     │  └── Observer 4               │
└───────────────────────────────┘     └───────────────────────────────┘

Observer 1/2 only receive notifications from Controller A
Observer 3/4 only receive notifications from Controller B
```

**Key Design Points**:

- No global EventBus needed, no manual `playerId` checking in callbacks
- The `PlayerNotificationDispatcher.playerId` property is for observers to identify the notification source, not for filtering
- Registration equals isolation, deregistration equals disconnection

```objc
// Controller A's notifications are only dispatched to observers registered with A
[controllerA addNotificationDelegate:slotA];  // slotA only receives A's notifications
[controllerB addNotificationDelegate:slotB];  // slotB only receives B's notifications
```

---

## **6. Custom Observer Development**

### **6.1 Implement Delegate Protocol**

Implement the required Delegate protocol, only implementing the methods you care about (all methods are `@optional`):

```objc
@interface MyAnalyticsObserver : NSObject <PlayerNotificationDelegate>
@end

@implementation MyAnalyticsObserver

- (void)playerDidChangeState:(PlayerState)state {
    [self trackStateChange:state];
}

- (void)playerDidEncounterError:(NSError *)error {
    [self reportError:error];
}

- (void)playerDidCompletion {
    [self trackPlaybackComplete];
}

@end
```

### **6.2 Registration and Deregistration**

```objc
// Create observer
MyAnalyticsObserver *observer = [[MyAnalyticsObserver alloc] init];

// Register: via Controller convenience entry
[controller addNotificationDelegate:observer];

// Deregister: explicitly remove
[controller removeNotificationDelegate:observer];
```

> **Note**: Although `NSHashTable` weak references will automatically clean up after observer deallocation, it is recommended to explicitly call `removeNotificationDelegate:` to ensure timely cleanup and avoid receiving unexpected notifications during the brief window before the observer is deallocated.

### **6.3 Thread Safety Mechanism**

| Feature | Description |
|---------|-------------|
| Observer Storage | `NSHashTable weakObjectsHashTable` weak reference storage |
| List Access | `PlayerNotificationDispatcher` is protected by `os_unfair_lock`; `GestureNotificationDispatcher`/`SlotActionNotificationDispatcher` are protected by a serial dispatch queue (`dispatch_queue_t`) — all thread-safe |
| Callback Thread | Notifications are always dispatched on the **main thread** (`SlotActionNotificationDispatcher` uses asynchronous main thread) |
| Exception Isolation | Each observer invocation is wrapped with `@try/@catch`, a single observer's exception does not affect other observers |
| Duplicate Addition | Adding the same observer repeatedly has no effect |
| No-op Safety | Removing an unregistered observer has no effect |

**Dispatch Flow:**

```text
PlayerNotificationDispatcher / GestureNotificationDispatcher:
    dispatch method called
        → Obtain observer snapshot within serial queue (thread-safe)
        → Invoke observer callbacks one by one on main thread
        → Each invocation wrapped with @try/@catch (exception isolation)

SlotActionNotificationDispatcher:
    notifyObservers: called
        → Obtain observer snapshot within serial queue (thread-safe)
        → dispatch_async(dispatch_get_main_queue(), ...) asynchronous dispatch
        → Invoke observer callbacks one by one in the next RunLoop
        → Each invocation wrapped with @try/@catch (exception isolation)
```

---

## **7. API Quick Reference**

### **7.1 Dispatcher Classes**

| Class | Key Methods | Description |
|-------|-------------|-------------|
| `PlayerNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` / `notifyObservers:` / `notifyObservers:withBlock:` | Player notification dispatcher, includes `playerId` property and selector-filtered dispatch |
| `GestureNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` / `notifyObservers:` | Gesture notification dispatcher |
| `SlotActionNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` / `notifyObservers:` | Slot action notification dispatcher (asynchronous dispatch) |

### **7.2 Delegate Protocols**

| Protocol | Method Count | Responsibility Scope |
|----------|-------------|---------------------|
| `PlayerNotificationDelegate` | 22 `@optional` methods | Playback state, progress, errors, snapshots, fullscreen, controls, loading, display modes, tracks, VID info, thumbnails |
| `GestureNotificationDelegate` | 7 `@optional` methods | Single tap, long press, brightness adjustment, volume adjustment |
| `SlotActionNotificationDelegate` | 7 `@optional` methods | Settings menu toggle, speed panel, quality panel, seek preview, chapter panel |

### **7.3 Controller Entry Points**

| Method | Description |
|--------|-------------|
| `addNotificationDelegate:` | Register a `PlayerNotificationDelegate` observer (weak reference) |
| `removeNotificationDelegate:` | Remove a `PlayerNotificationDelegate` observer |

### **7.4 Common Dispatcher Methods**

| Method | Description |
|--------|-------------|
| `addObserver:` | Add an observer (weak reference, duplicate additions have no effect) |
| `removeObserver:` | Remove a specified observer (no effect if not registered) |
| `removeAllObservers` | Clear all observers |
| `notifyObservers:` | Dispatch notification Block to all observers |
| `observerCount` | Return the number of currently active observers |

### **7.5 PlayerNotificationDispatcher Exclusive Methods**

| Method | Description |
|--------|-------------|
| `notifyObservers:withBlock:` | Dispatch only to observers that implement the specified selector (selector filtering) |
| `dispatchDidChangeState:` and 17 other convenience methods | Convenience dispatch for player state, progress, errors, snapshots, fullscreen, loading, display modes, and tracks |
