# **Strategy System**

The **Strategy System** is a core architectural design of AliPlayerKit. Through an event-driven strategy mechanism, it encapsulates player monitoring, analysis, and optimization logic into independent strategy components, achieving decoupling, reuse, and flexible extension of player business logic.

------

## **1. Concept Introduction**

### **1.1 What is a Strategy?**

A **Strategy** is an independent encapsulation unit for player business logic, carrying specific business capabilities or custom logic, such as first-frame time measurement, stutter detection, traffic protection, resume playback, etc.

**Core Characteristics**:

- **Single Responsibility**: Each strategy focuses on one clear functional goal
- **Event-Driven**: Subscribes to player events through the `PlayerNotificationDelegate` protocol, executing reactively
- **Independent Isolation**: Strategies are independent and do not interfere with each other; each strategy's execution is isolated via `@try/@catch`

### **1.2 What is the Strategy System?**

The **Strategy System** is an architectural mechanism for unified management of strategy components.

It is responsible for defining the **registration mechanism, lifecycle management, context injection, and event subscription** of strategies, and uniformly manages the creation, startup, reset, and destruction of strategies during player runtime.

Based on this mechanism, developers can enable or disable specific strategies on demand, quickly implement custom strategies, or even completely replace default strategies to meet customization needs for different business scenarios.

### **1.3 Core Value**

| Usage Approach       | Description                                       | Advantage                                      |
| -------------------- | ------------------------------------------------- | ---------------------------------------------- |
| Use Default Strategies | Player components use official default strategies | Simplifies integration, works out of the box   |
| Custom Strategies      | Implement strategies for specific business needs  | Meets various customization requirements       |
| No Strategies          | Use only playback capabilities                    | Pure playback scenarios, no logic dependencies |

**Architecture Advantages**:

- **Decoupling**: Strategies are separated from player core logic, with clear responsibilities
- **Reuse**: Strategies can be reused across different player instances
- **Extensible**: Custom strategies can be added without modifying the framework
- **Isolation**: Strategies are independent; a single strategy's exception does not affect others

------

## **2. Features**

### **2.1 Core Capabilities**

| Capability           | Description                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------------- |
| Event-Driven         | Strategies subscribe to player events by implementing the `PlayerNotificationDelegate` protocol, executing reactively |
| Lifecycle Management | Unified management of strategy startup, stop, reset, and destruction                            |
| Context Injection    | Strategies can access the player controller, playback model, and state store via `StrategyContext` |
| Factory Pattern      | Register global strategy factories through `StrategyRegistry`, automatically applied to all newly created player instances |
| Error Isolation      | Each strategy's lifecycle calls are isolated via `@try/@catch`; a single strategy's exception does not affect others |

### **2.2 Built-in Strategies**

| Strategy             | Class Name                  | Description                                           | Trigger Condition                  |
| -------------------- | --------------------------- | ----------------------------------------------------- | ---------------------------------- |
| First Frame Time     | `FirstFrameStrategy`        | Measures time from PREPARING to first frame rendering | Automatically starts when player prepares |
| Stutter Detection    | `StutterDetectStrategy`     | Detects stutter count and duration during playback    | Starts monitoring after first frame renders |
| Traffic Protection   | `TrafficProtectionStrategy` | Cellular network status detection and change notification | Triggered on network status change |

> **Note**: Built-in strategies are automatically registered when `StrategyRegistry` is first accessed. Each time a new `AliPlayerController` is created, all registered factories are instantiated and injected into the controller's `StrategyManager` via `applyToManager:`, ensuring each controller has independent strategy instances.

#### **2.2.1 First Frame Strategy (FirstFrameStrategy)**

Measures player first frame rendering time, divided into three phases:

| Phase         | Description                  | Event Interval                     |
| ------------- | ---------------------------- | ---------------------------------- |
| Prepare Phase | Video parsing, network requests | `PREPARING` → `Prepared`           |
| Render Phase  | Decoding, rendering first frame | `Prepared` → `FirstFrameRendered`  |
| Total Time    | Complete first frame duration   | `PREPARING` → `FirstFrameRendered` |

