# **播放器生命周期策略 (Player Lifecycle Strategy)**

**播放器生命周期策略 (Player Lifecycle Strategy)** 是 AliPlayerKit 的核心架构设计，用于统一管理播放器实例的 **创建、复用、回收与销毁**，在不同业务场景下实现更合理的资源调度与性能优化。

---

## **1. 概念介绍**

### **1.1 什么是播放器生命周期策略？**

播放器生命周期策略是用于管理播放器实例生命周期的架构机制。它定义了播放器实例的获取（acquire）、回收（recycle）、清理（clear）等核心操作，将播放器资源管理从业务代码中解耦出来。

不同的业务场景对播放器实例的管理有不同的需求：

| 场景 | 需求特点 | 推荐策略 |
|-----|---------|---------|
| 普通视频播放 | 简单直接，无需复用 | Default |
| 短视频列表 | 频繁切换，需要快速起播 | ReusePool |
| 视频预加载 | ID 与实例绑定，支持预加载 | IdScopedPool |
| 内存敏感场景 | 全局唯一实例，最小内存占用 | Singleton |

### **1.2 核心价值**

通过策略模式管理播放器生命周期，带来以下核心优势：

- **解耦**：业务代码无需关心播放器实例的创建和销毁细节
- **灵活**：运行时动态切换策略，无需修改业务代码
- **可扩展**：可实现自定义策略，满足特定业务需求
- **可观测**：统一的生命周期事件，便于监控和调试

### **1.3 设计背景**

播放器生命周期策略的架构设计，源于**阿里云微短剧解决方案**中的多实例播放器池。微短剧场景下，用户在信息流中快速滑动切换视频，对播放器性能提出了极高要求：**首帧要快、切换要顺滑、内存要可控**。

AliPlayerKit 将这一实践经验抽象为**策略模式**，形成更加通用、灵活的播放器生命周期管理架构。

---

## **2. 功能特性**

### **2.1 核心能力**

| 能力 | 说明 |
|-----|------|
| 实例获取 | `acquirePlayer` 获取播放器实例，由策略决定创建或复用 |
| 实例回收 | `recyclePlayer:force:` 回收实例，由策略决定销毁或保留 |
| 资源清理 | `clear` 清理所有资源，支持安全释放 |
| 预加载 | `preloadWithCount:` 预创建实例，减少首帧耗时 |
| 池容量控制 | `setMaxPoolSize:` 动态调整池容量 |

### **2.2 内置组件**

AliPlayerKit 提供 4 种内置的播放器生命周期策略：

| 策略 | 类名 | 说明 | 适用场景 | 内存占用 |
|-----|------|------|---------|---------|
| 默认策略 | `DefaultLifecycleStrategy` | 每次创建新实例，用完立即销毁 | 普通播放 | 低 |
| 复用池策略 | `ReusePoolLifecycleStrategy` | 维护空闲池，LIFO 复用 | 短视频列表 | 中 |
| ID 绑定策略 | `IdScopedPoolLifecycleStrategy` | 为每个 ID 维护独立实例，LRU 淘汰 | 视频预加载 | 中 |
| 单例策略 | `SingletonLifecycleStrategy` | 全局唯一实例 | 内存敏感场景 | 最低 |

### **2.3 生命周期事件**

策略执行过程中会发布生命周期事件，可通过事件总线监听：

| 事件 | 说明 | 触发时机 |
|-----|------|---------|
| PlayerCreated | 播放器创建 | 创建新实例时 |
| PlayerDestroyed | 播放器销毁 | 销毁实例时 |
| PlayerReused | 播放器复用 | 从池中取出复用时 |
| PlayerHit | 播放器命中 | 相同 ID 命中已存在实例时 |
| PlayerEvicted | 播放器淘汰 | LRU 淘汰或池满时 |

---

## **3. 使用方式**

### **3.1 基本用法 — 默认策略**

最简单的使用方式，无需额外配置。`AliPlayerController` 默认使用 `DefaultLifecycleStrategy`：

```objc
// 创建控制器（自动使用默认策略）
AliPlayerController *controller = [[AliPlayerController alloc] init];

// 创建视频源
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];

// 创建播放数据
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeVOD;
model.autoPlay = YES;

// 配置并绑定到播放器视图
[controller configure:model];
[self.playerView attach:controller];
```

**默认策略行为**：每次 `acquire` 创建新实例，每次 `recycle` 立即销毁，不维护任何池。

### **3.2 高级用法 — 复用池策略（短视频场景）**

适合短视频列表、信息流等频繁切换视频的场景：

```objc
// 1. 创建复用池策略
ReusePoolLifecycleStrategy *strategy =
    [[ReusePoolLifecycleStrategy alloc] initWithMaxPoolSize:3];

// 2. 预加载（可选，减少首帧耗时）
[strategy preloadWithCount:2];

// 3. 创建控制器时注入策略
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 4. 正常绑定和使用
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
```

