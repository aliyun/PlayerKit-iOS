# **Player Lifecycle Strategy**

**Player Lifecycle Strategy** is a core architectural design in AliPlayerKit that provides unified management of player instance **creation, reuse, recycling, and destruction**, enabling more efficient resource scheduling and performance optimization across different business scenarios.

---

## **1. Concept Introduction**

### **1.1 What is a Player Lifecycle Strategy?**

A Player Lifecycle Strategy is an architectural mechanism for managing the lifecycle of player instances. It defines core operations such as acquiring, recycling, and clearing player instances, decoupling player resource management from business code.

Different business scenarios have different requirements for player instance management:

| Scenario | Requirements | Recommended Strategy |
|----------|-------------|---------------------|
| Standard video playback | Simple and straightforward, no reuse needed | Default |
| Short video list | Frequent switching, requires fast playback start | ReusePool |
| Video preloading | ID bound to instance, supports preloading | IdScopedPool |
| Memory-sensitive scenarios | Single global instance, minimal memory footprint | Singleton |

### **1.2 Core Value**

Managing the player lifecycle through the strategy pattern provides the following key advantages:

- **Decoupling**: Business code does not need to handle player instance creation and destruction details
- **Flexibility**: Switch between strategies at runtime without modifying business code
- **Extensibility**: Custom strategies can be implemented to meet specific business requirements
- **Observability**: Unified lifecycle management facilitates monitoring and debugging

### **1.3 Design Background**

The Player Lifecycle Strategy architecture originates from the **multi-instance player pool** in the **Alibaba Cloud Short Drama Solution**. In short drama scenarios, users rapidly swipe through videos in a feed, placing extremely high demands on player performance: **fast first frame, smooth transitions, and controllable memory usage**.

AliPlayerKit abstracts this practical experience into a **strategy pattern**, forming a more general and flexible player lifecycle management architecture.

---

## **2. Features**

### **2.1 Core Capabilities**

| Capability | Description |
|-----------|-------------|
| Instance Acquisition | `acquirePlayer` obtains a player instance; the strategy decides whether to create or reuse |
| Instance Recycling | `recyclePlayer:force:` recycles an instance; the strategy decides whether to destroy or retain |
| Resource Cleanup | `clear` releases all player instances held by the strategy, restoring initial state |
| Preloading | `preloadWithCount:` pre-creates instances into the pool to reduce first-frame latency (`@optional`) |
| ID Binding | `acquirePlayerWithUniqueId:` obtains an instance by business unique identifier (`@optional`) |
| Factory Injection | `setupWithFactory:` injects the player factory, automatically called by `AliPlayerController` |

### **2.2 Built-in Strategies**

AliPlayerKit provides 4 built-in player lifecycle strategies:

| Strategy | Class Name | Description | Use Case |
|----------|-----------|-------------|----------|
| Default | `DefaultLifecycleStrategy` | Creates a new instance each time, destroys immediately after use | Standard playback |
| Reuse Pool | `ReusePoolLifecycleStrategy` | Maintains an idle pool, prioritizes reusing pooled instances | Short video lists |
| ID-Scoped Pool | `IdScopedPoolLifecycleStrategy` | Maintains an independent instance for each uniqueId, with LRU eviction | Video preloading |
| Singleton | `SingletonLifecycleStrategy` | Single global instance, all acquisitions return the same instance | Playlist playback, memory-sensitive scenarios |

### **2.3 Architecture Layers**

```text
┌──────────────────────────────────────────────────────────────┐
│                  AliPlayerController                          │
│       initWithLifecycleStrategy: injects strategy             │
│       configure: internally calls recycle(old) + acquire(new) │
│       destroy: internally calls recycle(player, force:YES)    │
├──────────────────────────────────────────────────────────────┤
│              PlayerLifecycleStrategy protocol                 │
│   setupWithFactory: / acquirePlayer / recyclePlayer:force:     │
│   clear / preloadWithCount: / acquirePlayerWithUniqueId:       │
├──────────────────────────────────────────────────────────────┤
│              BaseLifecycleStrategy base class                 │
│            factory / createPlayer / destroyPlayer:             │
├──────────┬──────────┬─────────────────┬──────────────────────┤
│ Default  │ReusePool │  IdScopedPool   │     Singleton        │
│ new each │ pool     │  ID-bound + LRU │     global unique    │
│  time    │ reuse    │                 │                      │
└──────────┴──────────┴─────────────────┴──────────────────────┘
│                                                                │
│              PlayerFactory protocol / DefaultPlayerFactory      │
│            createPlayer / destroyPlayer:                        │
└──────────────────────────────────────────────────────────────┘
```

