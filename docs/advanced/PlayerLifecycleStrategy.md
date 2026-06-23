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
- **灵活**：运行时选择不同策略，无需修改业务代码
- **可扩展**：可实现自定义策略，满足特定业务需求
- **可观测**：统一的生命周期管理，便于监控和调试

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
| 资源清理 | `clear` 清理策略持有的所有播放器实例，恢复初始状态 |
| 预加载 | `preloadWithCount:` 预创建实例到池中，减少首帧耗时（`@optional`） |
| ID 绑定 | `acquirePlayerWithUniqueId:` 按业务唯一标识获取实例（`@optional`） |
| 工厂注入 | `setupWithFactory:` 注入播放器工厂，由 `AliPlayerController` 自动调用 |

### **2.2 内置策略**

AliPlayerKit 提供 4 种内置的播放器生命周期策略：

| 策略 | 类名 | 说明 | 适用场景 |
|-----|------|------|---------|
| 默认策略 | `DefaultLifecycleStrategy` | 每次创建新实例，用完立即销毁 | 普通播放 |
| 复用池策略 | `ReusePoolLifecycleStrategy` | 维护空闲池，优先复用池中实例 | 短视频列表 |
| ID 绑定策略 | `IdScopedPoolLifecycleStrategy` | 为每个 uniqueId 维护独立实例，LRU 淘汰 | 视频预加载 |
| 单例策略 | `SingletonLifecycleStrategy` | 全局唯一实例，所有获取返回同一实例 | 列表播放、内存敏感场景 |

### **2.3 架构层次**

```text
┌──────────────────────────────────────────────────────────────┐
│                  AliPlayerController                          │
│       initWithLifecycleStrategy: 注入策略                      │
│       configure: 内部调用 recycle(旧) + acquire(新)             │
│       destroy: 内部调用 recycle(player, force:YES)              │
├──────────────────────────────────────────────────────────────┤
│              PlayerLifecycleStrategy 协议                      │
│   setupWithFactory: / acquirePlayer / recyclePlayer:force:     │
│   clear / preloadWithCount: / acquirePlayerWithUniqueId:       │
├──────────────────────────────────────────────────────────────┤
│                 BaseLifecycleStrategy 基类                     │
│            factory / createPlayer / destroyPlayer:             │
├──────────┬──────────┬─────────────────┬──────────────────────┤
│ Default  │ReusePool │  IdScopedPool   │     Singleton        │
│ 每次新建  │ 池复用    │  ID 绑定 + LRU  │     全局唯一          │
└──────────┴──────────┴─────────────────┴──────────────────────┘
│                                                                │
│              PlayerFactory 协议 / DefaultPlayerFactory          │
│            createPlayer / destroyPlayer:                        │
└──────────────────────────────────────────────────────────────┘
```

---

## **3. 使用方式**

### **3.1 基本用法 — 默认策略**

最简单的使用方式，无需额外配置。`AliPlayerController` 默认使用 `DefaultLifecycleStrategy`：

```objc
// 创建控制器（自动使用默认策略）
AliPlayerController *controller = [[AliPlayerController alloc] init];

// 创建播放数据
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];

// 配置并绑定到播放器视图
[controller configure:model];
[self.playerView attach:controller];
```

**默认策略行为**：每次 `acquirePlayer` 创建新实例，每次 `recyclePlayer:force:` 立即销毁，不维护任何池。

### **3.2 复用池策略（短视频场景）**

适合短视频列表、信息流等频繁切换视频的场景：

```objc
// 1. 创建复用池策略（最大容量 3）
ReusePoolLifecycleStrategy *strategy =
    [[ReusePoolLifecycleStrategy alloc] initWithMaxPoolSize:3];

// 2. 创建控制器时注入策略
//    控制器自动调用 setupWithFactory: 注入默认工厂，无需手动设置
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 3. 正常配置和使用
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
```

> **说明**：`AliPlayerController` 在 `initWithLifecycleStrategy:` 时自动调用 `[strategy setupWithFactory:[AliPlayerKit playerFactory]]` 注入默认工厂，调用方无需手动初始化策略。

### **3.3 ID 绑定策略（预加载场景）**

适合需要预加载和多视频切换的场景，相同 `uniqueId` 始终返回同一实例：