**页面销毁时的清理**：

```objc
- (void)dealloc {
    [self.playerView detach];
    // detach 内部会 recycle(force:NO)，实例归还到池中

    // 如需彻底释放池资源：
    // [self.lifecycleStrategy clear];
}
```

### **3.3 高级用法 — ID 绑定策略（预加载场景）**

适合需要预加载和多视频切换的场景，相同 `uniqueId` 始终返回同一实例：

```objc
// 1. 创建 ID 绑定策略
IdScopedPoolLifecycleStrategy *strategy =
    [[IdScopedPoolLifecycleStrategy alloc] initWithMaxPoolSize:3];

// 2. 预加载未绑定实例
[strategy preloadWithCount:2];

// 3. 创建控制器时注入策略
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 4. 使用 —— 同一 mediaId 总是返回同一实例
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"your_video_id" playAuth:@"your_play_auth"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
// 下次 acquire 同一 mediaId 时，直接命中已有实例（PlayerHit 事件）
```

### **3.4 高级用法 — 单例策略（内存敏感场景）**

全局唯一实例，所有位置共享同一播放器：

```objc
// 获取单例策略
SingletonLifecycleStrategy *strategy =
    [SingletonLifecycleStrategy sharedInstance];

// 创建控制器
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 所有位置使用同一播放器实例
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
```

> **注意**：单例策略下切换内容时底层播放器实例不变，需先 `stop` 再重新配置数据源。

### **3.5 预加载时机建议**

| 时机 | 说明 |
|-----|------|
| App 启动后 | 在 `application:didFinishLaunchingWithOptions:` 中完成初始化后异步预加载 |
| 列表页加载前 | 在短视频列表 VC 的 `viewDidLoad` 中预加载 1~2 个实例 |
| 数据请求返回后 | 获取到视频列表数据后，为即将显示的视频预加载 |

```objc
// App 启动时异步预加载
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [AliPlayerKit setup]

    // 异步预加载，不阻塞启动
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ReusePoolLifecycleStrategy *strategy =
            [[ReusePoolLifecycleStrategy alloc] initWithMaxPoolSize:3];
        [strategy setupWithFactory:[[DefaultPlayerFactory alloc] init]];
        [strategy preloadWithCount:2];
    });

    return YES;
}
```

---

## **4. 策略详解**

### **4.1 DefaultLifecycleStrategy**

最简单的策略，每次调用 `acquire` 创建新实例，每次 `recycle` 立即销毁。

**特点**：

- 无状态，每次都是全新实例
- 无复用，适合简单场景
- 内存占用最低（用完即释放）

```objc
@interface DefaultLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>
@end

@implementation DefaultLifecycleStrategy

- (id<MediaPlayer>)acquirePlayer {
    // 每次创建新实例
    id<MediaPlayer> player = [self createPlayer];
    return player;
}

- (void)recyclePlayer:(id<MediaPlayer>)player force:(BOOL)force {
    if (!player) return;
    // 无论 force 为何值，都立即销毁
    [self destroyPlayer:player];
}

@end
```

### **4.2 ReusePoolLifecycleStrategy**

基于对象池模式，维护空闲池和活跃列表。使用 **LIFO（后进先出）** 策略复用实例。

**特点**：

- 空闲池 LIFO 策略，最近使用的实例优先复用
- 支持预加载，提前创建实例
- 池容量可配置，超出时销毁多余实例
- 适合短视频列表、信息流场景

**LIFO 的原因**：在 Feed 流场景下，刚归还到池中的实例，其底层解码器上下文与硬件资源最"热"（缓存未被系统回收），优先复用能减少上下文重置耗时，提升起播速度。

**内存建议**：每个播放器实例约占用 35~40MB 内存。默认池容量为 3，可根据设备性能调整。

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquire` | 优先从空闲池取出（LIFO），池空则创建新实例 |
| `recycle (force:NO)` | 停止播放，归还到空闲池；池满则销毁 |
| `recycle (force:YES)` | 立即销毁实例 |
| `clear` | 销毁所有空闲池中的实例，活跃实例不受影响 |
| `preload` | 预创建实例放入空闲池，数量受 `maxPoolSize` 限制 |

### **4.3 IdScopedPoolLifecycleStrategy**

为每个 `uniqueId` 维护独立的播放器实例。相同 `uniqueId` 始终返回同一实例。使用 **LRU（最近最少使用）** 机制控制实例数量。

**特点**：

- ID 绑定，相同 ID 始终复用同一实例
- LRU 淘汰机制，自动清理最近最少使用的实例
- 支持预加载，提前创建未绑定实例
- 适合视频预加载、多视频切换场景

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquire` (ID 命中) | 返回已有实例，更新 LRU 顺序 |
| `acquire` (ID 未命中) | 优先从预加载队列取，否则创建新实例并绑定 ID |
| `recycle (force:NO)` | 仅停止播放，保留在映射表中（由 LRU 自动淘汰） |
| `recycle (force:YES)` | 从映射表移除并立即销毁 |
| `clear` | 清理预加载队列和映射表中非活跃实例 |
| `preload` | 创建未绑定 ID 的实例，首次 acquire 新 ID 时从中取出 |