---

## **3. Usage**

### **3.1 Basic Usage — Default Strategy**

The simplest usage requires no additional configuration. `AliPlayerController` uses `DefaultLifecycleStrategy` by default:

```objc
// Create controller (automatically uses default strategy)
AliPlayerController *controller = [[AliPlayerController alloc] init];

// Create playback data
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

// Configure and bind to player view
[controller configure:model];
[self.playerView attach:controller];
```

**Default strategy behavior**: Each `acquirePlayer` call creates a new instance, and each `recyclePlayer:force:` call immediately destroys the instance. No pool is maintained.

### **3.2 Reuse Pool Strategy (Short Video Scenario)**

Suitable for short video lists, feeds, and other scenarios with frequent video switching:

```objc
// 1. Create reuse pool strategy (max capacity 3)
ReusePoolLifecycleStrategy *strategy =
    [[ReusePoolLifecycleStrategy alloc] initWithMaxPoolSize:3];

// 2. Inject strategy when creating controller
//    Controller automatically calls setupWithFactory: to inject the default factory; no manual setup needed
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 3. Configure and use as normal
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
```

> **Note**: `AliPlayerController` automatically calls `[strategy setupWithFactory:[AliPlayerKit playerFactory]]` during `initWithLifecycleStrategy:` to inject the default factory. The caller does not need to manually initialize the strategy.

### **3.3 ID-Scoped Strategy (Preloading Scenario)**

Suitable for scenarios requiring preloading and multi-video switching, where the same `uniqueId` always returns the same instance:

```objc
// 1. Create ID-scoped strategy (max capacity 3)
IdScopedPoolLifecycleStrategy *strategy =
    [[IdScopedPoolLifecycleStrategy alloc] initWithMaxPoolSize:3];

// 2. Inject strategy when creating controller
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 3. Use — configure internally performs ID binding via VideoSource.uniqueId
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                              playAuth:@"your_play_auth"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];

// Next time configure is called with the same uniqueId, acquire internally hits the existing instance
```

### **3.4 Singleton Strategy (Playlist Scenario)**

A single global instance shared by all controllers:

```objc
// Get singleton strategy (dispatch_once guarantees global uniqueness)
SingletonLifecycleStrategy *strategy =
    [SingletonLifecycleStrategy sharedInstance];

// Create controller
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// All controllers using this strategy share the same player instance
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
```

> **Caution**: When using the singleton strategy, multiple `AliPlayerController` instances must not hold the player simultaneously, as this will cause state conflicts. The `init` method of `SingletonLifecycleStrategy` is marked as `NS_UNAVAILABLE`; it can only be obtained via `+sharedInstance`.

### **3.5 Scenario Reference: Playlist Playback**

`ScenePlaylistViewController` demonstrates a complete implementation of auto-continuous playback using `SingletonLifecycleStrategy`:

```objc
// Initialize player lifecycle strategy
self.lifecycleStrategy = [SingletonLifecycleStrategy sharedInstance];

// Create controller and inject strategy
self.currentController = [[AliPlayerController alloc]
    initWithLifecycleStrategy:self.lifecycleStrategy];

// Register playback completion notification (used to trigger auto-play next)
[self.currentController addNotificationDelegate:self];

// Configure data and bind (playback starts automatically after attachment)
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
[self.currentController configure:model];
[self.playerView attach:self.currentController];

// PlayerNotificationDelegate callback — auto-play next video after completion
- (void)playerDidCompletion {
    [self playNextVideo];
}
```

