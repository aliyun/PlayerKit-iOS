# **策略系统 (Strategy System)**

**策略系统 (Strategy System)** 是 AliPlayerKit 的核心架构设计。它通过事件驱动的策略机制，将播放器监控、分析和优化逻辑封装为独立的策略组件，实现播放器业务逻辑的解耦、复用与灵活扩展。

------

## **1. 概念介绍**

### **1.1 什么是策略？**

**策略 (Strategy)** 是播放器业务逻辑的独立封装单元，承载特定业务能力或自定义逻辑，如首帧耗时统计、卡顿检测、流量保护、记忆播放等。

**核心特征**：

- **单一职责**：每个策略围绕一个明确的功能目标
- **事件驱动**：通过 `PlayerNotificationDelegate` 协议订阅播放器事件，响应式执行
- **独立隔离**：策略之间相互独立、互不干扰，每个策略的执行通过 `@try/@catch` 隔离

### **1.2 什么是策略系统？**

**策略系统 (Strategy System)** 是用于统一管理策略组件的架构机制。

它负责定义策略的 **注册机制、生命周期管理、上下文注入以及事件订阅**，并在播放器运行过程中统一管理策略的创建、启动、重置与销毁。

基于这一机制，开发者可以按需启用或禁用特定策略，也可以快速实现自定义策略，甚至完全替换默认策略，以满足不同业务场景的定制需求。

### **1.3 核心价值**

| 使用方式     | 说明                       | 优势                   |
| ------------ | -------------------------- | ---------------------- |
| 使用默认策略 | 播放器组件使用官方默认策略 | 简化接入流程，开箱即用 |
| 自定义策略   | 实现特定业务需求的策略     | 满足各类定制化业务需求 |
| 不使用策略   | 仅使用播放能力             | 纯播放场景，无逻辑依赖 |

**架构优势**：

- **解耦**：策略与播放器核心逻辑分离，职责清晰
- **复用**：策略可在不同播放器实例间复用
- **可扩展**：无需修改框架即可自定义策略
- **隔离**：策略间相互独立，单个策略异常不影响其他策略

------

## **2. 功能特性**

### **2.1 核心能力**

| 能力         | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| 事件驱动     | 策略通过实现 `PlayerNotificationDelegate` 协议订阅播放器事件，响应式执行 |
| 生命周期管理 | 统一管理策略的启动、停止、重置、销毁                         |
| 上下文注入   | 策略可通过 `StrategyContext` 访问播放器控制器、播放模型和状态存储 |
| 工厂模式     | 通过 `StrategyRegistry` 注册全局策略工厂，自动应用于所有新创建的播放器实例 |
| 错误隔离     | 每个策略的生命周期调用通过 `@try/@catch` 隔离，单个策略异常不影响其他策略 |

### **2.2 内置策略**

| 策略     | 类名                        | 说明                              | 触发条件             |
| -------- | --------------------------- | --------------------------------- | -------------------- |
| 首帧耗时 | `FirstFrameStrategy`        | 测量从 PREPARING 到首帧渲染的耗时 | 播放器准备时自动启动 |
| 卡顿检测 | `StutterDetectStrategy`     | 检测播放过程中的卡顿次数和时长    | 首帧渲染后开始监测   |
| 流量保护 | `TrafficProtectionStrategy` | 蜂窝网络状态检测和变化通知        | 网络状态变化时触发   |

> **说明**：内置策略在 `StrategyRegistry` 首次访问时自动注册。每当新的 `AliPlayerController` 创建时，通过 `applyToManager:` 将所有已注册的工厂实例化并注入到控制器的 `StrategyManager` 中，确保每个控制器拥有独立的策略实例。

#### **2.2.1 首帧耗时策略 (FirstFrameStrategy)**

测量播放器首帧渲染耗时，分为三个阶段：

| 阶段     | 说明               | 事件区间                           |
| -------- | ------------------ | ---------------------------------- |
| 准备阶段 | 视频解析、网络请求 | `PREPARING` → `Prepared`           |
| 渲染阶段 | 解码、渲染首帧     | `Prepared` → `FirstFrameRendered`  |
| 总耗时   | 完整首帧耗时       | `PREPARING` → `FirstFrameRendered` |