```objc
// 1. 创建 ID 绑定策略（最大容量 3）
IdScopedPoolLifecycleStrategy *strategy =
    [[IdScopedPoolLifecycleStrategy alloc] initWithMaxPoolSize:3];

// 2. 创建控制器时注入策略
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 3. 使用 —— configure 内部通过 VideoSource.uniqueId 进行 ID 绑定
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                              playAuth:@"your_play_auth"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];

// 下次 configure 同一 uniqueId 时，内部 acquire 直接命中已有实例
```

### **3.4 单例策略（列表播放场景）**

全局唯一实例，所有控制器共享同一播放器：

```objc
// 获取单例策略（dispatch_once 保证全局唯一）
SingletonLifecycleStrategy *strategy =
    [SingletonLifecycleStrategy sharedInstance];

// 创建控制器
AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];

// 所有使用此策略的控制器共享同一播放器实例
VideoSource *source = [VideoSource urlSourceWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
[controller configure:model];
[self.playerView attach:controller];
```

> **注意**：使用单例策略时，多个 `AliPlayerController` 不可同时持有播放器，否则会导致状态冲突。`SingletonLifecycleStrategy` 的 `init` 方法被标记为 `NS_UNAVAILABLE`，只能通过 `+sharedInstance` 获取。

### **3.5 场景参考：列表播放**

`ScenePlaylistViewController` 展示了 `SingletonLifecycleStrategy` 实现自动连播的完整用法：

```objc
// 初始化播放器生命周期策略
self.lifecycleStrategy = [SingletonLifecycleStrategy sharedInstance];

// 创建控制器并注入策略
self.currentController = [[AliPlayerController alloc]
    initWithLifecycleStrategy:self.lifecycleStrategy];

// 注册播放完成通知（用于触发自动播放下一个）
[self.currentController addNotificationDelegate:self];

// 配置数据并绑定（挂载后自动开始播放）
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
[self.currentController configure:model];
[self.playerView attach:self.currentController];

// PlayerNotificationDelegate 回调 — 播放完成后自动播放下一个
- (void)playerDidCompletion {
    [self playNextVideo];
}
```

> **说明**：列表播放场景通过 `SingletonLifecycleStrategy` 复用播放器实例，避免频繁创建和销毁带来的性能开销。切换视频时，`configure:` 内部自动执行 `recycle(旧实例)` + `acquire(新实例)`，无需手动管理播放器生命周期。

---

## **4. 策略详解**

### **4.1 DefaultLifecycleStrategy**

最简单的策略，等价于未引入生命周期策略前的原始行为。

```objc
@interface DefaultLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>
@end
```

**特点**：

- 无状态，每次 `acquirePlayer` 通过工厂创建新实例
- 每次 `recyclePlayer:force:` 直接销毁实例，无论 `force` 值
- 内存占用最低（用完即释放）
- 适合大多数标准播放场景

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquirePlayer` | 通过工厂创建新实例 |
| `recyclePlayer:force:` | 直接销毁实例（无论 `force` 为何值） |
| `clear` | 无操作（不维护任何池） |

### **4.2 ReusePoolLifecycleStrategy**

基于对象池模式，维护空闲池和活跃列表。

```objc
@interface ReusePoolLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// 池的最大容量，默认为 3。超出此容量时 recycle 将直接销毁。
@property (nonatomic, assign) NSInteger maxPoolSize;

/// 当前池中空闲播放器数量
@property (nonatomic, assign, readonly) NSInteger idleCount;

/// 当前已 acquire 但未 recycle 的活跃播放器数量
@property (nonatomic, assign, readonly) NSInteger activeCount;

- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize NS_DESIGNATED_INITIALIZER;

@end
```

**特点**：

- 空闲池优先复用，减少播放器初始化开销
- 支持 `preloadWithCount:` 预填充池
- 池容量通过 `maxPoolSize` 控制
- 所有方法线程安全
- 适合短视频列表、信息流场景

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquirePlayer` | 优先从空闲池取出，池空则通过工厂创建新实例 |
| `recyclePlayer:force:NO` | 停止播放，归还到空闲池；池满则销毁 |
| `recyclePlayer:force:YES` | 立即销毁实例 |
| `clear` | 销毁所有空闲池中的实例，活跃实例不受影响 |
| `preloadWithCount:` | 预创建实例放入空闲池，数量受 `maxPoolSize` 限制 |