> **Note**: The playlist scenario reuses the player instance through `SingletonLifecycleStrategy`, avoiding performance overhead from frequent creation and destruction. When switching videos, `configure:` internally executes `recycle(old instance)` + `acquire(new instance)`, eliminating the need for manual player lifecycle management.

---

## **4. Strategy Details**

### **4.1 DefaultLifecycleStrategy**

The simplest strategy, equivalent to the original behavior before lifecycle strategies were introduced.

```objc
@interface DefaultLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>
@end
```

**Characteristics**:

- Stateless; each `acquirePlayer` creates a new instance via the factory
- Each `recyclePlayer:force:` directly destroys the instance regardless of the `force` value
- Lowest memory usage (released immediately after use)
- Suitable for most standard playback scenarios

**Core Flow**:

| Operation | Behavior |
|-----------|----------|
| `acquirePlayer` | Creates a new instance via the factory |
| `recyclePlayer:force:` | Directly destroys the instance (regardless of `force` value) |
| `clear` | No-op (no pool is maintained) |

### **4.2 ReusePoolLifecycleStrategy**

Based on the object pool pattern, maintains an idle pool and an active list.

```objc
@interface ReusePoolLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// Maximum pool capacity, defaults to 3. Instances recycled beyond this capacity are destroyed directly.
@property (nonatomic, assign) NSInteger maxPoolSize;

/// Current number of idle players in the pool
@property (nonatomic, assign, readonly) NSInteger idleCount;

/// Current number of active players (acquired but not yet recycled)
@property (nonatomic, assign, readonly) NSInteger activeCount;

- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize NS_DESIGNATED_INITIALIZER;

@end
```

**Characteristics**:

- Prioritizes reuse from the idle pool, reducing player initialization overhead
- Supports `preloadWithCount:` to pre-fill the pool
- Pool capacity controlled via `maxPoolSize`
- All methods are thread-safe
- Suitable for short video lists and feed scenarios

**Core Flow**:

| Operation | Behavior |
|-----------|----------|
| `acquirePlayer` | Takes from idle pool first; creates new instance via factory if pool is empty |
| `recyclePlayer:force:NO` | Stops playback, returns to idle pool; destroys if pool is full |
| `recyclePlayer:force:YES` | Immediately destroys the instance |
| `clear` | Destroys all instances in the idle pool; active instances are unaffected |
| `preloadWithCount:` | Pre-creates instances into the idle pool, limited by `maxPoolSize` |

### **4.3 IdScopedPoolLifecycleStrategy**

Maintains an independent player instance for each `uniqueId`. The same `uniqueId` always returns the same instance. Uses an **LRU (Least Recently Used)** mechanism to control instance count.

```objc
@interface IdScopedPoolLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// Maximum pool capacity, defaults to 3. When exceeded, LRU automatically evicts the least recently used instance.
/// When this value is reduced below the current instance count, excess instances are immediately evicted in LRU order.
@property (nonatomic, assign) NSInteger maxPoolSize;

/// Current number of player instances in the mapping table (including both active and idle)
@property (nonatomic, assign, readonly) NSInteger poolCount;

- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize NS_DESIGNATED_INITIALIZER;

@end
```

**Characteristics**:

- ID-bound; the same `uniqueId` always reuses the same instance
- LRU eviction mechanism automatically cleans up the least recently used instances
- Supports `preloadWithCount:` to pre-create unbound instances
- All methods are thread-safe
- Design inspired by the multi-instance player pool LRU management mechanism in the Alibaba Cloud Short Drama Solution
- Suitable for video preloading and multi-video switching scenarios

**Core Flow**:

| Operation | Behavior |
|-----------|----------|
| `acquirePlayerWithUniqueId:` (ID hit) | Returns existing instance, updates LRU order |
| `acquirePlayerWithUniqueId:` (ID miss) | Takes from preload queue first, otherwise creates new instance and binds ID |
| `recyclePlayer:uniqueId:force:NO` | Only stops playback, retains in mapping table (LRU handles eviction automatically) |
| `recyclePlayer:uniqueId:force:YES` | Removes from mapping table and destroys immediately |
| `clear` | Cleans up non-active instances in both the preload queue and mapping table; active instances are unaffected |
| `preloadWithCount:` | Creates instances not bound to any ID; taken when acquiring a new ID for the first time |

