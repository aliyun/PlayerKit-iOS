# **Scene Type (SceneType)**

**Scene Type (SceneType)** is AliPlayerKit's playback scene abstraction mechanism that automatically adapts UI behavior, gesture controls, and slot visibility by specifying different scenes.

> **Most developers do not need to worry about this configuration**: If you are using the most common VOD scenario, there is no need to set SceneType — it defaults to `SceneTypeVOD` with full playback capabilities. You only need to explicitly specify it for **non-VOD scenarios** such as live streaming or restricted playback.

---

## **1. Concept Overview**

### **1.1 What is SceneType?**

SceneType is an enum identifier that tells the player "what business scenario it is currently running in." After setting SceneType, AliPlayerKit automatically:

- Adjusts **slot visibility** (e.g., hides the cover image in live scenarios)
- Filters **gesture behavior** (e.g., disables progress dragging and playback speed in live/restricted scenarios; disables vertical gestures in video list scenarios)
- Adapts **feature restrictions** (e.g., ensures users watch content sequentially in restricted scenarios)

Developers only need to set a single enum value, and the framework automatically handles all the above adaptations, greatly reducing the customization cost for different business scenarios.

### **1.2 Core Value**

| Value | Description |
|-------|-------------|
| Zero-config adaptation | After setting the scene, UI and interaction behaviors adjust automatically — no need to configure slots and gestures individually |
| Consistency guarantee | All player instances under the same scene maintain uniform UI standards and interaction behavior |
| Reduced customization cost | Replace dozens of lines of slot visibility + gesture filtering code with a single line |
| Extensibility | Further fine-tuning is possible through `SlotConfig` and `GestureControlSlotConfig` |

---

## **2. Features**

### **2.1 Scene Overview**

AliPlayerKit includes 5 built-in scene types that cover the vast majority of playback use cases:

| Scene | Enum Value | Description | Applicable Use Cases | Differences from VOD |
|-------|------------|-------------|---------------------|---------------------|
| VOD | `SceneTypeVOD` | Default scene with full control capabilities | Standard VOD, courses, media library | — |
| Live | `SceneTypeLive` | Real-time stream with no fixed duration; automatically disables timeline operations | Live streaming, sports events, e-commerce live | Disables progress dragging/speed control; hides cover image |
| Video List | `SceneTypeVideoList` | Disables vertical gestures to avoid conflicts with list scrolling | News feeds, short video lists | Disables volume/brightness vertical gestures; otherwise same as VOD |
| Restricted | `SceneTypeRestricted` | Prevents skipping, ensures users watch content completely | Exam monitoring, training courses | Disables progress dragging/speed control; hides cover image |
| Minimal | `SceneTypeMinimal` | Clean canvas; all controls must be implemented manually | Background playback, fully custom UI | Hides all control components and gestures |

### **2.2 Enum Definition**

```objc
// SceneType.h
typedef NS_ENUM(NSInteger, SceneType) {
    /** Video on demand scene (default) */
    SceneTypeVOD = 0,

    /** Live streaming scene */
    SceneTypeLive = 1,

    /** Video list or short video feed scene */
    SceneTypeVideoList = 2,

    /** Restricted playback scene */
    SceneTypeRestricted = 3,

    /** Minimal player page scene */
    SceneTypeMinimal = 4,
};
```

---

## **3. Scene Capability Matrix**

### **3.1 Slot Visibility**

The slot system automatically controls component visibility based on scene type. The following matrix reflects the default rules from `DefaultSlotFactory.defaultConfigs`:

| Slot | VOD | Live | VideoList | Restricted | Minimal |
|------|-----|------|-----------|------------|---------|
| `PlayerSurface` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `GestureControl` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `LandscapeHint` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `Cover` | ✓ | ✗ | ✓ | ✗ | ✗ |
| `CenterDisplay` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `PlayState` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `LogPanel` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `TopBar` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `BottomBar` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `SettingMenu` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `OptionPanel` | ✓ | ✓ | ✓ | ✓ | ✗ |