### **4.4 SingletonLifecycleStrategy**

全局维护唯一一个播放器实例。无论 `uniqueId` 为何值，始终返回同一实例。

**特点**：

- 全局唯一，所有位置共享同一实例
- 内存占用最低
- 不适合多视频同时播放场景

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquire` | 全局实例存在则直接返回，否则创建 |
| `recycle (force:NO)` | 仅停止播放，保留实例 |
| `recycle (force:YES)` | 销毁全局实例 |
| `clear` | 不销毁实例（可能正在使用） |
| `preload` | 如全局实例不存在则创建 |

### **4.5 策略对比表**

| 策略 | 创建方式 | 回收方式 | 适用场景 | 内存占用 | 首帧速度 |
|-----|---------|---------|---------|---------|---------|
| **Default** | 每次新建 | 立即销毁 | 普通播放 | 低 | 慢 |
| **ReusePool** | 池中取/新建 | 归还到池/池满销毁 | 短视频列表 | 中 | 快 |
| **IdScoped** | ID 命中/预加载/新建 | 保持在映射表/LRU 淘汰 | 预加载 | 中 | 最快 |
| **Singleton** | 只创建一次 | 不销毁（仅停止） | 内存敏感 | 最低 | 中 |

---

## **5. 自定义开发**

### **5.1 策略协议**

所有生命周期策略都遵循 `PlayerLifecycleStrategy` 协议：

```objc
@protocol PlayerLifecycleStrategy <NSObject>

@required

/// 初始化策略，注入播放器工厂
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/// 获取播放器实例
- (id<MediaPlayer>)acquirePlayer;

/// 回收播放器实例
- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force;

/// 清空所有资源
- (void)clear;

@optional

/// 预加载播放器实例
- (void)preloadWithCount:(NSInteger)count;

/// 根据业务唯一标识获取播放器实例
- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId;

/// 根据业务唯一标识回收播放器实例
- (void)recyclePlayer:(nullable id<MediaPlayer>)player uniqueId:(NSString *)uniqueId force:(BOOL)force;

@end
```

### **5.2 策略基类**

继承 `BaseLifecycleStrategy` 可以复用通用逻辑：

```objc
@interface BaseLifecycleStrategy : NSObject <PlayerLifecycleStrategy>

/// 默认播放器池最大容量（默认 3）
@property (nonatomic, assign) NSInteger maxPoolSize;

@end
```

基类提供的辅助方法：

| 方法 | 说明 |
|------|------|
| `createPlayer` | 通过工厂创建实例，并发送 PlayerCreated 事件 |
| `destroyPlayer:` | 通过工厂销毁实例，并发送 PlayerDestroyed 事件 |
| `onMaxPoolSizeUpdated:` | 钩子方法，`maxPoolSize` 更新时调用 |

### **5.3 自定义策略示例**

```objc
/// 自定义策略示例：基于 ID 映射的简单缓存策略
@interface MyCustomLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>
@end