> **Note**: When a strategy implements the `acquirePlayerWithUniqueId:` method, `AliPlayerController` will call it preferentially over `acquirePlayer`, achieving ID binding through `VideoSource.uniqueId`. Similarly, `recyclePlayer:uniqueId:force:` takes priority over `recyclePlayer:force:`.

### **4.4 SingletonLifecycleStrategy**

Globally maintains a single player instance. Implemented as a true singleton using `dispatch_once`.

```objc
@interface SingletonLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// Get the globally shared singleton strategy instance
+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
```

**Characteristics**:

- Globally unique; all controllers using this strategy share the same player instance
- Lowest memory footprint
- `clear` destroys the current singleton player instance and sets it to nil; the next `acquirePlayer` call re-creates it
- Not suitable for simultaneous multi-video playback scenarios
- Multiple `AliPlayerController` instances must not hold the player simultaneously, as this causes state conflicts

**Core Flow**:

| Operation | Behavior |
|-----------|----------|
| `acquirePlayer` | Returns the global instance if it exists, otherwise creates one |
| `recyclePlayer:force:NO` | Only stops playback, retains instance |
| `recyclePlayer:force:YES` | Destroys the global instance |
| `clear` | Destroys the singleton player instance and sets it to nil |

### **4.5 Strategy Comparison Table**

| Strategy | Acquire Behavior | Recycle Behavior (force:NO) | Use Case | First-Frame Speed | Thread-Safe |
|----------|-----------------|---------------------------|----------|------------------|-------------|
| **Default** | New each time | Destroy immediately | Standard playback | Slow | — |
| **ReusePool** | From pool / new | Return to pool / destroy if full | Short video list | Fast | Yes |
| **IdScoped** | ID hit / preload / new | Retain in map / LRU eviction | Preloading | Fastest | Yes |
| **Singleton** | Create only once | Only stop playback | Playlist playback | Medium | — |

---

## **5. Custom Development**

### **5.1 Strategy Protocol (PlayerLifecycleStrategy)**

All lifecycle strategies conform to the `PlayerLifecycleStrategy` protocol:

```objc
@protocol PlayerLifecycleStrategy <NSObject>

@required

/// Inject the player factory (automatically called by AliPlayerController)
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/// Acquire a player instance (strategy decides whether to create or reuse)
- (id<MediaPlayer>)acquirePlayer;

/// Recycle a player instance (force:YES forces destruction, force:NO lets strategy decide)
- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force;

/// Release all player instances held by the strategy, restoring initial state
- (void)clear;

@optional

/// Preload a specified number of player instances into the pool
- (void)preloadWithCount:(NSInteger)count;

/// Acquire a player instance by business unique identifier (only implemented by IdScopedPoolLifecycleStrategy)
- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId;

/// Recycle a player instance by business unique identifier (only implemented by IdScopedPoolLifecycleStrategy)
- (void)recyclePlayer:(nullable id<MediaPlayer>)player
             uniqueId:(NSString *)uniqueId
                force:(BOOL)force;

@end
```

> **Note**: `setupWithFactory:` is automatically called by `AliPlayerController` during `initWithLifecycleStrategy:`, injecting the factory instance returned by `[AliPlayerKit playerFactory]`. Developers typically do not need to call this method manually. If preloading is needed (before creating a Controller), you can manually call `setupWithFactory:` followed by `preloadWithCount:`.

### **5.2 Strategy Base Class (BaseLifecycleStrategy)**

`BaseLifecycleStrategy` is the shared base class for all built-in strategies, providing factory management and template methods:

```objc
@interface BaseLifecycleStrategy : NSObject

/// The currently injected player factory (read-only)
@property (nonatomic, strong, readonly) id<PlayerFactory> factory;

/// Inject the player factory (idempotent; only the first call takes effect, subsequent calls log a warning and are ignored)
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/// Create a new player instance via the factory (subclasses should call this instead of calling factory directly)
- (id<MediaPlayer>)createPlayer;

/// Destroy a player instance via the factory (subclasses should call this instead of calling factory directly)
- (void)destroyPlayer:(nullable id<MediaPlayer>)player;

@end
```

> **Note**: `BaseLifecycleStrategy` itself **does not declare** conformance to the `PlayerLifecycleStrategy` protocol. Subclasses must declare conformance and implement `acquirePlayer`, `recyclePlayer:force:`, `clear`, etc. Subclasses should operate on player instances through the `createPlayer` / `destroyPlayer:` template methods rather than calling `factory` directly, ensuring operations are uniformly logged.

### **5.3 Player Factory (PlayerFactory)**

The `PlayerFactory` protocol defines the interface for creating and destroying player instances:

```objc
@protocol PlayerFactory <NSObject>

/// Create a player instance (each call creates a new instance in PlayerStateIdle state)
- (id<MediaPlayer>)createPlayer;

/// Destroy a player instance (releases all resources; logs a warning when nil)
- (void)destroyPlayer:(nullable id<MediaPlayer>)player;

@end
```

The framework includes `DefaultPlayerFactory`, which creates standard instances using the Alibaba Cloud Player SDK (AliPlayer). You can replace it with a custom factory via `[AliPlayerKit setPlayerFactory:]`.

### **5.4 Custom Strategy Example**

The following example demonstrates a simple cache strategy based on ID mapping:

```objc
@interface MyCacheLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>
@end

@implementation MyCacheLifecycleStrategy {
    NSMutableDictionary<NSString *, id<MediaPlayer>> *_playerMap;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _playerMap = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - PlayerLifecycleStrategy

- (id<MediaPlayer>)acquirePlayer {
    return [self createPlayer];
}

- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId {
    id<MediaPlayer> player = _playerMap[uniqueId];
    if (!player) {
        player = [self createPlayer];
        _playerMap[uniqueId] = player;
    }
    return player;
}

- (void)recyclePlayer:(id<MediaPlayer>)player
             uniqueId:(NSString *)uniqueId
                force:(BOOL)force {
    if (!player) return;
    if (force) {
        [_playerMap removeObjectForKey:uniqueId];
        [self destroyPlayer:player];
    } else {
        [player stop];
    }
}

- (void)recyclePlayer:(id<MediaPlayer>)player force:(BOOL)force {
    if (!player) return;
    [self destroyPlayer:player];
}

- (void)clear {
    for (id<MediaPlayer> player in _playerMap.allValues) {
        [self destroyPlayer:player];
    }
    [_playerMap removeAllObjects];
}

@end
```

Register and use:

```objc
MyCacheLifecycleStrategy *strategy = [[MyCacheLifecycleStrategy alloc] init];

AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
// controller automatically calls [strategy setupWithFactory:...] to inject the factory
```

---

## **6. Lifecycle Flow**

### **6.1 Controller-Strategy Interaction Flow**

```text
AliPlayerController initialization
    ↓
initWithLifecycleStrategy: → stores strategy reference
    ↓                       → automatically calls [strategy setupWithFactory:[AliPlayerKit playerFactory]]
    ↓
[controller configure:model]
    ↓
    ├── Has existing player? → [strategy recyclePlayer:oldInstance force:NO]
    ↓
    ├── Does strategy implement acquirePlayerWithUniqueId:?
    │   ├── YES → [strategy acquirePlayerWithUniqueId:source.uniqueId]
    │   └── NO  → [strategy acquirePlayer]
    ↓
    ├── [player setDataSource:model]
    ├── [player prepare]
    └── autoPlay ? → [player start]
    ↓
Switch video source → [controller configure:newModel]
    ↓                → recycle(old) + acquire(new) + setDataSource + prepare
    ↓
[controller destroy]
    ↓
    ├── [strategy recyclePlayer:player force:YES]
    └── controller released
```

### **6.2 Strategy Resource Cleanup Timing**