Obtain timing data through `FirstFrameStrategyDelegate`:

```objc
@protocol FirstFrameStrategyDelegate <NSObject>
@optional

- (void)firstFrameStrategy:(FirstFrameStrategy *)strategy
       didRenderFirstFrameWithPrepareTime:(NSInteger)prepareTimeMs
                               renderTime:(NSInteger)renderTimeMs
                                totalTime:(NSInteger)totalTimeMs;
@end
```

```objc
FirstFrameStrategy *strategy = [[FirstFrameStrategy alloc] init];
strategy.delegate = self;
[controller.strategyManager registerStrategy:strategy];
```

#### **2.2.2 Stutter Detection Strategy (StutterDetectStrategy)**

Monitors Loading states during playback and tracks stutter occurrences. Loading events before first frame rendering are not counted as stutters.

| Metric              | Property                 | Description                                          |
| ------------------- | ------------------------ | ---------------------------------------------------- |
| Stutter Count       | `stutterCount`           | Number of Loading occurrences (counted after first frame) |
| Total Stutter Duration | `totalStutterDurationMs` | Total stutter duration across the playback session (ms) |
| Stutter Threshold   | `stutterThresholdMs`     | Only counts as stutter if exceeding this duration (default 0) |

Obtain callbacks through `StutterDetectStrategyDelegate`:

```objc
@protocol StutterDetectStrategyDelegate <NSObject>
@optional

/// A stutter was detected
- (void)stutterDetectStrategy:(StutterDetectStrategy *)strategy
                   didStutter:(NSInteger)durationMs;

/// Playback session analysis completed
- (void)stutterDetectStrategy:(StutterDetectStrategy *)strategy
            didAnalyzeSession:(NSInteger)stayDurationMs
            validPlayDuration:(NSInteger)validPlayDurationMs
         totalStutterDuration:(NSInteger)totalStutterDurationMs
                 stutterCount:(NSInteger)stutterCount;
@end
```

```objc
// Create stutter detection strategy (optionally specify threshold)
StutterDetectStrategy *strategy = [[StutterDetectStrategy alloc] initWithThreshold:500];
strategy.delegate = self;
[controller.strategyManager registerStrategy:strategy];
```

#### **2.2.3 Traffic Protection Strategy (TrafficProtectionStrategy)**

Monitors network status changes and sends notifications when the device is detected to be playing video over a cellular network. This strategy only performs detection and logging; it does not automatically pause playback.

| Scenario                    | Behavior                                     |
| --------------------------- | -------------------------------------------- |
| WiFi → Cellular             | Notifies via delegate                        |
| Cellular at playback start  | Notifies via delegate                        |
| Cellular → WiFi             | Notifies via delegate, resets prompt flag    |

```objc
@protocol TrafficProtectionStrategyDelegate <NSObject>
@optional

/// Cellular network detected
- (void)trafficProtectionStrategyDidDetectCellularNetwork:(TrafficProtectionStrategy *)strategy;

/// Switch back to Wi-Fi detected
- (void)trafficProtectionStrategyDidDetectWifiNetwork:(TrafficProtectionStrategy *)strategy;
@end
```

The application layer can query the current network status via the `isOnCellularNetwork` property:

```objc
TrafficProtectionStrategy *strategy = (TrafficProtectionStrategy *)
    [controller.strategyManager strategyWithName:@"TrafficProtectionStrategy"];
if (strategy.isOnCellularNetwork) {
    // Show traffic usage prompt
}
```

------

## **3. Usage**

### **3.1 Using Default Strategies (Simplest Integration)**

Default strategies (first frame, stutter detection, traffic protection) are automatically registered when creating an `AliPlayerController`:

```objc
// Create controller (default strategies are automatically registered)
AliPlayerController *controller = [[AliPlayerController alloc] init];

// Configure playback data
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"vid" playAuth:@"auth"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];

// Attach to view (strategies start automatically)
[self.playerView attach:controller];
```

### **3.2 Registering Custom Strategies**

Register additional strategies on a specific Controller:

```objc
AliPlayerController *controller = [[AliPlayerController alloc] init];

// Register first frame strategy with delegate callback
FirstFrameStrategy *firstFrame = [[FirstFrameStrategy alloc] init];
firstFrame.delegate = self;
[controller.strategyManager registerStrategy:firstFrame];

// Register stutter detection strategy with threshold
StutterDetectStrategy *stutter = [[StutterDetectStrategy alloc] initWithThreshold:200];
stutter.delegate = self;
[controller.strategyManager registerStrategy:stutter];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
[controller configure:model];
[self.playerView attach:controller];
```

### **3.3 Global Strategy Factory Registration**

Strategy factories registered through `StrategyRegistry` are automatically applied to all newly created Controllers:

```objc
// Register global strategies in AppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [AliPlayerKit setup];

    // Register global custom strategy factory
    [[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
        return [[MyAnalyticsStrategy alloc] init];
    }];

    return YES;
}

// All AliPlayerControllers created afterwards will automatically have this strategy registered
```

> **Note**: `StrategyFactory` creates a new strategy instance each time it is called, ensuring each controller has an independent strategy object and avoiding shared state.

### **3.4 Selective Strategy Usage**

```objc
// Clear default strategies (including built-in ones); subsequently created Controllers will not have any strategies auto-registered
[[StrategyRegistry sharedRegistry] clearGlobalStrategies];

// Only need first frame measurement
[[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
    return [[FirstFrameStrategy alloc] init];
}];

// Restore default built-in strategy configuration
[[StrategyRegistry sharedRegistry] resetToDefault];
```

### **3.5 Global Registration vs. Local Registration**

| Registration Method | Description                                          | Use Case                                     |
| ------------------- | ---------------------------------------------------- | -------------------------------------------- |
| **Global Registration** | Register factories through `StrategyRegistry`    | Common strategies like first frame, stutter detection |
| **Local Registration**  | Call `strategyManager.registerStrategy:` directly | Business strategies for specific scenarios   |

```objc
// Global registration: automatically loaded for all newly created Controllers
[[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
    return [[MyAnalyticsStrategy alloc] init];
}];

// Local registration: loaded only for the current Controller
AliPlayerController *controller = [[AliPlayerController alloc] init];
[controller.strategyManager registerStrategy:[[MySpecialStrategy alloc] init]];
```

> **Note**: Global registration only affects Controllers created after registration; already created Controllers are not affected. Registering a strategy with the same name replaces the existing instance.

------

## **4. Custom Development**

### **4.1 Strategy Protocol (StrategyProtocol)**

All strategies must conform to `StrategyProtocol`, which defines the strategy lifecycle contract:

```objc
@protocol StrategyProtocol <NSObject>

@required

/// Unique identifier name for the strategy (registering a strategy with the same name replaces the existing instance)
- (NSString *)strategyName;

/// Strategy starts, binds to player context
- (void)strategyDidStart:(StrategyContext *)context;

/// Strategy stops, unbinds from player context
- (void)strategyDidStop;

/// Strategy resets, updates context and clears internal state (called when video source switches)
- (void)strategyDidReset:(StrategyContext *)context;

@end
```

> **Note**: `strategyDidReset:` is a `@required` method. It is called by `StrategyManager` when the same controller switches video sources (re-`configure:`). The strategy should reset internal counters and temporary state while keeping event subscriptions intact.

### **4.2 Strategy Context (StrategyContext)**

`StrategyContext` is created by `StrategyManager` and passed to the strategy at startup, providing read-only player environment information:

```objc
@interface StrategyContext : NSObject

/// Associated player controller (weak reference)
@property (nonatomic, weak, readonly) AliPlayerController *controller;

/// Current playback configuration model
@property (nonatomic, strong, readonly) AliPlayerModel *playerModel;

/// Player state store, provides a read-only snapshot of current playback state
@property (nonatomic, strong, readonly, nullable) PlayerStateStore *stateStore;

- (instancetype)initWithController:(AliPlayerController *)controller
                       playerModel:(AliPlayerModel *)playerModel;

@end
```

> **Note**: `StrategyContext` is no longer valid after `strategyDidStop` and should not be used further. `strategyDidReset:` passes a new context (containing the updated `playerModel`); the old context is no longer valid.

### **4.3 Inheriting BaseStrategy (Recommended)**

`BaseStrategy` encapsulates notification subscription management and common lifecycle logic; subclasses only need to focus on business logic:

```objc
@interface BaseStrategy : NSObject <StrategyProtocol, PlayerNotificationDelegate>

/// Strategy context (available after strategyDidStart:, nil after strategyDidStop)
@property (nonatomic, strong, readonly, nullable) StrategyContext *context;

/// Hook method for subclasses to reset internal state (called by base class during strategyDidReset:)
- (void)resetInternalState;

@end
```

**Lifecycle Flow**:

| Phase               | BaseStrategy Internal Behavior                               |
| ------------------- | ------------------------------------------------------------ |
| `strategyDidStart:` | Save context → Register as controller's `PlayerNotificationDelegate` |
| `strategyDidReset:` | Update context → Call subclass's `resetInternalState`        |
| `strategyDidStop`   | Unregister `PlayerNotificationDelegate` → Clear context      |

> **Note**: Subclasses must override the `strategyName` method; otherwise an exception will be raised. If overriding `strategyDidStart:` / `strategyDidStop` / `strategyDidReset:`, you must call `super`.

### **4.4 Complete Custom Strategy Example**

The following is a complete implementation of a play duration tracking strategy:

```objc
@interface PlayDurationStrategy : BaseStrategy

@property (nonatomic, copy, readonly, nullable) void (^onSessionEnd)(NSTimeInterval durationMs);

- (instancetype)initWithCallback:(void (^)(NSTimeInterval durationMs))callback;

@end

@implementation PlayDurationStrategy {
    CFAbsoluteTime _playStartTime;
    NSTimeInterval _totalPlayDuration;
    BOOL _isPlaying;
}

- (instancetype)initWithCallback:(void (^)(NSTimeInterval))callback {
    self = [super init];
    if (self) {
        _onSessionEnd = [callback copy];
    }
    return self;
}

- (NSString *)strategyName {
    return @"PlayDurationStrategy";
}

- (void)resetInternalState {
    _playStartTime = 0;
    _totalPlayDuration = 0;
    _isPlaying = NO;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    switch (state) {
        case PlayerStatePlaying:
            if (!_isPlaying) {
                _isPlaying = YES;
                _playStartTime = CFAbsoluteTimeGetCurrent();
            }
            break;

        case PlayerStatePaused:
            [self accumulateDuration];
            break;

        case PlayerStateCompleted:
        case PlayerStateStopped:
        case PlayerStateError:
            [self accumulateDuration];
            [self reportDuration];
            break;

        default:
            break;
    }
}

#pragma mark - Private

- (void)accumulateDuration {
    if (_isPlaying && _playStartTime > 0) {
        NSTimeInterval delta = (CFAbsoluteTimeGetCurrent() - _playStartTime) * 1000;
        _totalPlayDuration += delta;
        _isPlaying = NO;
        _playStartTime = 0;
    }
}

- (void)reportDuration {
    if (_onSessionEnd && _totalPlayDuration > 0) {
        _onSessionEnd(_totalPlayDuration);
    }
    _totalPlayDuration = 0;
}

@end
```

Register and use:

```objc
AliPlayerController *controller = [[AliPlayerController alloc] init];

[controller.strategyManager registerStrategy:
    [[PlayDurationStrategy alloc] initWithCallback:^(NSTimeInterval durationMs) {
        NSLog(@"Play duration: %.0fms", durationMs);
    }]];

[controller configure:model];
[self.playerView attach:controller];
```

### **4.5 Directly Implementing StrategyProtocol (Advanced)**

Directly conforming to the protocol provides greater flexibility, but requires manual event subscription management:

```objc
@interface MyCustomStrategy : NSObject <StrategyProtocol, PlayerNotificationDelegate>
@end

@implementation MyCustomStrategy {
    StrategyContext *_context;
}

- (NSString *)strategyName {
    return @"MyCustomStrategy";
}

- (void)strategyDidStart:(StrategyContext *)context {
    _context = context;
    [context.controller addNotificationDelegate:self];
}

- (void)strategyDidStop {
    [_context.controller removeNotificationDelegate:self];
    _context = nil;
}

- (void)strategyDidReset:(StrategyContext *)context {
    _context = context;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // Handle state changes
}

@end
```

> **Note**: When directly implementing the protocol, you must manually unsubscribe from all events in `strategyDidStop`; otherwise it will cause memory leaks. Inheriting `BaseStrategy` handles this automatically.

------

## **5. Strategy Lifecycle**

### **5.1 Lifecycle Phases**

| Lifecycle Method             | Trigger Timing                                           | Description                                                        |
| ---------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------ |
| `registerStrategy:`          | Manual registration or automatic registration via global factory | Strategy joins the manager, awaiting startup. If the manager is already started, the new strategy starts immediately |
| `strategyDidStart:`          | `StrategyManager.startWithController:playerModel:`       | Strategy starts, subscribes to notifications, initializes resources |
| `PlayerNotificationDelegate` | Controller dispatches notifications                      | Strategy processes received player events                          |
| `strategyDidReset:`          | `StrategyManager.resetWithPlayerModel:`                  | Resets internal state, updates context (when video source switches) |
| `strategyDidStop`            | `StrategyManager.stop` or strategy is unregistered       | Strategy stops, unsubscribes, cleans up resources                  |
| `destroy`                    | `StrategyManager.destroy`                                | Stops all strategies and clears the strategy list                  |

### **5.2 Lifecycle Flow**

```text
Create Controller
    ↓
[StrategyRegistry applyToManager:] → Register global strategies
    ↓
[playerView attach:controller]
    ↓
[strategyManager startWithController:playerModel:] → Create StrategyContext
    ↓                                                 → Iterate strategies calling strategyDidStart:
Strategies auto-register as PlayerNotificationDelegate (BaseStrategy)
    ↓
Player notifications dispatched via NotificationDispatcher → Strategies respond to callbacks
    ↓
Content switch → [controller configure:newModel]
    ↓           → [strategyManager resetWithPlayerModel:] → Update StrategyContext
    ↓                                                      → Iterate strategies calling strategyDidReset:
    ↓                                                      → BaseStrategy calls resetInternalState
    ↓
[playerView detach] or [controller destroy]
    ↓
[strategyManager stop] → Iterate strategies calling strategyDidStop
                        → BaseStrategy auto-unregisters NotificationDelegate
```

### **5.3 Strategy Manager (StrategyManager)**

`StrategyManager` is responsible for unified lifecycle management of all strategies. Each `AliPlayerController` owns one `StrategyManager` instance.