通过 `FirstFrameStrategyDelegate` 获取耗时数据：

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

#### **2.2.2 卡顿检测策略 (StutterDetectStrategy)**

监控播放过程中的 Loading 状态，统计卡顿情况。首帧渲染前的 Loading 不计入卡顿统计。

| 指标       | 属性                     | 说明                               |
| ---------- | ------------------------ | ---------------------------------- |
| 卡顿次数   | `stutterCount`           | Loading 发生的次数（首帧后计算）   |
| 卡顿总时长 | `totalStutterDurationMs` | 整个播放会话的卡顿时长总和（毫秒） |
| 卡顿阈值   | `stutterThresholdMs`     | 超过该时长才视为卡顿（默认 0）     |

通过 `StutterDetectStrategyDelegate` 获取回调：

```objc
@protocol StutterDetectStrategyDelegate <NSObject>
@optional

/// 检测到一次卡顿
- (void)stutterDetectStrategy:(StutterDetectStrategy *)strategy
                   didStutter:(NSInteger)durationMs;

/// 播放会话结束分析
- (void)stutterDetectStrategy:(StutterDetectStrategy *)strategy
            didAnalyzeSession:(NSInteger)stayDurationMs
            validPlayDuration:(NSInteger)validPlayDurationMs
         totalStutterDuration:(NSInteger)totalStutterDurationMs
                 stutterCount:(NSInteger)stutterCount;
@end
```

```objc
// 创建卡顿检测策略（可选指定阈值）
StutterDetectStrategy *strategy = [[StutterDetectStrategy alloc] initWithThreshold:500];
strategy.delegate = self;
[controller.strategyManager registerStrategy:strategy];
```

#### **2.2.3 流量保护策略 (TrafficProtectionStrategy)**

监控网络状态变化，当检测到设备使用蜂窝网络播放视频时发出通知。此策略仅进行检测和日志记录，不会自动暂停播放。

| 场景             | 行为                             |
| ---------------- | -------------------------------- |
| WiFi → 蜂窝网络  | 通过 delegate 通知               |
| 起播时为蜂窝网络 | 通过 delegate 通知               |
| 蜂窝网络 → WiFi  | 通过 delegate 通知，重置提示标记 |

```objc
@protocol TrafficProtectionStrategyDelegate <NSObject>
@optional

/// 检测到蜂窝网络
- (void)trafficProtectionStrategyDidDetectCellularNetwork:(TrafficProtectionStrategy *)strategy;

/// 检测到切换回 Wi-Fi
- (void)trafficProtectionStrategyDidDetectWifiNetwork:(TrafficProtectionStrategy *)strategy;
@end
```

应用层可通过 `isOnCellularNetwork` 属性查询当前网络状态：

```objc
TrafficProtectionStrategy *strategy = (TrafficProtectionStrategy *)
    [controller.strategyManager strategyWithName:@"TrafficProtectionStrategy"];
if (strategy.isOnCellularNetwork) {
    // 展示流量提示
}
```

------

## **3. 使用方式**

### **3.1 使用默认策略（最简接入）**

创建 `AliPlayerController` 时自动注册默认策略（首帧、卡顿检测、流量保护）：

```objc
// 创建控制器（自动注册默认策略）
AliPlayerController *controller = [[AliPlayerController alloc] init];

// 配置播放数据
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"vid" playAuth:@"auth"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];

// 绑定到视图（策略自动启动）
[self.playerView attach:controller];
```

### **3.2 注册自定义策略**

在特定 Controller 上注册额外策略：

```objc
AliPlayerController *controller = [[AliPlayerController alloc] init];

// 注册带 delegate 回调的首帧策略
FirstFrameStrategy *firstFrame = [[FirstFrameStrategy alloc] init];
firstFrame.delegate = self;
[controller.strategyManager registerStrategy:firstFrame];

// 注册带阈值的卡顿检测策略
StutterDetectStrategy *stutter = [[StutterDetectStrategy alloc] initWithThreshold:200];
stutter.delegate = self;
[controller.strategyManager registerStrategy:stutter];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
[controller configure:model];
[self.playerView attach:controller];
```

