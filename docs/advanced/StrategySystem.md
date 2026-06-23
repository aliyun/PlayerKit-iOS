# **策略系统 (Strategy System)**

**策略系统 (Strategy System)** 是 AliPlayerKit 的核心架构设计。它通过事件驱动的策略机制，将播放器监控、分析和优化逻辑封装为独立的策略组件，实现播放器业务逻辑的解耦、复用与灵活扩展。

---

## **1. 概念介绍**

### **1.1 什么是策略？**

**策略 (Strategy)** 是播放器业务逻辑的独立封装单元，承载特定业务能力或自定义逻辑，如首帧耗时统计、卡顿检测、流量保护、记忆播放等。

**核心特征**：

- **单一职责**：每个策略围绕一个明确的功能目标
- **事件驱动**：通过事件系统订阅播放器事件，响应式执行
- **独立隔离**：策略之间相互独立、互不干扰

### **1.2 什么是策略系统？**

**策略系统 (Strategy System)** 是用于统一管理策略组件的架构机制。

它负责定义策略的 **注册机制、生命周期管理、上下文注入以及事件订阅**，并在播放器运行过程中统一管理策略的创建、启动、重置与销毁。

基于这一机制，开发者可以按需启用或禁用特定策略，也可以快速实现自定义策略，甚至完全替换默认策略，以满足不同业务场景的定制需求。

### **1.3 核心价值**

| 使用方式 | 说明 | 优势 |
|---------|------|------|
| 使用默认策略 | 播放器组件使用官方默认策略 | 简化接入流程，开箱即用 |
| 自定义策略 | 实现特定业务需求的策略 | 满足各类定制化业务需求 |
| 不使用策略 | 仅使用播放能力 | 纯播放场景，无逻辑依赖 |

**架构优势**：

- **解耦**：策略与播放器核心逻辑分离，职责清晰
- **复用**：策略可在不同播放器实例间复用
- **可扩展**：无需修改框架即可自定义策略
- **隔离**：策略间相互独立，互不影响

---

## **2. 功能特性**

### **2.1 核心能力**

| 能力 | 说明 |
|-----|------|
| 事件驱动 | 策略通过实现 PlayerNotificationDelegate 协议订阅播放器事件，响应式执行 |
| 生命周期管理 | 统一管理策略的启动、停止、重置、销毁 |
| 上下文注入 | 策略可通过上下文访问播放器状态和数据 |
| 工厂模式 | 支持全局注册策略工厂，自动应用于所有播放器实例 |

### **2.2 内置策略**

| 策略 | 类名 | 说明 | 触发条件 |
|------|------|------|---------|
| 首帧耗时 | `FirstFrameStrategy` | 统计从 PREPARING 到首帧渲染的耗时 | 播放器准备时自动启动 |
| 卡顿检测 | `StutterDetectStrategy` | 检测播放过程中的卡顿次数和时长 | 首帧渲染后开始监测 |
| 流量保护 | `TrafficProtectionStrategy` | WiFi 切换到蜂窝网络时提醒用户 | 网络状态变化时触发 |

#### 首帧耗时策略详情

统计播放器首帧渲染耗时，细分三个阶段：

| 阶段 | 说明 | 事件区间 |
|-----|------|---------|
| 准备阶段 | 视频解析、网络请求 | `PREPARING` → `Prepared` |
| 渲染阶段 | 解码、渲染首帧 | `Prepared` → `FirstFrameRendered` |
| 总耗时 | 完整首帧耗时 | `PREPARING` → `FirstFrameRendered` |

#### 卡顿检测策略详情

监控播放过程中的 Loading 状态，统计卡顿情况：

| 指标 | 说明 |
|-----|------|
| 卡顿次数 | Loading 发生的次数（首帧后计算） |
| 单次卡顿时长 | 每次 LoadingBegin → LoadingEnd 的时长 |
| 卡顿总时长 | 整个播放会话的卡顿时长总和 |
| 有效播放时长 | 实际观看时间（不含暂停和卡顿） |

#### 流量保护策略详情