```objc
@interface StrategyManager : NSObject

/// Register a strategy (same-name strategies are replaced; if manager is already started, new strategy starts immediately)
- (void)registerStrategy:(id<StrategyProtocol>)strategy;

/// Unregister a strategy by name (if manager is started, the strategy is stopped before removal)
- (void)unregisterStrategyWithName:(NSString *)name;

/// Find a strategy by name
- (nullable id<StrategyProtocol>)strategyWithName:(NSString *)name;

/// Start all strategies (if already started, stops first then restarts)
- (void)startWithController:(AliPlayerController *)controller
                playerModel:(AliPlayerModel *)playerModel;

/// Reset all strategies (called when video source switches; no effect if not started)
- (void)resetWithPlayerModel:(AliPlayerModel *)playerModel;

/// Stop all strategies (strategy instances are retained, can be started again)
- (void)stop;

/// Destroy the manager (stops and clears the strategy list)
- (void)destroy;

/// Number of currently registered strategies
@property (nonatomic, assign, readonly) NSUInteger strategyCount;

/// Whether the manager has been started
@property (nonatomic, assign, readonly, getter=isStarted) BOOL started;

@end
```

> **Note**: All methods must be called on the main thread. The manager does not provide internal thread synchronization. Strategies execute lifecycle callbacks in registration order.

------

## **6. Best Practices**

### **6.1 Lifecycle Management**

```objc
@implementation MyStrategy

- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];  // Must call super
    // Initialize resources
}

- (void)strategyDidStop {
    // Clean up resources (timers, network listeners, etc.)
    [super strategyDidStop];  // Must call super
}

- (void)resetInternalState {
    // Reset internal state, prepare for new video
    _count = 0;
    _duration = 0;
}

@end
```

### **6.2 Event Response**

`BaseStrategy` automatically registers as a `PlayerNotificationDelegate`; subclasses directly implement callback methods:

```objc
#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // Handle state changes
}

- (void)playerDidRenderFirstFrame {
    // Handle first frame rendering
}

- (void)playerDidLoadingBegin {
    // Handle Loading start
}

- (void)playerDidLoadingEnd {
    // Handle Loading end
}
```

### **6.3 Accessing Player State**

Access player information through `context` (available after `strategyDidStart:`):

```objc
- (void)playerDidChangeState:(PlayerState)state {
    // Get playback data model
    AliPlayerModel *model = self.context.playerModel;
    NSString *title = model.videoTitle;

    // Get player state
    PlayerStateStore *stateStore = self.context.stateStore;
    long position = stateStore.currentPosition;
    long duration = stateStore.duration;

    // Send commands through controller
    [self.context.controller pause];
}
```

### **6.4 Important Notes**

| Scenario                      | Recommended Approach                            | Reason                                            |
| ----------------------------- | ----------------------------------------------- | ------------------------------------------------- |
| Overriding lifecycle methods  | Must call `super`                               | BaseStrategy manages notification subscriptions in super |
| Long-running tasks            | Cancel tasks in `strategyDidStop`               | Avoid memory leaks                                |
| Video switching               | Reset state in `resetInternalState`             | Ensure correct state, avoid accumulating stale data |
| Accessing Context             | Use after `strategyDidStart:`                   | Ensure context is available                       |
| Network listeners             | Remove listeners in `strategyDidStop`           | Prevent resource leaks                            |
| Thread safety                 | Execute all operations on main thread           | `StrategyManager` does not provide internal thread synchronization |

### **6.5 Common Mistakes**

```objc
// ✗ Wrong: Accessing context in constructor
- (instancetype)init {
    self = [super init];
    if (self) {
        // context is nil at this point!
        NSString *title = self.context.playerModel.videoTitle;  // nil
    }
    return self;
}

// ✓ Correct: Access after strategyDidStart:
- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    NSString *title = self.context.playerModel.videoTitle;  // works correctly
}
```

```objc
// ✗ Wrong: resetInternalState does not reset all internal state
- (void)resetInternalState {
    // Forgot to reset _stutterCount, causing cross-video data accumulation
}

// ✓ Correct: Reset all internal state
- (void)resetInternalState {
    _stutterCount = 0;
    _totalDuration = 0;
    _isPlaying = NO;
}
```

```objc
// ✗ Wrong: Overriding lifecycle method without calling super
- (void)strategyDidStart:(StrategyContext *)context {
    // Did not call [super strategyDidStart:context]
    // Results in context not saved, notifications not subscribed
}

// ✓ Correct: Always call super
- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    // Custom initialization
}
```