@implementation MyCustomLifecycleStrategy {
    NSMutableDictionary<NSString *, id<MediaPlayer>> *_playerMap;
    dispatch_queue_t _syncQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _playerMap = [NSMutableDictionary dictionary];
        _syncQueue = dispatch_queue_create("com.example.custom.strategy",
                                           DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId {
    __block id<MediaPlayer> player = nil;

    dispatch_sync(_syncQueue, ^{
        player = _playerMap[uniqueId];
        if (!player) {
            player = [self createPlayer];
            _playerMap[uniqueId] = player;
        }
    });

    return player;
}

- (void)recyclePlayer:(id<MediaPlayer>)player
             uniqueId:(NSString *)uniqueId
                force:(BOOL)force {
    if (!player) return;

    dispatch_sync(_syncQueue, ^{
        if (force) {
            [_playerMap removeObjectForKey:uniqueId];
            [self destroyPlayer:player];
        } else {
            [player stop];
        }
    });
}

- (void)clear {
    dispatch_sync(_syncQueue, ^{
        for (id<MediaPlayer> player in _playerMap.allValues) {
            [self destroyPlayer:player];
        }
        [_playerMap removeAllObjects];
    });
}

@end
```

### **5.4 使用自定义策略**

```objc
MyCustomLifecycleStrategy *strategy = [[MyCustomLifecycleStrategy alloc] init];
[strategy setupWithFactory:[[DefaultPlayerFactory alloc] init]];

AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
```

---

## **6. 最佳实践**

### **6.1 策略选择指南**

| 需求场景 | 推荐策略 | 原因 |
|---------|---------|------|
| 普通视频详情页 | Default | 简单直接，页面销毁即释放 |
| 短视频上下滑列表 | ReusePool | LIFO 复用减少创建开销 |
| 视频预加载/秒开 | IdScoped | ID 绑定 + 预加载实现极速起播 |
| 低端设备/内存紧张 | Singleton | 全局唯一，内存占用最小 |
| 播客/音频播放 | Singleton | 单音频流场景无需多实例 |

### **6.2 内存管理建议**

| 建议 | 说明 |
|------|------|
| 监听内存警告 | 池策略应监听 `UIApplicationDidReceiveMemoryWarningNotification` 并调用 `clear` |
| 合理设置池容量 | 每个实例约 35~40MB，根据设备性能设置 `maxPoolSize` |
| 后台释放空闲池 | 进入后台时可调用 `clear` 释放空闲实例 |
| recycle 后置 nil | 回收后将播放器引用置为 `nil`，避免误用 |

```objc
// 监听内存警告
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(handleMemoryWarning:)
                                             name:UIApplicationDidReceiveMemoryWarningNotification
                                           object:nil];

- (void)handleMemoryWarning:(NSNotification *)notification {
    [self.lifecycleStrategy clear];
}
```

### **6.3 常见错误**

#### **错误 1：忘记清理策略资源**

```objc
// ❌ 错误：只解绑了 View，忘记清理池
- (void)dealloc {
    [self.playerView detach];
}

// ✅ 正确：需要时主动清理
- (void)dealloc {
    [self.playerView detach];
    // 当页面是池策略的最后使用者时，清理资源
    // [self.lifecycleStrategy clear];
}
```

#### **错误 2：回收后继续使用实例**

```objc
// ❌ 错误：recycle 后继续使用
[self.playerView detach];
[player start]; // 可能导致异常

// ✅ 正确：recycle 后置 nil
[self.playerView detach];
player = nil; // 清空引用，避免误用
```

---

## **7. API 速查**

### **7.1 核心协议**

| 协议 / 类 | 说明 | 详见 |
|-----------|------|------|
| `PlayerLifecycleStrategy` | 生命周期策略协议 | [ApiReference.md](../ApiReference.md) |
| `PlayerFactory` | 播放器工厂协议 | [ApiReference.md](../ApiReference.md) |
| `BaseLifecycleStrategy` | 策略基类 | [ApiReference.md](../ApiReference.md) |

### **7.2 内置策略**

| 类 | 单例方式 | 说明 |
|----|---------|------|
| `DefaultLifecycleStrategy` | `alloc init` | 默认策略，每次新建 |
| `ReusePoolLifecycleStrategy` | `alloc initWithMaxPoolSize:` | 复用池策略 |
| `IdScopedPoolLifecycleStrategy` | `alloc initWithMaxPoolSize:` | ID 绑定策略 |
| `SingletonLifecycleStrategy` | `sharedInstance` | 单例策略 |

### **7.3 核心方法**

| 方法 | 参数 | 说明 |
|------|------|------|
| `setupWithFactory:` | `id<PlayerFactory>` | 初始化策略，注入工厂 |
| `acquirePlayer` | — | 获取播放器实例（@required） |
| `recyclePlayer:force:` | player, BOOL | 回收播放器实例（@required） |
| `clear` | — | 清空所有资源 |
| `preloadWithCount:` | `NSInteger count` | 预加载实例 |
| `setMaxPoolSize:` | `NSInteger maxPoolSize` | 设置池容量（默认 3） |

### **7.4 uniqueId 说明**

`uniqueId` 是播放器实例的业务唯一标识，通常使用视频的 `mediaId`。不同策略对其使用方式不同：

| 策略 | uniqueId 用途 |
|------|-------------|
| Default | 仅用于日志记录 |
| ReusePool | 仅用于日志记录 |
| IdScoped | **核心标识**，同一 uniqueId 始终返回相同实例 |
| Singleton | 不影响行为 |

### **7.5 force 参数说明**

| force 值 | 行为 | 使用场景 |
|----------|------|---------|
| `NO` | 策略自行决定是回收到池中还是销毁 | 正常页面切换 |
| `YES` | 无论策略如何，立即销毁实例 | 页面销毁、内存警告 |

---

## **下一步**

- [日志系统](./LogSystem.md) — 了解 AliPlayerKit 的日志管理
- [视频源](./VideoSource.md) — 了解多视频源配置
- [API 参考](../ApiReference.md) — 完整 API 文档
