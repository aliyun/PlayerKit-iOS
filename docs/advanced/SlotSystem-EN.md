# **Slot System**

The **Slot System** is the core architectural design of AliPlayerKit. Through componentization and a pluggable mechanism, it decomposes the player UI into multiple independent slot components managed and orchestrated by a unified system, achieving decoupling, composition, and flexible extensibility for the player interface.

---

## **1. Concept Overview**

### **1.1 What is a Slot?**

A **Slot** is the fundamental building unit of the player UI. Each slot represents an independent interface component responsible for a specific part of the player interface, such as the top control bar, bottom progress bar, cover image, or notification messages.

All slots are stacked according to a predefined **Z-Order hierarchy**, collectively forming the complete player interface. Each slot focuses solely on its own UI presentation and interaction logic, resulting in a clear-responsibility, fine-grained interface structure.

### **1.2 What is the Slot System?**

The **Slot System** is the architectural mechanism for unified management of these slot components.

It is responsible for defining the **registration mechanism, lifecycle management, scene adaptation, and rendering order** of slots, and uniformly manages slot creation, display, hiding, and destruction during player operation.

Based on this mechanism, developers can flexibly build player interfaces like assembling building blocks: use the system-provided default slots to quickly set up the player UI, selectively replace or extend specific slots as needed, or fully customize all components to achieve a highly customized player interface.

### **1.3 Core Value**

| Usage Approach | Description | Advantage |
|---------|------|------|
| Use default interface | Zero configuration, works out of the box | Simplified integration, low-code setup |
| Customize partial slots | Only replace slots that need customization, keep others as default | Partial customization while preserving default interactions |
| Fully custom interface | Replace all slot implementations | Meets brand-specific UI requirements |
| No slots | Use only playback capabilities, no UI dependency | Pure playback scenarios |

**Architecture Advantages**:

- **Decoupled**: UI components separated from player core logic, clear responsibilities
- **Flexible**: Dynamic composition and replacement of UI components at runtime
- **Extensible**: Customize UI without modifying the framework
- **Separation of Concerns**: UI styling separated from business logic

---

## **2. Features**

### **2.1 Core Capabilities**

| Capability | Description |
|-----|------|
| Dynamic Composition | Freely compose UI components at runtime |
| Hot Replacement | Replace component implementations without restart |
| Scene Adaptation | Automatically switch UI behavior for different playback scenes |
| Dual Lifecycle | Independent management of View lifecycle and Data lifecycle |

### **2.2 Built-in Slot Types**

AliPlayerKit includes 13 built-in slot types, arranged by Z-Order from bottom to top:

| Slot Type | Enum Value | Description | Default Implementation |
|---------|--------|------|---------|
| Video Surface | `SlotTypePlayerSurface` (10) | Displays player video content (bottom layer) | `PlayerSurfaceSlot` |
| Gesture Control | `SlotTypeGestureControl` (20) | Handles single tap/double tap/long press/drag | `GestureControlSlot` |
| Landscape Hint | `SlotTypeLandscapeHint` (30) | Prompts fullscreen viewing when landscape video is in portrait | `LandscapeHintSlot` |
| Cover Image | `SlotTypeCover` (40) | Displays video cover before playback | `CoverSlot` |
| Center Display | `SlotTypeCenterDisplay` (50) | Shows speed/brightness/volume status hints | `CenterDisplaySlot` |
| Play State | `SlotTypePlayState` (60) | Shows loading/error/playback completion states | `PlayStateSlot` |
| Log Panel | `SlotTypeLogPanel` (70) | Displays player logs during debugging | `LogPanelSlot` |
| Top Bar | `SlotTypeTopBar` (80) | Back button/title/settings button | `TopBarSlot` |
| Seek Thumbnail | `SlotTypeSeekThumbnail` (85) | Shows thumbnail preview when dragging progress bar | `SeekThumbnailSlot` |
| Bottom Bar | `SlotTypeBottomBar` (90) | Play-pause/progress bar/fullscreen button | `BottomBarSlot` |
| Setting Menu | `SlotTypeSettingMenu` (100) | Speed/resolution/mirror/rotation | `SettingMenuSlot` |
| Option Panel | `SlotTypeOptionPanel` (110) | Speed/resolution option popup panel (top layer) | `OptionPanelSlot` |
| Chapter Panel | `SlotTypeChapterPanel` (115) | Chapter navigation and AI content display panel | `ChapterPanelSlot` |