| 场景 | 行为 |
|-----|------|
| WiFi → 蜂窝网络 | 提示用户正在使用流量播放 |
| 起播时为蜂窝网络 | 提示用户当前使用流量 |
| 蜂窝网络 → WiFi | 重置提示标记 |

---

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

// 注册自定义策略
[controller.strategyManager registerStrategy:
    [[TrafficProtectionStrategy alloc] initWithCallback:^(NSTimeInterval durationMs) {
        NSLog(@"播放时长: %.0fms", durationMs);
    }]];

// 注册带回调的内置策略
[controller.strategyManager registerStrategy:
    [[FirstFrameStrategy alloc] initWithCallback:
        ^(NSTimeInterval prepareTime, NSTimeInterval renderTime, NSTimeInterval totalTime) {
            NSLog(@"首帧耗时: %.0fms", totalTime);
        }]];

AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
[controller configure:model];
[self.playerView attach:controller];
```

### **3.3 全局注册策略工厂**

通过 `StrategyRegistry` 注册的策略将自动应用于所有新创建的 Controller：

```objc
// 在 AppDelegate 中注册全局策略
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 初始化 AliPlayerKit
    [AliPlayerKit setup];

    // 注册全局自定义策略
    [[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
        return [[MyAnalyticsStrategy alloc] initWithConfig:analyticsConfig];
    }];

    return YES;
}

// 之后创建的所有 AliPlayerController 都会自动注册此策略
```

### **3.4 按需选择策略**

```objc
// 清除默认策略，只注册需要的
[[StrategyRegistry sharedRegistry] clearGlobalStrategies];

// 只需要首帧统计
[[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
    return [[FirstFrameStrategy alloc] init];
}];

// 或完全不使用策略
// 清除全局策略后，新建的 Controller 不会自动注册任何策略
```

### **3.5 全局注册 vs 局部注册**

| 注册方式 | 说明 | 使用场景 |
|---------|------|---------|
| **全局注册** | 通过 `StrategyRegistry` 注册 | 首帧统计、卡顿检测等通用策略 |
| **局部注册** | 直接调用 `strategyManager.registerStrategy:` | 特定场景下的业务策略 |

```objc
// 全局注册：所有 Controller 自动加载
[[StrategyRegistry sharedRegistry] addGlobalStrategyFactory:^id<StrategyProtocol>{
    return [[MyAnalyticsStrategy alloc] init];
}];

// 局部注册：仅当前 Controller 加载
AliPlayerController *controller = [[AliPlayerController alloc] init];
[controller.strategyManager registerStrategy:[[MySpecialStrategy alloc] init]];
```

---

## **4. 自定义开发**

### **4.1 策略协议 (StrategyProtocol)**

所有策略必须遵循 `StrategyProtocol`：

```objc
@protocol StrategyProtocol <NSObject>

@required

/// 策略名称（用于日志和调试，必须唯一）
- (NSString *)strategyName;

/// 策略启动（订阅通知、初始化资源）
- (void)strategyDidStart:(StrategyContext *)context;

/// 策略停止（取消订阅、清理资源）
- (void)strategyDidStop;

@optional

/// 策略重置（播放内容切换时调用）
- (void)strategyDidReset:(StrategyContext *)context;

@end
```

### **4.2 策略上下文 (StrategyContext)**

策略上下文提供只读的播放器信息：

```objc
@interface StrategyContext : NSObject

/// 播放器唯一标识
@property (nonatomic, copy, readonly) NSString *playerId;

/// 播放数据模型
@property (nonatomic, strong, readonly, nullable) AliPlayerModel *model;

/// 播放器状态存储（只读）
@property (nonatomic, strong, readonly) id<AliPlayerStateStoreProtocol> stateStore;

@end
```

### **4.3 继承 BaseStrategy（推荐）**

`BaseStrategy` 封装了通知订阅管理和通用工具方法，子类只需关注业务逻辑：

```objc
@interface BaseStrategy : NSObject <StrategyProtocol, PlayerNotificationDelegate>

/// 策略上下文（strategyDidStart: 后可用）
@property (nonatomic, strong, readonly, nullable) StrategyContext *context;