**Visibility Rules**:

- `PlayerSurface` and `PlayState`: Visible in all scenes (no `excludedScenes` configuration)
- `Cover`: Not visible in `Live`, `Restricted`, and `Minimal` scenes
- Other slots (`GestureControl`, `LandscapeHint`, `CenterDisplay`, `LogPanel`, `TopBar`, `BottomBar`, `SettingMenu`, `OptionPanel`): Only not visible in the `Minimal` scene

### **3.2 Gesture Behavior Differences**

`GestureControlSlot` internally performs scene filtering in each gesture handler method based on `currentSceneType`:

| Gesture | VOD | Live | VideoList | Restricted | Minimal |
|---------|-----|------|-----------|------------|---------|
| Single tap (show/hide control bar) | ✓ | ✓ | ✓ | ✓ | ✗ |
| Double tap (play/pause) | ✓ | ✓ | ✓ | ✓ | ✗ |
| Long press (speed playback) | ✓ | ✗ | ✓ | ✗ | ✗ |
| Horizontal drag (seek) | ✓ | ✗ | ✓ | ✗ | ✗ |
| Left vertical drag (brightness) | ✓ | ✓ | ✗ | ✓ | ✗ |
| Right vertical drag (volume) | ✓ | ✓ | ✗ | ✓ | ✗ |

**Filtering Logic**:

- **Minimal**: All gesture handler method entry points directly `return` (`handleSingleTap:` / `handleDoubleTap:` / `handleLongPress:` / `handlePan:`)
- **Live / Restricted**: Long press and horizontal drag are filtered (checked in `handleLongPress:` and `tryStartDragWithCurrentPoint:`)
- **VideoList**: Vertical drag is filtered (directly `return` when checking `SceneTypeVideoList` in `tryStartDragWithCurrentPoint:`)

---

## **4. Usage**

### **4.1 Basic Usage**

The scene type is specified via the `AliPlayerModel.sceneType` property. **It defaults to `SceneTypeVOD`** and does not need to be explicitly set.

**VOD Scene (default, no setup needed)**:

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
// model.sceneType defaults to SceneTypeVOD, no need to set

[controller configure:model];
```

**Live Scene**:

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://live.example.com/stream.m3u8"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeLive;
model.videoTitle = @"直播间";

[controller configure:model];
```

**Video List Scene**:

```objc
VideoSource *source = [VideoSource urlSourceWithUrl:videoUrl];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeVideoList;

[controller configure:model];
```

### **4.2 Detailed Scene Descriptions**

#### **4.2.1 VOD — Video on Demand (Default)**

**Applicable scenarios**: Standard video playback, online courses, media library browsing, etc.

**Capabilities**:
- Supports all 11 default slots
- Supports all 6 gesture types
- Supports progress dragging, speed control, and resolution switching
- Supports fullscreen toggle

```objc
// No need to explicitly specify SceneType — defaults to VOD
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.coverUrl = @"https://example.com/cover.jpg";
model.videoTitle = @"精彩视频";
model.autoPlay = YES;

[controller configure:model];
```

#### **4.2.2 Live — Live Streaming**

**Applicable scenarios**: Real-time live streaming, sports events, e-commerce live, etc.

**Key differences from VOD**:
- **Disabled**: Progress dragging (horizontal gesture), speed playback (long press gesture) — because live streams have no fixed duration
- **Hidden**: Cover image slot — live streams do not need a cover
- **Retained**: Single tap/double tap gestures, volume/brightness adjustment

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:liveSource];
model.sceneType = SceneTypeLive;
model.videoTitle = @"热门直播";
model.autoPlay = YES;

[controller configure:model];
```

#### **4.2.3 VideoList — Video List**

**Applicable scenarios**: Embedded videos in news feeds, short video lists, swipeable video collections, etc.

**Key differences from VOD**:
- **Disabled**: Left/right vertical drag gestures — to avoid conflicts with list `UIScrollView` scrolling
- **Retained**: All other features (progress dragging, speed control, single tap/double tap/long press, etc.)

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeVideoList;
model.autoPlay = YES;

[controller configure:model];
```