> **Note**: Enum values are spaced by 10 to allow inserting new types without affecting existing ordering. The enum value also determines the slot's Z-axis order (lower values are further back). Use the `SlotTypeName()` function to get a readable name for a slot type, and `SlotTypeAllBuiltinTypes()` to get an ordered array of all built-in types.

### **2.3 Z-Order Hierarchy Diagram**

```text
┌────────────────────────────────────────┐  ← Top layer
│       ChapterPanel (Chapter Panel)     │  Z=115
├────────────────────────────────────────┤
│       OptionPanel (Option Panel)       │  Z=110
├────────────────────────────────────────┤
│       SettingMenu (Setting Menu)       │  Z=100
├────────────────────────────────────────┤
│       BottomBar (Bottom Bar)           │  Z=90
├────────────────────────────────────────┤
│     SeekThumbnail (Seek Thumbnail)    │  Z=85
├────────────────────────────────────────┤
│       TopBar (Top Bar)                 │  Z=80
├────────────────────────────────────────┤
│       LogPanel (Log Panel)             │  Z=70
├────────────────────────────────────────┤
│       PlayState (Play State)           │  Z=60
├────────────────────────────────────────┤
│       CenterDisplay (Center Display)   │  Z=50
├────────────────────────────────────────┤
│       Cover (Cover Image)              │  Z=40
├────────────────────────────────────────┤
│       LandscapeHint (Landscape Hint)   │  Z=30
├────────────────────────────────────────┤
│       GestureControl (Gesture Control) │  Z=20
├────────────────────────────────────────┤
│       PlayerSurface (Video Surface)    │  Z=10
└────────────────────────────────────────┘  ← Bottom layer
```

### **2.4 Scene Adaptation**

AliPlayerKit defines 6 playback scenes, with slot visibility and behavior automatically adapting to different scenes. Scene adaptation is implemented through `SlotConfig`, and `DefaultSlotFactory` provides default configurations for all built-in slots.

| Scene | Enum Value | Description | Typical Use |
|-----|--------|------|---------|
| VOD | `SceneTypeVOD` | Video-on-demand scene, supports all features | Regular video playback |
| LIVE | `SceneTypeLive` | Live streaming scene, disables timeline operations | Real-time live streams |
| VIDEO_LIST | `SceneTypeVideoList` | List playback scene, disables vertical gestures | Feed streams, short video lists |
| RESTRICTED | `SceneTypeRestricted` | Restricted playback scene, limits seek operations | Education/training, exam monitoring |
| MINIMAL | `SceneTypeMinimal` | Minimal playback scene, shows only video surface | Background video, decorative video |
| AI_VOD | `SceneTypeAIVod` | AI video-on-demand scene, supports all VOD features | AI education, interactive VOD |

**Slot Visibility Rules** (defined by `DefaultSlotFactory.defaultConfigs`):

| Slot | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL | AI_VOD |
|------|-----|------|------------|------------|---------|--------|
| PlayerSurface | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GestureControl | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| LandscapeHint | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Cover | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ |
| CenterDisplay | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| PlayState | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| LogPanel | Configurable | Configurable | Configurable | Configurable | ✗ | Configurable |
| TopBar | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| SeekThumbnail | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ |
| BottomBar | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| SettingMenu | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| OptionPanel | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| ChapterPanel | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |

**Gesture Behavior Differences**:

| Gesture | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL | AI_VOD |
|------|-----|------|------------|------------|---------|--------|
| Single Tap | Show/hide controls | Show/hide controls | Show/hide controls | Show/hide controls | Disabled | Show/hide controls |
| Double Tap | Toggle play/pause | Toggle play/pause | Toggle play/pause | Toggle play/pause | Disabled | Toggle play/pause |
| Long Press | 2x speed playback | Disabled | 2x speed playback | Disabled | Disabled | 2x speed playback |
| Horizontal Drag | Seek progress | Disabled | Seek progress | Disabled | Disabled | Seek progress |
| Left Vertical Drag | Brightness adjustment | Brightness adjustment | Disabled | Brightness adjustment | Disabled | Brightness adjustment |
| Right Vertical Drag | Volume adjustment | Volume adjustment | Disabled | Volume adjustment | Disabled | Volume adjustment |

---

## **3. Usage**

### **3.1 Strategy One: Use Default Interface**

The simplest approach, zero configuration and works out of the box:

```objc
@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. Create the player view
    AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:playerView];

    // 2. Create the controller
    AliPlayerController *controller = [[AliPlayerController alloc] init];

    // 3. Create the data model
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
    model.sceneType = SceneTypeVOD;
    model.autoPlay = YES;

    // 4. Configure and bind (automatically uses default slots)
    [controller configure:model];
    [playerView attach:controller];
}

@end
```

### **3.2 Strategy Two: Customize Partial Slots**

Only replace slots that need customization, keep others as default:

```objc
// 1. Get the SlotManager from the player view
SlotManager *slotManager = playerView.slotManager;

// 2. Only register slots that need customization (others remain default)
[slotManager registerSlotType:SlotTypeTopBar provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomTopBarSlot alloc] initWithFrame:parentView.bounds];
}];

// 3. Configure and bind
[controller configure:model];
[playerView attach:controller];
```

### **3.3 Strategy Three: Fully Custom Interface**

Clear all default configurations and register custom slots one by one:

```objc
// 1. Get SlotManager and clear default configurations
SlotManager *slotManager = playerView.slotManager;
[slotManager clearAll];

// 2. Register all required custom slots
[slotManager registerSlotType:SlotTypePlayerSurface provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MySurfaceSlot alloc] initWithFrame:parentView.bounds];
}];
[slotManager registerSlotType:SlotTypeCover provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCoverSlot alloc] initWithFrame:parentView.bounds];
}];
// ... other slots

// 3. Bind
[controller configure:model];
[playerView attach:controller];
```

### **3.4 Slot Visibility Control**

Control show/hide without replacing slot implementations:

```objc
SlotManager *slotManager = playerView.slotManager;

// Hide an entire slot (not built during rebuildSlots)
[slotManager hideSlot:SlotTypeLogPanel];

// Show a previously hidden slot (requires rebuildSlots to take effect)
[slotManager showSlot:SlotTypeLogPanel];
[slotManager rebuildSlots];

// Check if a slot is hidden
BOOL hidden = [slotManager isSlotHidden:SlotTypeLogPanel];
```

### **3.5 Element-Level Visibility Control**

The slot system supports fine-grained visibility control over individual UI elements within a slot, implemented through bitmasks (`SlotElements.h`):

```objc
SlotManager *slotManager = playerView.slotManager;

// Hide the download button and snapshot button in the top bar
[slotManager hideElements:(TopBarElementDownload | TopBarElementSnapshot)
                  forSlot:SlotTypeTopBar];

// Hide the refresh button in the bottom bar
[slotManager hideElements:BottomBarElementRefresh
                  forSlot:SlotTypeBottomBar];

// Disable horizontal drag gesture (for GestureControl slot, hiding elements means disabling the corresponding gesture)
[slotManager hideElements:GestureElementHorizontalDrag
                  forSlot:SlotTypeGestureControl];

// Show previously hidden elements
[slotManager showElements:TopBarElementDownload
                  forSlot:SlotTypeTopBar];

// Batch set all hidden element masks for all slots (replacement mode)
[slotManager setAllHiddenElementMasks:@{
    @(SlotTypeTopBar): @(TopBarElementDownload | TopBarElementSnapshot),
    @(SlotTypeBottomBar): @(BottomBarElementRefresh),
}];

// Clear all element visibility configurations
[slotManager clearAllElementMasks];
```