### **3.3 全局注册策略工厂**

通过 `StrategyRegistry` 注册的策略工厂将自动应用于所有新创建的 Controller：

```objc
// 在 AppDelegate 中注册全局策略
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [AliPlayerKit setup];

    // 注册全局自定义策略工厂
    [[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
        return [[MyAnalyticsStrategy alloc] init];
    }];

    return YES;
}

// 之后创建的所有 AliPlayerController 都会自动注册此策略
```

> **说明**：`StrategyFactory` 每次调用创建一个新的策略实例，确保每个控制器拥有独立的策略对象，避免共享状态。

### **3.4 按需选择策略**

```objc
// 清除默认策略（包括内置策略），后续新建的 Controller 不会自动注册任何策略
[[StrategyRegistry sharedRegistry] clearGlobalStrategies];

// 只需要首帧统计
[[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
    return [[FirstFrameStrategy alloc] init];
}];

// 恢复默认内置策略配置
[[StrategyRegistry sharedRegistry] resetToDefault];
```

### **3.5 全局注册 vs 局部注册**

| 注册方式     | 说明                                         | 使用场景                     |
| ------------ | -------------------------------------------- | ---------------------------- |
| **全局注册** | 通过 `StrategyRegistry` 注册工厂             | 首帧统计、卡顿检测等通用策略 |
| **局部注册** | 直接调用 `strategyManager.registerStrategy:` | 特定场景下的业务策略         |

```objc
// 全局注册：所有新建 Controller 自动加载
[[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
    return [[MyAnalyticsStrategy alloc] init];
}];

// 局部注册：仅当前 Controller 加载
AliPlayerController *controller = [[AliPlayerController alloc] init];
[controller.strategyManager registerStrategy:[[MySpecialStrategy alloc] init]];
```

> **说明**：全局注册仅影响注册后新创建的 Controller，已创建的 Controller 不受影响。同名策略注册时会替换已有实例。

------

## **4. 自定义开发**

### **4.1 策略协议 (StrategyProtocol)**

所有策略必须遵循 `StrategyProtocol`，该协议定义了策略的生命周期契约：

```objc
@protocol StrategyProtocol <NSObject>

@required

/// 策略的唯一标识名称（同名策略注册时会替换已有实例）
- (NSString *)strategyName;

/// 策略启动，绑定播放器上下文
- (void)strategyDidStart:(StrategyContext *)context;

/// 策略停止，解绑播放器上下文
- (void)strategyDidStop;

/// 策略重置，更新上下文并清除内部状态（视频源切换时调用）
- (void)strategyDidReset:(StrategyContext *)context;

@end
```

> **说明**：`strategyDidReset:` 是 `@required` 方法。当同一控制器切换视频源时（重新 `configure:`），由 `StrategyManager` 调用。策略应重置内部计数器和临时状态，但保持事件订阅不变。

### **4.2 策略上下文 (StrategyContext)**

`StrategyContext` 在策略启动时由 `StrategyManager` 创建并传入，为策略提供只读的播放器环境信息：

```objc
@interface StrategyContext : NSObject

/// 关联的播放器控制器（弱引用）
@property (nonatomic, weak, readonly) AliPlayerController *controller;

/// 当前播放配置模型
@property (nonatomic, strong, readonly) AliPlayerModel *playerModel;

/// 播放器状态存储，提供当前播放状态的只读快照
@property (nonatomic, strong, readonly, nullable) PlayerStateStore *stateStore;

- (instancetype)initWithController:(AliPlayerController *)controller
                       playerModel:(AliPlayerModel *)playerModel;

@end
```

> **说明**：`StrategyContext` 在 `strategyDidStop` 后不再有效，不应继续使用。`strategyDidReset:` 会传入新的上下文（包含更新后的 `playerModel`），旧 context 不再有效。

### **4.3 继承 BaseStrategy（推荐）**

`BaseStrategy` 封装了通知订阅管理和通用生命周期逻辑，子类只需关注业务逻辑：