#### **4.2.4 Restricted — Restricted Playback**

**Applicable scenarios**: Online exam monitoring videos, training certification courses, copyright protection scenarios, etc.

**Key differences from VOD**:
- **Disabled**: Progress dragging (horizontal gesture), speed playback (long press gesture) — ensures users watch content sequentially and completely
- **Hidden**: Cover image slot
- **Retained**: Single tap/double tap gestures, volume/brightness adjustment

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeRestricted;
model.videoTitle = @"安全培训课程";
model.autoPlay = YES;
// Usually combined with screenshot prevention
model.disableScreenshot = YES;

[controller configure:model];
```

#### **4.2.5 Minimal — Minimal Mode**

**Applicable scenarios**: Background playback, fully custom UI, preview thumbnail playback, etc.

**Key differences from VOD**:
- **Hidden**: Nearly all UI control slots (only `PlayerSurface` and `PlayState` are retained)
- **Disabled**: All gestures (`GestureControl` slot is not visible in Minimal scene, and all internal gesture handler methods directly `return`)
- **Suitable for**: Scenarios requiring fully custom playback control UI

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeMinimal;

[controller configure:model];
// All controls need to be implemented manually via controller APIs
// For example: [controller play]; [controller pause]; [controller seekTo:position];
```

---

## **5. Custom Development**

### **5.1 Slot Visibility Fine-tuning**

When the scene's preset slot visibility does not fully meet your needs, you can fine-tune it via `SlotConfig`:

```objc
// Example: Additionally hide TopBar in Live scene
SlotConfig *topBarConfig = [SlotConfig configWithSlotType:SlotTypeTopBar
                                           excludedScenes:[NSSet setWithObjects:
                                               @(SceneTypeMinimal),
                                               @(SceneTypeLive), nil]];

// Register with SlotManager (overrides the default SlotConfig for this slot type)
[playerView.slotManager registerSlotConfig:topBarConfig];
```

You can also directly hide an entire slot via `hideSlot:`, independent of scene-based logic:

```objc
// Unconditionally hide TopBar (requires calling rebuildSlots to take effect)
[playerView.slotManager hideSlot:SlotTypeTopBar];
```

> **Note**: `registerSlotConfig:` provides scene-level visibility control, while `hideSlot:` provides slot-level visibility control. Both work independently — a slot must pass both checks to be built.

### **5.2 Gesture Behavior Fine-tuning**

Gesture control supports two fine-tuning approaches:

**Approach 1**: Disable specific gestures via `SlotManager`'s element bitmask API (recommended — configure before `attach`):

```objc
// Disable long press speed control in VOD scene
[playerView.slotManager hideElements:GestureElementLongPress
                             forSlot:SlotTypeGestureControl];
```

**Approach 2**: Control directly via `GestureControlSlotConfig` (requires obtaining the slot instance after `attach`):

```objc
// Get the gesture control slot instance
GestureControlSlot *gestureSlot = (GestureControlSlot *)[playerView.slotManager slotViewForType:SlotTypeGestureControl];

// Modify configuration (takes effect immediately)
GestureControlSlotConfig *config = [GestureControlSlotConfig defaultConfig];
config.longPressEnabled = NO;
config.horizontalDragEnabled = NO;
gestureSlot.config = config;
```

> **Note**: Both approaches work independently. The element bitmask is applied during slot construction (`setupContentView` phase), while `GestureControlSlotConfig` takes effect dynamically at runtime.

### **5.3 Registering Custom Slots in Minimal Scene**

In the Minimal scene, most default slots are excluded by the scene configuration. To restore a slot, you can override its `SlotConfig`:

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeMinimal;