**Element Bitmask Types**:

| Slot Type | Element Type | Controllable Elements |
|---------|---------|---------|
| TopBar | `TopBarElement` | Back / Title / Download / Snapshot / Settings |
| BottomBar | `BottomBarElement` | Play / Progress / Refresh / Speed |
| SettingMenu | `SettingMenuElement` | Speed / TrackInfo / Loop / Mute / MirrorMode / RotateMode / ScaleMode / Subtitle |
| CenterDisplay | `CenterDisplayElement` | Volume / Brightness / Speed |
| GestureControl | `GestureElement` | SingleTap / DoubleTap / LongPress / HorizontalDrag / LeftVerticalDrag / RightVerticalDrag |
| PlayState | `PlayStateElement` | ErrorMessage / LoadingMessage |

> **Note**: Subclasses declare default visible element combinations through `onRegisterElements`. Externally, `hideElements:forSlot:` can override default visible elements, and `showElements:forSlot:` can override default hidden elements. The final visibility is queried through `isElementVisible:`.

### **3.6 Scene Visibility Configuration**

Control slot visibility across different scenes through `SlotConfig`:

```objc
SlotManager *slotManager = playerView.slotManager;

// Configure the cover slot to be invisible in Live and Restricted scenes
SlotConfig *coverConfig = [SlotConfig configWithSlotType:SlotTypeCover
                                         excludedScenes:[NSSet setWithObjects:@(SceneTypeLive), @(SceneTypeRestricted), nil]];
[slotManager registerSlotConfig:coverConfig];

// Use visibilityCondition for dynamic visibility control (LogPanel's default creation is also gated by this switch, see DefaultSlotFactory)
SlotConfig *logConfig = [SlotConfig configWithSlotType:SlotTypeLogPanel
                                       excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]
                                  visibilityCondition:^BOOL{
    return [AliPlayerKit isLogPanelEnabled];
}];
[slotManager registerSlotConfig:logConfig];

// Remove scene visibility configuration (slot becomes visible in all scenes)
[slotManager unregisterSlotConfigForType:SlotTypeCover];

// Query configuration
SlotConfig *config = [slotManager slotConfigForType:SlotTypeCover];
BOOL visible = [config isVisibleInScene:SceneTypeLive];
```

> **Note**: `DefaultSlotFactory.defaultConfigs` provides default scene visibility configurations for all built-in slots. Use `registerSlotConfig:` to override the defaults.

---

## **4. Custom Development**

### **4.1 Slot Protocol (SlotProtocol)**

All slots must conform to `SlotProtocol`, which defines the minimal lifecycle contract for slots:

```objc
@protocol SlotProtocol <NSObject>

#pragma mark - View Lifecycle

/// Called when the slot is attached to a host
- (void)onAttach:(id<SlotHost>)host;

/// Called when the slot is detached from the host
- (void)onDetach;

#pragma mark - Data Lifecycle

/// Data binding callback
- (void)onBindData:(AliPlayerModel *)model;

/// Data unbinding callback
- (void)onUnbindData;

@end
```

`SlotProvider` is the Block type for building slot views:

```objc
typedef UIView<SlotProtocol> * _Nullable (^SlotProvider)(UIView *parentView);
```

### **4.2 Dual Lifecycle**

Slots adopt independent View lifecycle and Data lifecycle:

| Lifecycle | Callback Method | Timing | Responsibility |
|---------|---------|------|------|
| **View Start** | `onAttach:` | Triggered by `playerView.attach:` | Establish host connection, subscribe to notifications, initialize views |
| **Data Start** | `onBindData:` | After `controller.configure:` sets playback data | Bind business data (cover image, title, etc.) |
| **Data End** | `onUnbindData` | Before playback data is cleared or updated | Clean up data-related resources |
| **View End** | `onDetach` | When `playerView.detach` or slot is removed | Release all resources, disconnect all connections |