```objc
@interface BaseStrategy : NSObject <StrategyProtocol, PlayerNotificationDelegate>

/// 策略上下文（strategyDidStart: 后可用，strategyDidStop 后为 nil）
@property (nonatomic, strong, readonly, nullable) StrategyContext *context;

/// 子类重置内部状态的钩子方法（在 strategyDidReset: 时由基类调用）
- (void)resetInternalState;

@end
```

**生命周期流转**：

| 阶段                | BaseStrategy 内部行为                                    |
| ------------------- | -------------------------------------------------------- |
| `strategyDidStart:` | 保存上下文 → 注册为控制器的 `PlayerNotificationDelegate` |
| `strategyDidReset:` | 更新上下文 → 调用子类的 `resetInternalState`             |
| `strategyDidStop`   | 注销 `PlayerNotificationDelegate` → 清空上下文           |

> **说明**：子类必须覆写 `strategyName` 方法，否则会触发异常。如果覆写 `strategyDidStart:` / `strategyDidStop` / `strategyDidReset:`，必须调用 `super`。

### **4.4 自定义策略完整示例**

以下是一个播放时长统计策略的完整实现：

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

注册并使用：

```objc
AliPlayerController *controller = [[AliPlayerController alloc] init];

[controller.strategyManager registerStrategy:
    [[PlayDurationStrategy alloc] initWithCallback:^(NSTimeInterval durationMs) {
        NSLog(@"播放时长: %.0fms", durationMs);
    }]];

[controller configure:model];
[self.playerView attach:controller];
```

### **4.5 直接实现 StrategyProtocol（高级）**

直接遵循协议可获得更高灵活性，但需自行管理事件订阅：

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
    // 处理状态变化
}

@end
```

> **说明**：直接实现协议时，必须在 `strategyDidStop` 中手动取消所有事件订阅，否则会导致内存泄漏。继承 `BaseStrategy` 可自动处理这一问题。

------

## **5. 策略生命周期**

### **5.1 生命周期阶段**

| 生命周期方法                 | 触发时机                                           | 说明                                                       |
| ---------------------------- | -------------------------------------------------- | ---------------------------------------------------------- |
| `registerStrategy:`          | 手动注册或全局工厂自动注册                         | 策略加入管理器，等待启动。如果管理器已启动，新策略立即启动 |
| `strategyDidStart:`          | `StrategyManager.startWithController:playerModel:` | 策略启动，订阅通知，初始化资源                             |
| `PlayerNotificationDelegate` | 控制器分发通知                                     | 策略处理接收到的播放器事件                                 |
| `strategyDidReset:`          | `StrategyManager.resetWithPlayerModel:`            | 重置内部状态，更新上下文（视频源切换时）                   |
| `strategyDidStop`            | `StrategyManager.stop` 或策略被注销                | 策略停止，取消订阅，清理资源                               |
| `destroy`                    | `StrategyManager.destroy`                          | 停止所有策略并清空策略列表                                 |

### **5.2 生命周期流程**

```text
创建 Controller
    ↓
[StrategyRegistry applyToManager:] → 注册全局策略
    ↓
[playerView attach:controller]
    ↓
[strategyManager startWithController:playerModel:] → 创建 StrategyContext
    ↓                                                 → 遍历策略调用 strategyDidStart:
策略自动注册为 PlayerNotificationDelegate（BaseStrategy）
    ↓
播放器通知通过 NotificationDispatcher 分发 → 策略响应回调方法
    ↓
播放内容切换 → [controller configure:newModel]
    ↓           → [strategyManager resetWithPlayerModel:] → 更新 StrategyContext
    ↓                                                      → 遍历策略调用 strategyDidReset:
    ↓                                                      → BaseStrategy 调用 resetInternalState
    ↓
[playerView detach] 或 [controller destroy]
    ↓
[strategyManager stop] → 遍历策略调用 strategyDidStop
                        → BaseStrategy 自动注销 NotificationDelegate
```

### **5.3 策略管理器 (StrategyManager)**

`StrategyManager` 负责统一管理所有策略的生命周期。每个 `AliPlayerController` 拥有一个 `StrategyManager` 实例。

```objc
@interface StrategyManager : NSObject

/// 注册策略（同名策略会被替换；管理器已启动时新策略立即启动）
- (void)registerStrategy:(id<StrategyProtocol>)strategy;