// Override BottomBar's scene config to remove the Minimal exclusion rule
[playerView.slotManager registerSlotConfig:
    [SlotConfig configWithSlotType:SlotTypeBottomBar]]; // No excludedScenes = visible in all scenes

[controller configure:model];
```

### **5.4 Dynamic Visibility Conditions**

Use `SlotConfig`'s `visibilityCondition` callback for runtime dynamic control:

```objc
SlotConfig *coverConfig = [SlotConfig configWithSlotType:SlotTypeCover
                                          excludedScenes:nil
                                     visibilityCondition:^BOOL{
    // Only show cover slot when a cover URL is available
    return model.coverUrl != nil;
}];

[playerView.slotManager registerSlotConfig:coverConfig];
```

> **Note**: `isVisibleInScene:` first checks `excludedScenes` (hidden if matched), then checks `visibilityCondition` (hidden if returns `NO`). The slot is only visible when both checks pass.

---

## **6. Scene Selection Guide**

### **6.1 Decision Flow**

```text
Do you need player control UI?
├── No → SceneTypeMinimal
└── Yes → Is it a live stream?
         ├── Yes → SceneTypeLive
         └── No → Is the player embedded in a scrollable list?
                   ├── Yes → SceneTypeVideoList
                   └── No → Do you need to prevent users from skipping?
                             ├── Yes → SceneTypeRestricted
                             └── No → SceneTypeVOD (default)