```text
┌─────────────────── Full Lifecycle ────────────────────┐
│                                                        │
│   ① onAttach:         ─── View lifecycle begins        │
│       ↓ Access host, subscribe to notifications,       │
│         initialize subviews                            │
│                                                        │
│   ② onBindData:       ─── Data lifecycle begins        │
│       ↓ Load cover image, set title,                   │
│         configure scene behavior                       │
│                                                        │
│   ③ onUnbindData      ─── Data lifecycle ends          │
│       ↓ Clear image cache, reset UI state              │
│                                                        │
│   ④ onDetach          ─── View lifecycle ends          │
│       ↓ Unsubscribe notifications, remove timers,      │
│         release all resources                          │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### **4.3 Inheriting BaseSlot (Recommended)**

`BaseSlot` is the recommended base class for all UI slots, encapsulating lifecycle management, notification subscription, scene adaptation, and other common logic.

**Core Properties**:

| Property | Type | Description |
|-----|------|------|
| `host` | `id<SlotHost>` (weak, readonly) | The host this slot is attached to |
| `slotType` | `SlotType` | The type identifier of the current slot (injected by `SlotHostLayout` during construction) |
| `safeAreaEdges` | `SlotSafeAreaEdge` | Safe area edges to respect (default `SlotSafeAreaEdgeAll`) |
| `deferContentCreation` | `BOOL` | Deferred content creation toggle |
| `contentReady` | `BOOL` (readonly) | Whether content has been created |
| `touchPassthrough` | `BOOL` | Touch passthrough toggle (default `YES`) |

**Core Methods**:

| Method | Description |
|-----|------|
| `setupContentView` | Override in subclass to create custom UI elements |
| `show` / `hide` | Visibility control |
| `showWithAnimation:` / `hideWithAnimation:` | Visibility control with animation |
| `isShowing` | Query current visibility state |
| `dismiss` | Remove slot through host for proper lifecycle management |
| `ensureContentReady` | Ensure deferred content has been created (idempotent) |
| `currentSceneType` | Safely read the current scene type |
| `onRegisterElements` | Override in subclass to declare supported elements and their default visibility |
| `isElementVisible:` | Query the final visibility of a specified element |

**Safe Area Insets (SlotSafeAreaEdge)**:

```objc
typedef NS_OPTIONS(NSUInteger, SlotSafeAreaEdge) {
    SlotSafeAreaEdgeNone   = 0,
    SlotSafeAreaEdgeTop    = 1 << 0,
    SlotSafeAreaEdgeLeft   = 1 << 1,
    SlotSafeAreaEdgeBottom = 1 << 2,
    SlotSafeAreaEdgeRight  = 1 << 3,
    SlotSafeAreaEdgeAll    = SlotSafeAreaEdgeTop | SlotSafeAreaEdgeLeft | SlotSafeAreaEdgeBottom | SlotSafeAreaEdgeRight,
};
```

`SlotHostLayout` shrinks the corresponding edge of the frame based on `safeAreaEdges` during `layoutSubviews`, allowing internal slot layout to use its own anchors to avoid areas like the notch and Home Indicator. Subclasses can set this property in `initWithFrame:`.

**Deferred Content Creation (deferContentCreation)**:

When set to `YES`, `onAttach:` will not call `setupContentView`. Content will be created on the first call to `show` or `ensureContentReady`. Suitable for infrequently used slots (e.g., SettingMenu) to avoid creating unnecessary views during initialization.

```objc
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.deferContentCreation = YES;
    }
    return self;
}
```

**Auto-Hide Delay Constant**:

```objc
FOUNDATION_EXPORT const NSTimeInterval SlotAutoHideDelay;
```

The hide delay duration (in seconds) for auto-hiding control bar slots (e.g., TopBar, BottomBar) after no interaction.

### **4.4 Complete Custom Slot Example**

**Step 1**: Create a custom slot class inheriting from `BaseSlot`:

```objc
@interface MyCustomCoverSlot : BaseSlot

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation MyCustomCoverSlot

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Optional: Configure safe area insets
        self.safeAreaEdges = SlotSafeAreaEdgeNone;
    }
    return self;
}