### **4.3 IdScopedPoolLifecycleStrategy**

为每个 `uniqueId` 维护独立的播放器实例。相同 `uniqueId` 始终返回同一实例。使用 **LRU（最近最少使用）** 机制控制实例数量。

```objc
@interface IdScopedPoolLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// 池的最大容量，默认为 3。超过时 LRU 自动淘汰最近最少使用的实例。
/// 修改此值时，如果新值小于当前实例数量，会立即按 LRU 顺序淘汰多余实例。
@property (nonatomic, assign) NSInteger maxPoolSize;

/// 当前映射表中的播放器实例数量（含活跃和空闲）
@property (nonatomic, assign, readonly) NSInteger poolCount;

- (instancetype)initWithMaxPoolSize:(NSInteger)maxPoolSize NS_DESIGNATED_INITIALIZER;

@end
```

**特点**：

- ID 绑定，相同 `uniqueId` 始终复用同一实例
- LRU 淘汰机制，自动清理最近最少使用的实例
- 支持 `preloadWithCount:` 预创建未绑定实例
- 所有方法线程安全
- 设计参考阿里云微短剧解决方案中的多实例播放器池 LRU 管理机制
- 适合视频预加载、多视频切换场景

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquirePlayerWithUniqueId:` (ID 命中) | 返回已有实例，更新 LRU 顺序 |
| `acquirePlayerWithUniqueId:` (ID 未命中) | 优先从预加载队列取，否则创建新实例并绑定 ID |
| `recyclePlayer:uniqueId:force:NO` | 仅停止播放，保留在映射表中（由 LRU 自动淘汰） |
| `recyclePlayer:uniqueId:force:YES` | 从映射表移除并立即销毁 |
| `clear` | 清理预加载队列和映射表中的实例 |
| `preloadWithCount:` | 创建未绑定 ID 的实例，首次 acquire 新 ID 时从中取出 |

> **说明**：当策略实现了 `acquirePlayerWithUniqueId:` 方法时，`AliPlayerController` 会优先调用它代替 `acquirePlayer`，通过 `VideoSource.uniqueId` 实现 ID 绑定。同理，`recyclePlayer:uniqueId:force:` 会优先于 `recyclePlayer:force:` 被调用。

### **4.4 SingletonLifecycleStrategy**

全局维护唯一一个播放器实例。通过 `dispatch_once` 真单例模式实现。

```objc
@interface SingletonLifecycleStrategy : BaseLifecycleStrategy <PlayerLifecycleStrategy>

/// 获取全局共享的单例策略实例
+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
```

**特点**：

- 全局唯一，所有使用此策略的控制器共享同一播放器实例
- 内存占用最低
- `clear` 为空操作（不销毁单例实例），需通过 `recyclePlayer:force:YES` 显式销毁
- 不适合多视频同时播放场景
- 多个 `AliPlayerController` 不可同时持有播放器，否则会导致状态冲突

**核心流程**：

| 操作 | 行为 |
|------|------|
| `acquirePlayer` | 全局实例存在则直接返回，否则创建 |
| `recyclePlayer:force:NO` | 仅停止播放，保留实例 |
| `recyclePlayer:force:YES` | 销毁全局实例 |
| `clear` | 空操作（不销毁单例实例） |

### **4.5 策略对比表**

| 策略 | 获取行为 | 回收行为 (force:NO) | 适用场景 | 首帧速度 | 线程安全 |
|-----|---------|-------------------|---------|---------|---------|
| **Default** | 每次新建 | 立即销毁 | 普通播放 | 慢 | — |
| **ReusePool** | 池中取/新建 | 归还到池/池满销毁 | 短视频列表 | 快 | 是 |
| **IdScoped** | ID 命中/预加载/新建 | 保持在映射表/LRU 淘汰 | 预加载 | 最快 | 是 |
| **Singleton** | 只创建一次 | 仅停止播放 | 列表播放 | 中 | — |

---

## **5. 自定义开发**

### **5.1 策略协议 (PlayerLifecycleStrategy)**

所有生命周期策略都遵循 `PlayerLifecycleStrategy` 协议：

```objc
@protocol PlayerLifecycleStrategy <NSObject>