/// 按名称注销策略（管理器已启动时策略先停止再移除）
- (void)unregisterStrategyWithName:(NSString *)name;

/// 按名称查找策略
- (nullable id<StrategyProtocol>)strategyWithName:(NSString *)name;

/// 启动所有策略（已启动时先停止再重新启动）
- (void)startWithController:(AliPlayerController *)controller
                playerModel:(AliPlayerModel *)playerModel;

/// 重置所有策略（视频源切换时调用，未启动时无效果）
- (void)resetWithPlayerModel:(AliPlayerModel *)playerModel;

/// 停止所有策略（策略实例保留，可再次 start）
- (void)stop;

/// 销毁管理器（停止并清空策略列表）
- (void)destroy;

/// 当前已注册的策略数量
@property (nonatomic, assign, readonly) NSUInteger strategyCount;

/// 管理器是否已启动
@property (nonatomic, assign, readonly, getter=isStarted) BOOL started;

@end
```

> **说明**：所有方法必须在主线程调用。管理器不提供内部线程同步。策略按注册顺序执行生命周期回调。

------

## **6. 最佳实践**

### **6.1 生命周期管理**

```objc
@implementation MyStrategy

- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];  // 必须调用 super
    // 初始化资源
}

- (void)strategyDidStop {
    // 清理资源（定时器、网络监听等）
    [super strategyDidStop];  // 必须调用 super
}

- (void)resetInternalState {
    // 重置内部状态，准备处理新视频
    _count = 0;
    _duration = 0;
}

@end
```

### **6.2 事件响应**

`BaseStrategy` 自动注册为 `PlayerNotificationDelegate`，子类直接实现回调方法：

```objc
#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // 处理状态变化
}

- (void)playerDidRenderFirstFrame {
    // 处理首帧渲染
}

- (void)playerDidLoadingBegin {
    // 处理 Loading 开始
}

- (void)playerDidLoadingEnd {
    // 处理 Loading 结束
}
```

### **6.3 访问播放器状态**

通过 `context` 访问播放器信息（`strategyDidStart:` 后可用）：

```objc
- (void)playerDidChangeState:(PlayerState)state {
    // 获取播放数据模型
    AliPlayerModel *model = self.context.playerModel;
    NSString *title = model.videoTitle;

    // 获取播放器状态
    PlayerStateStore *stateStore = self.context.stateStore;
    long position = stateStore.currentPosition;
    long duration = stateStore.duration;

    // 通过控制器发送命令
    [self.context.controller pause];
}
```

### **6.4 注意事项**

| 场景             | 推荐做法                           | 原因                                 |
| ---------------- | ---------------------------------- | ------------------------------------ |
| 覆写生命周期方法 | 必须调用 `super`                   | BaseStrategy 在 super 中管理通知订阅 |
| 长时间运行任务   | 在 `strategyDidStop` 中取消任务    | 避免内存泄漏                         |
| 视频切换         | 在 `resetInternalState` 中重置状态 | 确保状态正确，不在旧数据上累积       |
| 访问 Context     | 在 `strategyDidStart:` 之后使用    | 确保上下文可用                       |
| 网络监听         | 在 `strategyDidStop` 中移除监听器  | 防止资源泄漏                         |
| 线程安全         | 所有操作在主线程执行               | `StrategyManager` 不提供内部线程同步 |

### **6.5 常见错误**

```objc
// ✗ 错误：在构造函数中访问 context
- (instancetype)init {
    self = [super init];
    if (self) {
        // context 此时为 nil！
        NSString *title = self.context.playerModel.videoTitle;  // nil
    }
    return self;
}

// ✓ 正确：在 strategyDidStart: 之后访问
- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    NSString *title = self.context.playerModel.videoTitle;  // 正常获取
}
```

```objc
// ✗ 错误：resetInternalState 未重置所有内部状态
- (void)resetInternalState {
    // 忘记重置 _stutterCount，导致跨视频数据累积
}