#pragma mark - Content Creation

- (void)setupContentView {
    _coverImageView = [[UIImageView alloc] init];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImageView.clipsToBounds = YES;
    [self addSubview:_coverImageView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self addSubview:_titleLabel];
}

#pragma mark - Lifecycle

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];
    if (model.coverUrl) {
        [_coverImageView sd_setImageWithURL:[NSURL URLWithString:model.coverUrl]];
    }
    _titleLabel.text = model.videoTitle;
    [self show];
}

- (void)onUnbindData {
    _coverImageView.image = nil;
    _titleLabel.text = nil;
    [super onUnbindData];
}

- (void)onDetach {
    [super onDetach];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidRenderFirstFrame {
    [self hideWithAnimation:YES];
}

- (void)playerDidChangeState:(PlayerState)state {
    if (state == PlayerStateError) {
        [self show];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    _coverImageView.frame = self.bounds;
    _titleLabel.frame = CGRectMake(16, self.bounds.size.height - 50,
                                   self.bounds.size.width - 32, 30);
}

@end
```

> **Note**: `BaseSlot` conforms to the `PlayerNotificationDelegate` protocol and automatically registers as the controller's notification delegate during `onAttach:`. Subclasses can directly implement callback methods of interest to receive player events without manual subscription.

**Step 2**: Register and use:

```objc
SlotManager *slotManager = playerView.slotManager;
[slotManager registerSlotType:SlotTypeCover provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomCoverSlot alloc] initWithFrame:parentView.bounds];
}];
[controller configure:model];
[playerView attach:controller];
```

### **4.5 Element-Level Visibility Declaration**

Subclasses declare supported elements and their default visibility through `onRegisterElements`:

```objc
@implementation MyCustomTopBarSlot

- (NSUInteger)onRegisterElements {
    // Return the bitmask of elements visible by default
    // Back and Title are visible by default; Download and Snapshot are hidden by default
    return TopBarElementBack | TopBarElementTitle;
}

- (void)setupContentView {
    // Decide whether to create UI based on element visibility
    if ([self isElementVisible:TopBarElementBack]) {
        // Create back button
    }
    if ([self isElementVisible:TopBarElementDownload]) {
        // Create download button (hidden by default, but can be enabled externally via showElements)
    }
}

@end
```

Merging logic of `isElementVisible:`:
1. External `hideElements:forSlot:` -> Force hide
2. External `showElements:forSlot:` -> Force show
3. No external override -> Use default value declared by `onRegisterElements`

### **4.6 Custom Slot Types (CustomSlotType)**

In addition to built-in slot types, you can insert custom slots at any position using `CustomSlotType`:

```objc
// Insert a custom slot between TopBar(80) and BottomBar(90)
CustomSlotType *type = [CustomSlotType typeWithKey:@"myCustomSlot" order:85];
[playerView.slotManager registerCustomSlotType:type provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomSlotView alloc] initWithFrame:parentView.bounds];
}];

// Check if a custom slot is registered
BOOL registered = [playerView.slotManager isCustomSlotRegistered:type];

// Get all registered custom slot types
NSArray<CustomSlotType *> *types = [playerView.slotManager customSlotTypes];

// Unregister a custom slot
[playerView.slotManager unregisterCustomSlotType:type];
```

> **Note**: `CustomSlotType` is defined by a `key` (unique identifier) and `order` (sort value). Equality is determined solely by `key`, and the same key cannot be registered more than once. Custom slots are sorted together with built-in slots by `order` during `rebuildSlots`.

### **4.7 Sending Commands from Slots**

Slots send commands to the controller through `host.controller`, implementing unidirectional data flow:

```objc
// Play/pause toggle
- (void)onPlayPauseButtonTapped {
    AliPlayerController *controller = self.host.controller;
    if (controller.playerState == PlayerStatePlaying) {
        [controller pause];
    } else {
        [controller play];
    }
}