@required

/// 注入播放器工厂（由 AliPlayerController 自动调用）
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/// 获取播放器实例（由策略决定创建或复用）
- (id<MediaPlayer>)acquirePlayer;

/// 回收播放器实例（force:YES 强制销毁，force:NO 由策略决定）
- (void)recyclePlayer:(nullable id<MediaPlayer>)player force:(BOOL)force;

/// 释放策略持有的所有播放器实例，恢复初始状态
- (void)clear;

@optional

/// 预加载指定数量的播放器实例到池中
- (void)preloadWithCount:(NSInteger)count;

/// 根据业务唯一标识获取播放器实例（仅 IdScopedPoolLifecycleStrategy 实现）
- (id<MediaPlayer>)acquirePlayerWithUniqueId:(NSString *)uniqueId;

/// 根据业务唯一标识回收播放器实例（仅 IdScopedPoolLifecycleStrategy 实现）
- (void)recyclePlayer:(nullable id<MediaPlayer>)player
             uniqueId:(NSString *)uniqueId
                force:(BOOL)force;

@end
```

> **说明**：`setupWithFactory:` 由 `AliPlayerController` 在 `initWithLifecycleStrategy:` 时自动调用，注入 `[AliPlayerKit playerFactory]` 返回的工厂实例。开发者通常不需要手动调用此方法。如需预加载（在创建 Controller 之前），可手动调用 `setupWithFactory:` 后再调用 `preloadWithCount:`。

### **5.2 策略基类 (BaseLifecycleStrategy)**

`BaseLifecycleStrategy` 是所有内置策略的共享基类，提供工厂管理和模板方法：

```objc
@interface BaseLifecycleStrategy : NSObject

/// 当前注入的播放器工厂（只读）
@property (nonatomic, strong, readonly) id<PlayerFactory> factory;

/// 注入播放器工厂（幂等，仅首次调用生效，重复调用打印警告并忽略）
- (void)setupWithFactory:(id<PlayerFactory>)factory;

/// 通过工厂创建新的播放器实例（子类应调用此方法而非直接调用 factory）
- (id<MediaPlayer>)createPlayer;

/// 通过工厂销毁播放器实例（子类应调用此方法而非直接调用 factory）
- (void)destroyPlayer:(nullable id<MediaPlayer>)player;

@end
```

> **说明**：`BaseLifecycleStrategy` 本身**不声明** `PlayerLifecycleStrategy` 协议一致性，子类需自行声明并实现 `acquirePlayer`、`recyclePlayer:force:`、`clear` 等方法。子类应通过 `createPlayer` / `destroyPlayer:` 模板方法操作播放器实例，而非直接调用 `factory`，以确保操作被统一记录。

### **5.3 播放器工厂 (PlayerFactory)**

`PlayerFactory` 协议定义了播放器实例的创建与销毁接口：

```objc
@protocol PlayerFactory <NSObject>

/// 创建播放器实例（每次调用创建新实例，处于 PlayerStateIdle 状态）
- (id<MediaPlayer>)createPlayer;

/// 销毁播放器实例（释放所有资源，nil 时仅记录警告日志）
- (void)destroyPlayer:(nullable id<MediaPlayer>)player;

@end
```

框架内置 `DefaultPlayerFactory`，使用阿里云播放器 SDK（AliPlayer）创建标准实例。可通过 `[AliPlayerKit setPlayerFactory:]` 替换为自定义工厂。

### **5.4 自定义策略示例**

以下示例展示了一个基于 ID 映射的简单缓存策略：

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

注册并使用：

```objc
MyCacheLifecycleStrategy *strategy = [[MyCacheLifecycleStrategy alloc] init];