/// 子类重置内部状态的钩子方法
- (void)resetInternalState;

/// 子类直接实现 PlayerNotificationDelegate 的回调方法即可接收播放器事件，
/// 例如：
/// - (void)playerDidChangeState:(PlayerState)state;
/// - (void)playerDidRenderFirstFrame;
/// - (void)playerDidLoadingBegin;
/// - (void)playerDidLoadingEnd;

@end
```

### **4.4 自定义策略完整示例**

以下是一个播放时长统计策略的完整实现：

```objc
/// 播放时长统计策略
@interface TrafficProtectionStrategy : BaseStrategy

typedef void(^TrafficProtectionCallback)(NSTimeInterval durationMs);

- (instancetype)initWithCallback:(nullable TrafficProtectionCallback)callback;

@end

@implementation TrafficProtectionStrategy {
    TrafficProtectionCallback _callback;
    CFAbsoluteTime _playStartTime;
    NSTimeInterval _totalPlayDuration;
    BOOL _isPlaying;
}

- (instancetype)initWithCallback:(TrafficProtectionCallback)callback {
    self = [super init];
    if (self) {
        _callback = callback;
    }
    return self;
}

- (NSString *)strategyName {
    return @"PlayDurationStrategy";
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    [self handleStateChanged:state];
}

- (void)strategyDidReset:(StrategyContext *)context {
    [super strategyDidReset:context];
}

#pragma mark - Private

- (void)handleStateChanged:(AliPlayerState)newState {
    switch (newState) {
        case AliPlayerStatePlaying:
            if (!_isPlaying) {
                _isPlaying = YES;
                _playStartTime = CFAbsoluteTimeGetCurrent();
            }
            break;

        case AliPlayerStatePaused:
            [self stopTimer];
            break;

        case AliPlayerStateCompleted:
        case AliPlayerStateStopped:
        case AliPlayerStateError:
            [self stopTimer];
            [self reportDuration];
            break;

        default:
            break;
    }
}

- (void)stopTimer {
    if (_isPlaying && _playStartTime > 0) {
        NSTimeInterval delta = (CFAbsoluteTimeGetCurrent() - _playStartTime) * 1000;
        _totalPlayDuration += delta;
        _isPlaying = NO;
        _playStartTime = 0;
    }
}

- (void)reportDuration {
    NSLog(@"[PlayDurationStrategy] 播放时长: %.0fms", _totalPlayDuration);
    if (_callback && _totalPlayDuration > 0) {
        _callback(_totalPlayDuration);
    }
    _totalPlayDuration = 0;
}

@end
```

### **4.5 带 Delegate 回调的策略**

对于需要多方法回调的策略，推荐使用 Delegate 模式：

```objc
/// 卡顿检测回调协议
@protocol StutterDetectStrategyDelegate <NSObject>
@optional
/// 发生卡顿
- (void)onStutter:(NSTimeInterval)durationMs;

/// 播放会话结束统计
- (void)onSessionAnalysisWithStayDuration:(NSTimeInterval)stayDurationMs
                        validPlayDuration:(NSTimeInterval)validPlayDurationMs
                      totalStutterDuration:(NSTimeInterval)totalStutterDurationMs
                             stutterCount:(NSInteger)stutterCount;
@end

/// 使用带 Delegate 的策略
StutterDetectStrategy *strategy =
    [[StutterDetectStrategy alloc] initWithDelegate:self];
[controller.strategyManager registerStrategy:strategy];
```

### **4.6 实现 StrategyProtocol（高级）**

直接遵循协议可获得更高灵活性，但需自行管理事件订阅：

```objc
@interface MyCustomStrategy : NSObject <StrategyProtocol>
@end

@implementation MyCustomStrategy {
    StrategyContext *_context;
}

- (NSString *)strategyName {
    return @"MyCustomStrategy";
}

- (void)strategyDidStart:(StrategyContext *)context {
    _context = context;
    // 通过 PlayerNotificationDelegate 订阅播放器事件
    [context.controller addNotificationDelegate:self];
}