// Seek to position
- (void)onSeekBarValueChanged:(UISlider *)slider {
    long position = (long)(slider.value * self.host.playerStateStore.duration);
    [self.host.controller seekTo:position];
}

// Fullscreen toggle
- (void)onFullscreenButtonTapped {
    BOOL isFullscreen = self.host.viewState.isFullscreen;
    [self.host.controller setFullscreen:!isFullscreen];
}
```

### **4.8 SlotBehavior (Composition Pattern)**

`SlotBehavior` uses the composition pattern, enabling non-`UIView` objects to gain slot capabilities (lifecycle management, event subscription). It is suitable for scenarios where pure logic components need to listen to player events.

```objc
@interface MyAnalyticsTracker : NSObject <PlayerNotificationDelegate>

@property (nonatomic, strong) SlotBehavior *behavior;

@end

@implementation MyAnalyticsTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        _behavior = [[SlotBehavior alloc] init];
    }
    return self;
}

- (void)attachToHost:(id<SlotHost>)host {
    [self.behavior attachToHost:host];
    // Register notification delegate through behavior; automatically unsubscribes on detach
    [self.behavior addNotificationDelegate:self toController:host.controller];
}

- (void)detach {
    [self.behavior detach];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidRenderFirstFrame {
    // Report first frame render event
}

- (void)playerDidEncounterError:(NSError *)error {
    // Report playback error
}

@end
```

**Core Advantage**: All delegates registered through `addNotificationDelegate:toController:` are automatically unregistered on `detach`, preventing memory leaks caused by manual subscription lifecycle management.

---

## **5. Host Protocol (SlotHost)**

The `SlotHost` protocol is conformed to by `SlotHostLayout` (internal implementation), providing context access for slots:

| Method/Property | Description |
|----------|------|
| `hostView` | Returns the host container view |
| `model` | Gets the current player model |
| `controller` | Gets the player controller (weak reference) |
| `playerStateStore` | Gets the player state store (read-only) |
| `viewState` | Gets the view hierarchy state (fullscreen, control bar visibility, etc.) |
| `sceneType` | Gets the current scene type |
| `setRenderView:` | Sets the render view for the player (called by `PlayerSurfaceSlot`) |
| `dismissSlotView:` | Dismisses a slot view, ensuring lifecycle management consistency |
| `allSlotViews` | Returns all mounted slot views |
| `slotViewForType:` | Gets a mounted slot view by type (O(1) lookup) |
| `slotManager` | Gets the slot manager (for element visibility queries) |
| `notifyBackPressed` | Notifies the host that the back button was pressed (in non-fullscreen state) |

> **Note**: Slots should prefer reading the scene type through `host.sceneType` or `BaseSlot.currentSceneType`, rather than chaining through `host.model.sceneType`, to avoid the implicit `SceneTypeVOD`(0) default value that could be returned when the model has not yet been bound.

---

## **6. Default Slot Factory (DefaultSlotFactory)**

`DefaultSlotFactory` centrally manages the default registration of all built-in slots:

| Class Method | Description |
|--------|------|
| `+defaultProviders` | Returns a `SlotType -> SlotProvider` factory closure mapping dictionary |
| `+defaultConfigs` | Returns the scene visibility configuration array for built-in slots (`SlotConfig` array) |

`SlotManager` fetches both datasets during initialization to complete default registration. Adding or removing built-in slots only requires modifying `DefaultSlotFactory`.

Use `SlotManager.clearAll` to clear all configurations and re-register defaults.

---

## **7. Technical Principles**

### **7.1 Slot Selection Strategy**

```text
Request to create slot → Is this type in the custom registry?
                  ├── Yes → Use custom implementation
                  └── No  → Is this type in the default registry?
                              ├── Yes → Use default implementation
                              └── No  → Skip (do not create)
```

### **7.2 Unidirectional Data Flow**

The slot system adopts a unidirectional data flow architecture where slots do not directly hold controller references:

```text
Controller → State / Event → Slot (state flows down, read-only)
Slot → Command → Controller (commands flow up, send-only)
```

- **State downstream**: Actively queried through `host.playerStateStore`, or passively received through `PlayerNotificationDelegate` callbacks
- **Commands upstream**: Playback commands invoked through `host.controller`, executed by the controller

### **7.3 Slot Isolation**

Slots are strictly prohibited from directly obtaining other slot instances or performing point-to-point communication. When one slot needs to affect another:

1. The initiating slot sends a state change through `host.controller`
2. The Controller notifies all slots interested in this change through `PlayerNotificationDelegate`

Through this "events bubble up, state sinks down" pattern, mesh-like UI coupling is avoided.

### **7.4 Bottom Bar Scene Differences**

| Control | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL | AI_VOD |
|------|-----|------|------------|------------|--------|--------|
| Play/Pause Button | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Progress Bar | Draggable | Not draggable | Draggable | Not draggable | ✗ | Draggable |
| Time Display | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Refresh Button | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Fullscreen Button | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |

---

## **8. API Quick Reference**

### **8.1 Core Protocols and Classes**

| Class/Protocol | Description |
|--------|------|
| `SlotProtocol` | Slot protocol, defines minimal lifecycle contract |
| `BaseSlot` | Slot base class, encapsulates common logic |
| `SlotManager` | Slot manager, unified registration, visibility control, and runtime access |
| `SlotHost` | Host protocol, provides context access capabilities |
| `SlotHostLayout` | Internal implementation of the host protocol (`UIView` subclass) |
| `SlotConfig` | Scene visibility configuration |
| `SlotBehavior` | Composition pattern behavior class, provides slot capabilities to non-UIView objects |
| `DefaultSlotFactory` | Default slot factory, centrally manages built-in slot registration |
| `CustomSlotType` | Custom slot type, supports insertion between built-in slots |
| `SlotType` | Built-in slot type enum |

### **8.2 SlotManager Method Quick Reference**

| Category | Method | Description |
|------|-----|------|
| Slot Registration | `registerSlotType:provider:` | Register/override built-in slot Provider |
| | `unregisterSlotType:` | Unregister a specified slot type |
| | `isRegistered:` | Check if registered |
| Custom Slots | `registerCustomSlotType:provider:` | Register a custom slot |
| | `unregisterCustomSlotType:` | Unregister a custom slot |
| | `isCustomSlotRegistered:` | Check if a custom slot is registered |
| | `customSlotTypes` | Get all registered custom slot types |
| Slot Visibility | `hideSlot:` / `showSlot:` | Hide/show entire slot |
| | `isSlotHidden:` | Check if a slot is hidden |
| Scene Visibility | `registerSlotConfig:` | Register scene visibility configuration |
| | `unregisterSlotConfigForType:` | Remove scene visibility configuration |
| | `slotConfigForType:` | Get scene visibility configuration |
| Element Visibility | `hideElements:forSlot:` | Hide specific elements within a slot |
| | `showElements:forSlot:` | Show specific elements within a slot |
| | `setHiddenElementMask:forSlot:` | Replace hidden element mask |
| | `hiddenElementMaskForSlot:` | Get hidden element mask |
| | `shownElementMaskForSlot:` | Get shown element mask |
| | `setAllHiddenElementMasks:` | Batch set all hidden element masks |
| | `clearAllElementMasks` | Clear all element visibility configurations |
| Runtime | `slotViewForType:` | Get a mounted slot view |
| | `rebuildSlots` | Rebuild all slots |
| | `clearAll` | Clear configurations and re-register defaults |

---

## **9. Example Reference**

> **Reference**: The `PlayerKitUsages/UsageSlotSystem` module provides complete slot system usage examples, demonstrating out-of-the-box default slot configuration, custom slot registration and hiding through `SlotManager`, and automatic slot lifecycle management.