AliPlayerController *controller =
    [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
// controller 自动调用 [strategy setupWithFactory:...] 注入工厂
```

---

## **6. 生命周期流程**

### **6.1 控制器与策略的交互流程**

```text
AliPlayerController 初始化
    ↓
initWithLifecycleStrategy: → 保存策略引用
    ↓                       → 自动调用 [strategy setupWithFactory:[AliPlayerKit playerFactory]]
    ↓
[controller configure:model]
    ↓
    ├── 已有播放器? → [strategy recyclePlayer:旧实例 force:NO]
    ↓
    ├── strategy 实现了 acquirePlayerWithUniqueId:?
    │   ├── YES → [strategy acquirePlayerWithUniqueId:source.uniqueId]
    │   └── NO  → [strategy acquirePlayer]
    ↓
    ├── [player setDataSource:model]
    ├── [player prepare]
    └── autoPlay ? → [player start]
    ↓
切换视频源 → [controller configure:newModel]
    ↓         → recycle(旧) + acquire(新) + setDataSource + prepare
    ↓
[controller destroy]
    ↓
    ├── [strategy recyclePlayer:player force:YES]
    └── 控制器释放
```

### **6.2 策略资源清理时机**

| 时机 | 操作 | 说明 |
|------|------|------|
| 视频切换 | `configure:` 内部 recycle + acquire | 自动完成，无需手动操作 |
| 控制器销毁 | `destroy` 内部 `recyclePlayer:force:YES` | 自动完成 |
| 页面退出 | `dealloc` 中调用 `[controller destroy]` | 必须手动调用 |
| 释放池资源 | `[strategy clear]` | 按需调用（如内存警告时） |

---

## **7. 最佳实践**

### **7.1 策略选择指南**

| 需求场景 | 推荐策略 | 原因 |
|---------|---------|------|
| 普通视频详情页 | Default | 简单直接，页面销毁即释放 |
| 短视频上下滑列表 | ReusePool | 复用实例减少创建开销，提升滑动流畅度 |
| 视频预加载/秒开 | IdScoped | ID 绑定 + 预加载实现极速起播 |
| 列表连续播放 | Singleton | 全局唯一实例，减少初始化次数 |
| 低端设备/内存紧张 | Singleton | 全局唯一，内存占用最小 |
| 播客/音频播放 | Singleton | 单音频流场景无需多实例 |

### **7.2 内存管理建议**

| 建议 | 说明 |
|------|------|
| 监听内存警告 | 池策略应监听 `UIApplicationDidReceiveMemoryWarningNotification` 并调用 `clear` |
| 合理设置池容量 | 每个播放器实例约占用 35~40MB 内存，根据设备性能设置 `maxPoolSize` |
| 后台释放空闲池 | 进入后台时可调用 `clear` 释放空闲实例 |
| 页面销毁必须 destroy | `dealloc` 中必须调用 `[controller destroy]`，否则会导致内存泄漏 |

```objc
// 监听内存警告，释放池资源
[[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(handleMemoryWarning:)
           name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];

- (void)handleMemoryWarning:(NSNotification *)notification {
    [self.lifecycleStrategy clear];
}
```

### **7.3 页面生命周期管理**

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
    // 必须：销毁控制器
    if (_controller) {
        [_controller destroy];
    }
    // 可选：如果此页面是策略的最后使用者，释放池资源
    if (_lifecycleStrategy) {
        [_lifecycleStrategy clear];
    }
}

@end
```

### **7.4 注意事项**

| 场景 | 推荐做法 | 原因 |
|-----|---------|------|
| 页面销毁 | `dealloc` 中调用 `[controller destroy]` | 避免内存泄漏 |
| 策略清理 | 最后使用者调用 `[strategy clear]` | 释放池中空闲实例 |
| 单例策略 | 不要同时多个 Controller 持有 | 避免状态冲突 |
| 工厂注入 | 不要手动调用 `setupWithFactory:` | Controller 自动注入，且该方法幂等（仅首次生效） |
| 预加载 | 在 Controller 创建后调用 | Controller 创建时自动注入工厂 |

### **7.5 常见错误**

```objc
// ✗ 错误：忘记在 dealloc 中销毁控制器
- (void)dealloc {
    [self.playerView detach];
    // 未调用 [_controller destroy]，导致内存泄漏
}

// ✓ 正确：销毁控制器并按需清理策略
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
// ✗ 错误：单例策略下同时持有多个 Controller
SingletonLifecycleStrategy *strategy = [SingletonLifecycleStrategy sharedInstance];
AliPlayerController *controller1 = [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
AliPlayerController *controller2 = [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
// controller1 和 controller2 共享同一播放器实例，导致状态冲突

// ✓ 正确：确保同一时间只有一个 Controller 使用单例策略
[controller1 destroy];
AliPlayerController *controller2 = [[AliPlayerController alloc] initWithLifecycleStrategy:strategy];
```

```objc
// ✗ 错误：尝试 alloc init SingletonLifecycleStrategy
SingletonLifecycleStrategy *strategy = [[SingletonLifecycleStrategy alloc] init]; // 编译错误

// ✓ 正确：通过 sharedInstance 获取
SingletonLifecycleStrategy *strategy = [SingletonLifecycleStrategy sharedInstance];
```

---

## **8. API 速查**

### **8.1 核心类与协议**

| 协议 / 类 | 说明 |
|-----------|------|
| `PlayerLifecycleStrategy` | 生命周期策略协议，定义获取/回收/清理接口 |
| `BaseLifecycleStrategy` | 策略基类，提供工厂管理和 createPlayer/destroyPlayer: 模板方法 |
| `PlayerFactory` | 播放器工厂协议，定义创建/销毁接口 |
| `DefaultPlayerFactory` | 默认工厂实现，使用阿里云播放器 SDK 创建实例 |
| `MediaPlayer` | 媒体播放器协议，定义播放控制、状态查询等接口 |

### **8.2 内置策略**

| 类 | 创建方式 | 关键属性 |
|----|---------|---------|
| `DefaultLifecycleStrategy` | `[[... alloc] init]` | — |
| `ReusePoolLifecycleStrategy` | `[[... alloc] initWithMaxPoolSize:]` | `maxPoolSize`、`idleCount`、`activeCount` |
| `IdScopedPoolLifecycleStrategy` | `[[... alloc] initWithMaxPoolSize:]` | `maxPoolSize`、`poolCount` |
| `SingletonLifecycleStrategy` | `[... sharedInstance]` | — |

### **8.3 PlayerLifecycleStrategy 方法**

| 方法 | 必选 | 说明 |
|------|------|------|
| `setupWithFactory:` | 是 | 注入播放器工厂（Controller 自动调用） |
| `acquirePlayer` | 是 | 获取播放器实例 |
| `recyclePlayer:force:` | 是 | 回收播放器实例 |
| `clear` | 是 | 释放所有缓存实例 |
| `preloadWithCount:` | 否 | 预加载实例（ReusePool / IdScoped 实现） |
| `acquirePlayerWithUniqueId:` | 否 | 按 uniqueId 获取实例（IdScoped 实现） |
| `recyclePlayer:uniqueId:force:` | 否 | 按 uniqueId 回收实例（IdScoped 实现） |

### **8.4 BaseLifecycleStrategy 方法**

| 方法/属性 | 说明 |
|----------|------|
| `factory` | 当前注入的播放器工厂（只读） |
| `setupWithFactory:` | 注入工厂（幂等，仅首次调用生效） |
| `createPlayer` | 通过工厂创建实例，统一记录日志 |
| `destroyPlayer:` | 通过工厂销毁实例，统一记录日志 |

### **8.5 force 参数说明**

| force 值 | 行为 | 使用场景 |
|----------|------|---------|
| `NO` | 策略自行决定：回收到池中或仅停止播放 | 正常视频切换（`configure:` 内部使用） |
| `YES` | 无论策略如何，立即销毁实例 | 控制器销毁（`destroy` 内部使用） |

### **8.6 uniqueId 说明**

`uniqueId` 是 `VideoSource` 上的业务唯一标识属性，用于区分不同视频源。不同策略对其使用方式不同：

| 策略 | uniqueId 用途 |
|------|-------------|
| Default | 不使用 |
| ReusePool | 不使用 |
| IdScoped | **核心标识**，同一 uniqueId 始终返回相同实例 |
| Singleton | 不使用 |

---

## **9. 示例参考**

> **参考**：`PlayerKitUsages/UsageLifecycleStrategy` 模块提供了完整的播放器生命周期策略使用示例，演示了四种内置策略（Default、ReusePool、Singleton、IdScopedPool）的切换对比、多视频源播放下的实例复用行为（NEW/REUSED/HIT），以及策略与控制器的资源清理流程。