------

## **7. API Reference**

### **7.1 Core Classes**

| Class/Protocol     | Description                                                  |
| ------------------ | ------------------------------------------------------------ |
| `StrategyProtocol` | Strategy protocol, defines the lifecycle contract            |
| `BaseStrategy`     | Strategy base class, encapsulates notification subscription management and lifecycle flow |
| `StrategyManager`  | Strategy manager, manages strategy registration, lifecycle, and error isolation |
| `StrategyContext`  | Strategy context, provides read-only player environment information |
| `StrategyRegistry` | Global strategy registry, manages default strategy factories |

### **7.2 StrategyProtocol Methods**

| Method              | Required | Description                         |
| ------------------- | -------- | ----------------------------------- |
| `strategyName`      | Yes      | Returns strategy name (must be unique) |
| `strategyDidStart:` | Yes      | Start strategy, bind context        |
| `strategyDidStop`   | Yes      | Stop strategy, unbind context       |
| `strategyDidReset:` | Yes      | Reset strategy, update context      |

### **7.3 BaseStrategy Methods**

| Method/Property      | Description                                              |
| -------------------- | -------------------------------------------------------- |
| `context`            | Strategy context (available after `strategyDidStart:`)   |
| `resetInternalState` | Hook method for subclasses to reset internal state       |

### **7.4 StrategyManager Methods**

| Method                             | Description                                            |
| ---------------------------------- | ------------------------------------------------------ |
| `registerStrategy:`                | Register strategy (replaces same-name, starts immediately if already running) |
| `unregisterStrategyWithName:`      | Unregister strategy by name                            |
| `strategyWithName:`                | Query strategy by name                                 |
| `startWithController:playerModel:` | Start all strategies                                   |
| `resetWithPlayerModel:`            | Reset all strategies                                   |
| `stop`                             | Stop all strategies                                    |
| `destroy`                          | Destroy the manager                                    |
| `strategyCount`                    | Number of registered strategies                        |
| `started`                          | Whether the manager is started                         |

### **7.5 StrategyRegistry Methods**

| Method                      | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `+sharedRegistry`           | Get the global singleton                          |
| `addGlobalStrategyFactory:` | Register a global strategy factory                |
| `clearGlobalStrategies`     | Clear all global strategies (including built-in)  |
| `applyToManager:`           | Apply global strategies to a specified manager    |
| `resetToDefault`            | Restore default built-in strategy configuration   |

### **7.6 StrategyContext Properties**

| Property      | Type                            | Description                          |
| ------------- | ------------------------------- | ------------------------------------ |
| `controller`  | `AliPlayerController *` (weak)  | Player controller                    |
| `playerModel` | `AliPlayerModel *`              | Playback configuration model         |
| `stateStore`  | `PlayerStateStore *` (nullable) | Player state store (read-only)       |

### **7.7 Built-in Strategies**

| Strategy                    | Delegate Protocol                   | Key Properties/Methods                                               |
| --------------------------- | ----------------------------------- | -------------------------------------------------------------------- |
| `FirstFrameStrategy`        | `FirstFrameStrategyDelegate`        | `delegate`                                                           |
| `StutterDetectStrategy`     | `StutterDetectStrategyDelegate`     | `delegate`, `stutterCount`, `totalStutterDurationMs`, `stutterThresholdMs`, `initWithThreshold:` |
| `TrafficProtectionStrategy` | `TrafficProtectionStrategyDelegate` | `delegate`, `isOnCellularNetwork`                                    |

---

## **8. Example Reference**

> **Reference**: The `PlayerKitUsages/UsageStrategySystem` module provides complete strategy system usage examples, demonstrating automatic loading of built-in strategies (first frame timing, stutter detection, traffic protection), as well as registration, resume position querying, and clearing of a custom resume playback strategy (`ResumePlayStrategy`).