- (void)strategyDidStop {
    // 取消订阅
    [_context.controller removeNotificationDelegate:self];
    _context = nil;
}

- (void)strategyDidReset:(StrategyContext *)context {
    _context = context;
    // 重置内部状态
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    [self handleEvent:state];
}

@end
```

---

## **5. 策略生命周期**

### **5.1 生命周期阶段**

| 生命周期方法 | 触发时机 | 说明 |
|------------|---------|------|
| `registerStrategy:` | 手动注册或全局工厂自动注册 | 策略加入管理器，等待启动 |
| `strategyDidStart:` | `playerView attach:` | 策略启动，订阅通知，初始化资源 |
| `PlayerNotificationDelegate` | 控制器分发通知 | 策略处理接收到的播放器事件 |
| `strategyDidReset:` | 播放内容切换 | 重置内部状态，准备处理新视频 |
| `strategyDidStop` | `playerView detach` 或 Controller 销毁 | 策略停止，取消订阅，清理资源 |
| `destroy` | 管理器销毁 | 停止所有策略并清空策略列表 |

### **5.2 生命周期流程**

```text
创建 Controller
    ↓
[StrategyRegistry applyToManager:] → 注册全局策略
    ↓
[playerView attach:controller]
    ↓
[strategyManager startWithController:playerModel:] → 遍历策略调用 strategyDidStart:
    ↓
策略自动注册为 PlayerNotificationDelegate
    ↓
播放器通知通过 NotificationDispatcher 分发 → 策略响应回调方法
    ↓
播放内容切换 → resetWithPlayerModel: → 遍历策略调用 strategyDidReset:
    ↓
[playerView detach] 或 Controller 销毁
    ↓
[strategyManager stop] → 遍历策略调用 strategyDidStop → 策略取消所有订阅
```

### **5.3 策略管理器**

`StrategyManager` 负责统一管理所有策略的生命周期：

```objc
@interface StrategyManager : NSObject

/// 注册策略
- (void)registerStrategy:(id<StrategyProtocol>)strategy;

/// 注销指定名称的策略
- (void)unregisterStrategyWithName:(NSString *)name;

/// 启动所有策略
- (void)startWithController:(AliPlayerController *)controller
                playerModel:(AliPlayerModel *)playerModel;

/// 停止所有策略
- (void)stop;

/// 重置所有策略（播放内容切换时）
- (void)resetWithPlayerModel:(AliPlayerModel *)playerModel;

/// 销毁管理器
- (void)destroy;

/// 查询策略
- (nullable id<StrategyProtocol>)strategyWithName:(NSString *)name;

/// 已注册策略数量
@property (nonatomic, readonly) NSUInteger strategyCount;

/// 是否已启动
@property (nonatomic, readonly, getter=isStarted) BOOL started;

@end
```

---

## **6. 最佳实践**

### **6.1 生命周期管理**

```objc
@implementation MyStrategy

- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];  // 必须调用
    // 初始化资源
}

- (void)strategyDidStop {
    // 清理资源（定时器、网络监听等）
    [super strategyDidStop];  // 必须调用
}

- (void)resetInternalState {
    // 重置内部状态，准备处理新视频
}

@end
```

### **6.2 事件响应**

BaseStrategy 自动注册为 PlayerNotificationDelegate，子类直接实现回调方法：

```objc
#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // 处理状态变化
}

- (void)playerDidRenderFirstFrame {
    // 处理首帧渲染
}
```

### **6.3 访问播放器状态**

通过 `context` 访问播放器信息（`strategyDidStart:` 后可用）：

```objc
- (void)playerDidChangeState:(PlayerState)state {
    // 获取播放器 ID
    NSString *playerId = self.context.playerId;

    // 获取播放数据模型
    AliPlayerModel *model = self.context.model;
    NSString *title = model.videoTitle;

    // 获取播放器状态
    PlayerStateStore *stateStore = self.context.stateStore;
    long position = stateStore.currentPosition;
    long duration = stateStore.duration;
}
```

### **6.4 注意事项**

| 场景 | 推荐做法 | 原因 |
|-----|---------|------|
| 长时间运行任务 | 在 `strategyDidStop` 中取消任务 | 避免内存泄漏 |
| 视频切换 | 在 `resetInternalState` 中重置状态 | 确保状态正确 |
| 访问 Context | 在 `strategyDidStart:` 之后使用 | 确保上下文可用 |
| 网络监听 | 在 `strategyDidStop` 中移除监听器 | 防止资源泄漏 |

### **6.5 常见错误**

```objc
// ✗ 错误：在构造函数中访问 context
- (instancetype)init {
    self = [super init];
    if (self) {
        // context 此时为 nil！
        NSString *playerId = self.context.playerId;  // nil
    }
    return self;
}