```

### **6.2 Scene Selection Summary**

| Business Requirement | Recommended Scene | Key Reason |
|---------------------|-------------------|------------|
| Standard video playback | `SceneTypeVOD` | Default scene with full feature support |
| Live/sports real-time stream | `SceneTypeLive` | Automatically disables meaningless progress operations |
| Video embedded in UIScrollView | `SceneTypeVideoList` | Automatically avoids vertical gesture conflicts |
| Training/exam/copyright protection | `SceneTypeRestricted` | Automatically prevents skipping and speed control |
| Fully custom UI | `SceneTypeMinimal` | Clean canvas with zero built-in UI interference |
| Background/Picture-in-Picture playback | `SceneTypeMinimal` | No UI control components needed |

---

## **7. API Quick Reference**

### **7.1 SceneType Enum**

| Enum Value | Integer Value | Description |
|------------|--------------|-------------|
| `SceneTypeVOD` | 0 | Video on demand scene (default) |
| `SceneTypeLive` | 1 | Live streaming scene |
| `SceneTypeVideoList` | 2 | Video list / short video feed scene |
| `SceneTypeRestricted` | 3 | Restricted playback scene |
| `SceneTypeMinimal` | 4 | Minimal player page scene |

### **7.2 SlotConfig**

| Method / Property | Description |
|-------------------|-------------|
| `configWithSlotType:` | Creates a config with no scene exclusion (visible in all scenes) |
| `configWithSlotType:excludedScenes:` | Creates a config with specified scene exclusions |
| `configWithSlotType:excludedScenes:visibilityCondition:` | Creates a config with scene exclusion and dynamic condition |
| `slotType` | Slot type (`readonly`) |
| `excludedScenes` | Set of excluded scenes, `NSSet<NSNumber *>` (`readonly`, nullable) |
| `visibilityCondition` | Dynamic visibility condition Block (`readonly`, nullable) |
| `isVisibleInScene:` | Determines whether the slot is visible in the specified scene |

### **7.3 GestureControlSlotConfig**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `singleTapEnabled` | `BOOL` | `YES` | Whether single tap gesture is enabled |
| `doubleTapEnabled` | `BOOL` | `YES` | Whether double tap gesture is enabled |
| `longPressEnabled` | `BOOL` | `YES` | Whether long press gesture is enabled |
| `horizontalDragEnabled` | `BOOL` | `YES` | Whether horizontal drag gesture is enabled |
| `leftVerticalDragEnabled` | `BOOL` | `YES` | Whether left vertical drag gesture is enabled |
| `rightVerticalDragEnabled` | `BOOL` | `YES` | Whether right vertical drag gesture is enabled |
| `+defaultConfig` | Class method | — | Creates a default config with all gestures enabled |

### **7.4 SlotManager Scene-related APIs**

| Method | Description |
|--------|-------------|
| `registerSlotConfig:` | Registers scene visibility config for a slot type (overrides default config) |
| `unregisterSlotConfigForType:` | Removes the scene config for a specified slot type (defaults to visible after removal) |
| `slotConfigForType:` | Gets the scene visibility config for a specified slot type |
| `hideSlot:` | Hides a specified slot (slot-level, independent of scene config) |
| `showSlot:` | Shows a previously hidden slot |
| `hideElements:forSlot:` | Hides slot elements / disables gestures by bitmask |
| `showElements:forSlot:` | Shows slot elements / enables gestures by bitmask |
| `slotViewForType:` | Gets the mounted slot view instance |
| `rebuildSlots` | Rebuilds all slots (must be called after scene config changes) |

### **7.5 Related Files**

| File | Description |
|------|-------------|
| `PlayerKit/Source/Data/SceneType.h` | SceneType enum definition |
| `PlayerKit/Source/AliPlayerModel.h` | Scene type configuration entry (`sceneType` property) |
| `PlayerKit/Source/Slot/SlotConfig.h` | Slot visibility configuration |
| `PlayerKit/Source/Slot/DefaultSlotFactory.h` | Default slot provider and scene visibility rules |
| `PlayerKit/Source/Slot/SlotManager.h` | Unified slot system management entry |
| `PlayerKit/Source/Slot/SlotElements.h` | Gesture element bitmask definitions |
| `PlayerKit/Source/UI/Slots/GestureControlSlot.h` | Gesture control slot and `GestureControlSlotConfig` definition |
| `PlayerKit/Source/Slot/BaseSlot.h` | Slot base class (`currentSceneType` method) |

> For full API details, see [API Reference](../ApiReference-EN.md).

---

## **8. Best Practices**

### **8.1 Important Notes**

| Item | Description |
|------|-------------|
| Set at creation time | SceneType is specified when creating `AliPlayerModel` and should not be dynamically switched during playback |
| Prioritize list scene | Always use `SceneTypeVideoList` when the player is embedded in a `UIScrollView`/`UICollectionView` |
| Minimal requires manual control | After choosing Minimal, all playback controls must be implemented by the developer via the `AliPlayerController` API |
| Composable fine-tuning | When preset behavior does not fully meet your needs, further fine-tuning is available via `SlotConfig` and `SlotManager` |
| Live and Restricted share behavior | Both have identical gesture filtering rules (disable progress dragging and speed control); differences are only in cover image visibility (both hidden) and business semantics |

### **8.2 FAQ**

#### **Q: What is the difference between VOD and VideoList?**

The main difference is in vertical gestures: `SceneTypeVideoList` disables volume/brightness vertical gestures to avoid conflicts with list container scroll gestures. All other features remain the same as VOD.

#### **Q: How to implement custom controls in Minimal scene?**

Control playback behavior directly through `AliPlayerController`'s APIs, and register custom slots to override the UI:

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeMinimal;
[controller configure:model];

// Control directly via controller API
[controller play];
[controller pause];
[controller seekTo:30000]; // Seek to 30 seconds
```

#### **Q: How to restore progress dragging in Live scene?**

If your live scenario supports timeshift (playback of past content), you can restore disabled gestures via `SlotManager`'s element control API:

```objc
// Restore horizontal drag gesture (seek)
[playerView.slotManager showElements:GestureElementHorizontalDrag
                             forSlot:SlotTypeGestureControl];
```

> **Note**: This approach only restores element-level visibility. The scene filtering logic inside `GestureControlSlot` is hardcoded, and `showElements:` cannot bypass it. For fully custom gesture behavior, consider using `GestureControlSlotConfig` or replacing `GestureControlSlot`.