| Timing | Operation | Description |
|--------|-----------|-------------|
| Video switch | `configure:` internally recycle + acquire | Automatic, no manual operation needed |
| Controller destruction | `destroy` internally calls `recyclePlayer:force:YES` | Automatic |
| Page exit | Call `[controller destroy]` in `dealloc` | Must be called manually |
| Release pool resources | `[strategy clear]` | Call as needed (e.g., on memory warning) |

---

## **7. Best Practices**

### **7.1 Strategy Selection Guide**

| Scenario | Recommended Strategy | Reason |
|----------|---------------------|--------|
| Standard video detail page | Default | Simple and direct, released when page is destroyed |
| Short video vertical scroll list | ReusePool | Reusing instances reduces creation overhead, improves scrolling smoothness |
| Video preloading / instant playback | IdScoped | ID binding + preloading enables ultra-fast playback start |
| Continuous playlist playback | Singleton | Single global instance reduces initialization count |
| Low-end devices / memory pressure | Singleton | Globally unique, minimal memory footprint |
| Podcast / audio playback | Singleton | Single audio stream scenario does not require multiple instances |

### **7.2 Memory Management Recommendations**

| Recommendation | Description |
|---------------|-------------|
| Listen for memory warnings | Pool strategies should listen for `UIApplicationDidReceiveMemoryWarningNotification` and call `clear` |
| Set pool capacity appropriately | Each player instance uses approximately 35~40MB of memory; set `maxPoolSize` based on device capability |
| Release idle pool on background | Call `clear` when entering background to release idle instances |
| Must destroy on page dealloc | `[controller destroy]` must be called in `dealloc`, otherwise memory leaks will occur |

```objc
// Listen for memory warnings and release pool resources
[[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(handleMemoryWarning:)
           name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];

- (void)handleMemoryWarning:(NSNotification *)notification {
    [self.lifecycleStrategy clear];
}
```

### **7.3 Page Lifecycle Management**

```objc
@interface MyViewController ()
@property (nonatomic, strong) AliPlayerView *playerView;
@property (nonatomic, strong) AliPlayerController *controller;
@property (nonatomic, strong) id<PlayerLifecycleStrategy> lifecycleStrategy;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lifecycleStrategy = [[ReusePoolLifecycleStrategy alloc] initWithMaxPoolSize:3];
    self.controller = [[AliPlayerController alloc]
        initWithLifecycleStrategy:self.lifecycleStrategy];
    // ... configure + attach
}

- (void)dealloc {
    // Required: destroy controller
    if (_controller) {
        [_controller destroy];
    }
    // Optional: if this page is the last user of the strategy, release pool resources
    if (_lifecycleStrategy) {
        [_lifecycleStrategy clear];
    }
}

@end
```

### **7.4 Important Notes**

| Scenario | Recommended Approach | Reason |
|----------|---------------------|--------|
| Page destruction | Call `[controller destroy]` in `dealloc` | Prevents memory leaks |
| Strategy cleanup | Last user calls `[strategy clear]` | Releases idle instances in the pool |
| Singleton strategy | Do not have multiple Controllers hold it simultaneously | Prevents state conflicts |
| Factory injection | Do not manually call `setupWithFactory:` | Controller injects automatically, and the method is idempotent (only first call takes effect) |
| Preloading | Call after Controller creation | Controller automatically injects the factory upon creation |

### **7.5 Common Mistakes**

```objc
// ✗ Wrong: forgetting to destroy controller in dealloc
- (void)dealloc {
    [self.playerView detach];
    // Did not call [_controller destroy], causing memory leak
}

// ✓ Correct: destroy controller and optionally clean up strategy
- (void)dealloc {
    if (_controller) {
        [_controller destroy];
    }
    if (_lifecycleStrategy) {
        [_lifecycleStrategy clear];
    }
}
```