// ✓ 正确：在 strategyDidStart: 之后访问
- (void)strategyDidStart:(StrategyContext *)context {
    [super strategyDidStart:context];
    NSString *playerId = self.context.playerId;  // 正常获取
}
```

```objc
// ✗ 错误：resetInternalState 未重置内部状态
- (void)resetInternalState {
    // 忘记重置 _stutterCount，导致数据累积
}

// ✓ 正确：重置所有内部状态
- (void)resetInternalState {
    _stutterCount = 0;
    _totalDuration = 0;
    _isPlaying = NO;
}
```

---

## **7. API 速查**

### **7.1 核心类**

| 类/协议 | 说明 | 详见 |
|--------|------|------|
| `StrategyProtocol` | 策略协议，定义生命周期方法 | [ApiReference.md](../ApiReference.md) |
| `BaseStrategy` | 策略基类，封装通知订阅管理 | [ApiReference.md](../ApiReference.md) |
| `StrategyManager` | 策略管理器，管理策略生命周期 | [ApiReference.md](../ApiReference.md) |
| `StrategyContext` | 策略上下文，提供只读播放器信息 | [ApiReference.md](../ApiReference.md) |
| `StrategyRegistry` | 策略注册中心，管理全局策略 | [ApiReference.md](../ApiReference.md) |

### **7.2 StrategyProtocol 方法**

| 方法 | 说明 |
|-----|------|
| `strategyName` | 返回策略名称（必须唯一） |
| `strategyDidStart:` | 启动策略，订阅通知 |
| `strategyDidStop` | 停止策略，取消订阅 |
| `strategyDidReset:`（可选） | 重置内部状态 |

### **7.3 BaseStrategy 方法**

| 方法 | 说明 |
|-----|------|
| `context` | 策略上下文（strategyDidStart: 后可用） |
| `resetInternalState` | 子类重置内部状态的钩子方法 |
| `PlayerNotificationDelegate` | 子类直接实现回调方法接收事件 |

### **7.4 StrategyManager 方法**

| 方法 | 说明 |
|-----|------|
| `registerStrategy:` | 注册策略 |
| `unregisterStrategyWithName:` | 按名称注销策略 |
| `startWithController:playerModel:` | 启动所有策略 |
| `stop` | 停止所有策略 |
| `resetWithPlayerModel:` | 重置所有策略 |
| `destroy` | 销毁管理器 |
| `strategyWithName:` | 按名称查询策略 |

### **7.5 StrategyRegistry 方法**

| 方法 | 说明 |
|-----|------|
| `-addGlobalStrategyFactory:` | 注册全局策略工厂 |
| `-clearGlobalStrategies` | 清除所有全局策略 |
| `-applyToManager:` | 将全局策略应用到指定管理器 |
| `-resetToDefault` | 恢复默认配置 |

### **7.6 StrategyContext 属性**

| 属性 | 类型 | 说明 |
|-----|------|------|
| `playerId` | `NSString *` | 播放器 ID |
| `model` | `AliPlayerModel *` | 播放数据模型 |
| `stateStore` | `id<AliPlayerStateStoreProtocol>` | 播放器状态存储（只读） |

---

## **8. 下一步**

- 了解事件系统如何驱动策略：[事件系统](./EventSystem.md)
- 了解插槽系统如何与策略协作：[插槽系统](./SlotSystem.md)
- 查看完整 API 参考：[API 文档](../ApiReference.md)