// ✓ 正确：重置所有内部状态
- (void)resetInternalState {
    _stutterCount = 0;
    _totalDuration = 0;
    _isPlaying = NO;
}
```

```objc
// ✗ 错误：覆写生命周期方法未调用 super
- (void)strategyDidStart:(StrategyContext *)context {
    // 未调用 [super strategyDidStart:context]
    // 导致 context 未保存、通知未订阅
}

// ✓ 正确：始终调用 super
- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    // 自定义初始化
}
```

------

## **7. API 速查**

### **7.1 核心类**

| 类/协议            | 说明                                         |
| ------------------ | -------------------------------------------- |
| `StrategyProtocol` | 策略协议，定义生命周期契约                   |
| `BaseStrategy`     | 策略基类，封装通知订阅管理和生命周期流转     |
| `StrategyManager`  | 策略管理器，管理策略注册、生命周期和错误隔离 |
| `StrategyContext`  | 策略上下文，提供只读的播放器环境信息         |
| `StrategyRegistry` | 全局策略注册表，管理默认策略工厂             |

### **7.2 StrategyProtocol 方法**

| 方法                | 必选 | 说明                     |
| ------------------- | ---- | ------------------------ |
| `strategyName`      | 是   | 返回策略名称（必须唯一） |
| `strategyDidStart:` | 是   | 启动策略，绑定上下文     |
| `strategyDidStop`   | 是   | 停止策略，解绑上下文     |
| `strategyDidReset:` | 是   | 重置策略，更新上下文     |

### **7.3 BaseStrategy 方法**

| 方法/属性            | 说明                                     |
| -------------------- | ---------------------------------------- |
| `context`            | 策略上下文（`strategyDidStart:` 后可用） |
| `resetInternalState` | 子类重置内部状态的钩子方法               |

### **7.4 StrategyManager 方法**

| 方法                               | 说明                                   |
| ---------------------------------- | -------------------------------------- |
| `registerStrategy:`                | 注册策略（同名替换，已启动时立即启动） |
| `unregisterStrategyWithName:`      | 按名称注销策略                         |
| `strategyWithName:`                | 按名称查询策略                         |
| `startWithController:playerModel:` | 启动所有策略                           |
| `resetWithPlayerModel:`            | 重置所有策略                           |
| `stop`                             | 停止所有策略                           |
| `destroy`                          | 销毁管理器                             |
| `strategyCount`                    | 已注册策略数量                         |
| `started`                          | 管理器是否已启动                       |

### **7.5 StrategyRegistry 方法**

| 方法                        | 说明                             |
| --------------------------- | -------------------------------- |
| `+sharedRegistry`           | 获取全局单例                     |
| `addGlobalStrategyFactory:` | 注册全局策略工厂                 |
| `clearGlobalStrategies`     | 清除所有全局策略（包括内置策略） |
| `applyToManager:`           | 将全局策略应用到指定管理器       |
| `resetToDefault`            | 恢复默认内置策略配置             |

### **7.6 StrategyContext 属性**

| 属性          | 类型                            | 说明                   |
| ------------- | ------------------------------- | ---------------------- |
| `controller`  | `AliPlayerController *` (weak)  | 播放器控制器           |
| `playerModel` | `AliPlayerModel *`              | 播放配置模型           |
| `stateStore`  | `PlayerStateStore *` (nullable) | 播放器状态存储（只读） |

### **7.7 内置策略**

| 策略                        | Delegate 协议                       | 关键属性/方法                                                |
| --------------------------- | ----------------------------------- | ------------------------------------------------------------ |
| `FirstFrameStrategy`        | `FirstFrameStrategyDelegate`        | `delegate`                                                   |
| `StutterDetectStrategy`     | `StutterDetectStrategyDelegate`     | `delegate`、`stutterCount`、`totalStutterDurationMs`、`stutterThresholdMs`、`initWithThreshold:` |
| `TrafficProtectionStrategy` | `TrafficProtectionStrategyDelegate` | `delegate`、`isOnCellularNetwork`                            |

---

## **8. 示例参考**

> **参考**：`PlayerKitUsages/UsageStrategySystem` 模块提供了完整的策略系统使用示例，演示了内置策略（首帧时机、卡顿检测、流量保护）的自动装载，以及自定义断点续播策略（`ResumePlayStrategy`）的注册、续播位置查询与清除。