```objc
// ✗ Wrong: holding multiple Controllers simultaneously with singleton strategy
SingletonLifecycleStrategy *strategy = [SingletonLifecycleStrategy sharedInstance];
AliPlayerController *controller1 = [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
AliPlayerController *controller2 = [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
// controller1 and controller2 share the same player instance, causing state conflicts

// ✓ Correct: ensure only one Controller uses the singleton strategy at a time
[controller1 destroy];
AliPlayerController *controller2 = [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
```

```objc
// ✗ Wrong: attempting to alloc init SingletonLifecycleStrategy
SingletonLifecycleStrategy *strategy = [[SingletonLifecycleStrategy alloc] init]; // Compile error

// ✓ Correct: obtain via sharedInstance
SingletonLifecycleStrategy *strategy = [SingletonLifecycleStrategy sharedInstance];
```

---

## **8. API Reference**

### **8.1 Core Classes and Protocols**

| Protocol / Class | Description |
|-----------------|-------------|
| `PlayerLifecycleStrategy` | Lifecycle strategy protocol, defines acquire/recycle/clear interfaces |
| `BaseLifecycleStrategy` | Strategy base class, provides factory management and createPlayer/destroyPlayer: template methods |
| `PlayerFactory` | Player factory protocol, defines create/destroy interfaces |
| `DefaultPlayerFactory` | Default factory implementation, creates instances using Alibaba Cloud Player SDK |
| `MediaPlayer` | Media player protocol, defines playback control, state query, and other interfaces |

### **8.2 Built-in Strategies**

| Class | Creation Method | Key Properties |
|-------|----------------|---------------|
| `DefaultLifecycleStrategy` | `[[... alloc] init]` | — |
| `ReusePoolLifecycleStrategy` | `[[... alloc] initWithMaxPoolSize:]` | `maxPoolSize`, `idleCount`, `activeCount` |
| `IdScopedPoolLifecycleStrategy` | `[[... alloc] initWithMaxPoolSize:]` | `maxPoolSize`, `poolCount` |
| `SingletonLifecycleStrategy` | `[... sharedInstance]` | — |

### **8.3 PlayerLifecycleStrategy Methods**

| Method | Required | Description |
|--------|----------|-------------|
| `setupWithFactory:` | Yes | Inject player factory (automatically called by Controller) |
| `acquirePlayer` | Yes | Acquire a player instance |
| `recyclePlayer:force:` | Yes | Recycle a player instance |
| `clear` | Yes | Release all cached instances |
| `preloadWithCount:` | No | Preload instances (implemented by ReusePool / IdScoped) |
| `acquirePlayerWithUniqueId:` | No | Acquire instance by uniqueId (implemented by IdScoped) |
| `recyclePlayer:uniqueId:force:` | No | Recycle instance by uniqueId (implemented by IdScoped) |

### **8.4 BaseLifecycleStrategy Methods**

| Method / Property | Description |
|------------------|-------------|
| `factory` | Currently injected player factory (read-only) |
| `setupWithFactory:` | Inject factory (idempotent, only first call takes effect) |
| `createPlayer` | Create instance via factory with unified logging |
| `destroyPlayer:` | Destroy instance via factory with unified logging |

### **8.5 force Parameter Description**

| force Value | Behavior | Use Case |
|-------------|----------|----------|
| `NO` | Strategy decides: return to pool or only stop playback | Normal video switching (used internally by `configure:`) |
| `YES` | Regardless of strategy, immediately destroy instance | Controller destruction (used internally by `destroy`) |

### **8.6 uniqueId Description**

`uniqueId` is a business unique identifier property on `VideoSource`, used to distinguish different video sources. Different strategies use it differently:

| Strategy | uniqueId Usage |
|----------|---------------|
| Default | Not used |
| ReusePool | Not used |
| IdScoped | **Core identifier**, same uniqueId always returns the same instance |
| Singleton | Not used |

---

## **9. Example Reference**

> **Reference**: The `PlayerKitUsages/UsageLifecycleStrategy` module provides complete usage examples for player lifecycle strategies, demonstrating switching between the four built-in strategies (Default, ReusePool, Singleton, IdScopedPool), instance reuse behavior (NEW/REUSED/HIT) under multi-video source playback, and the resource cleanup flow for strategies and controllers.
