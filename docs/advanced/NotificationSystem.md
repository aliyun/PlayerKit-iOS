# **通知系统 (Notification System)**

**通知系统 (Notification System)** 是 AliPlayerKit 的组件间通信基础设施。它采用 **Notification Dispatcher + Delegate 协议** 模式，将播放器内部状态变化、手势交互、插槽操作等信息分发给所有关注方，实现播放器控制器、UI 插槽、策略之间的完全解耦。

---

## **1. 概念介绍**

### **1.1 什么是通知系统？**

**通知系统 (Notification System)** 是 PlayerKit 内部的多播通知分发机制。每种 Dispatcher 管理一组弱引用观察者，通过对应的 Delegate 协议定义回调接口，观察者只需实现关心的方法即可接收对应通知。

**核心特征**：

- **多播分发**：每个 Dispatcher 支持注册多个观察者，通知广播给所有已注册的观察者
- **弱引用管理**：观察者通过 `NSHashTable` 以弱引用方式存储，对象释放后自动清理
- **实例级隔离**：每个 `AliPlayerController` 持有独立的 Dispatcher 实例，不同播放器实例的通知互不干扰
- **异常隔离**：每次观察者调用通过 `@try/@catch` 包裹，单个观察者异常不影响其他观察者

### **1.2 解决的问题**

| 问题 | 通知系统的解法 |
|------|--------------|
| 组件间直接依赖导致耦合度高 | 通过 Delegate 协议通信，组件间无直接引用 |
| 多播放器实例通知混乱 | 每个 Controller 持有独立的 Dispatcher 实例，天然隔离 |
| UI 与业务逻辑混杂 | 状态通知下行分发，职责分离 |
| 订阅者泄漏 | `NSHashTable` 弱引用自动管理，对象释放后自动清理 |

### **1.3 核心架构**

PlayerKit 通知系统由三组 Dispatcher + Delegate 协议组成：

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

| Dispatcher | Delegate 协议 | 职责 | 访问方式 |
|-----------|---------------|------|---------|
| `PlayerNotificationDispatcher` | `PlayerNotificationDelegate` | 播放器核心通知：状态、进度、错误、截图、全屏、控制栏、加载、显示模式、轨道 | 通过 Controller 的 `addNotificationDelegate:` |
| `GestureNotificationDispatcher` | `GestureNotificationDelegate` | 手势通知：单击、长按、亮度滑动、音量滑动 | 由 `SlotHostLayout` 注入到内置插槽 |
| `SlotActionNotificationDispatcher` | `SlotActionNotificationDelegate` | 插槽操作通知：设置菜单、倍速面板、画质面板、Seek 预览、章节面板 | 由 `SlotHostLayout` 注入到内置插槽 |

> **说明**：`AliPlayerController` 仅暴露 `PlayerNotificationDelegate` 的注册入口（`addNotificationDelegate:` / `removeNotificationDelegate:`）。`GestureNotificationDispatcher` 和 `SlotActionNotificationDispatcher` 属于插槽内部通信机制，由 `SlotHostLayout` 在插槽构建时自动注入，不对外暴露。

> **跨平台差异**：Android 端采用全局事件总线（`PlayerEventBus`）+ `playerId` 隔离的发布-订阅模式。iOS 端采用实例级 Dispatcher + Delegate 模式，更符合 Cocoa 编程范式。两端功能等价，仅通信机制不同。

---

## **2. 三组 Dispatcher**

### **2.1 PlayerNotificationDispatcher**

播放器核心通知分发器，负责将播放状态变化、进度更新、错误通知等信息分发给所有观察者。

**核心属性与方法：**

| 接口 | 说明 |
|------|------|
| `playerId` | 通知来源播放器的唯一标识符（`NSString`，可读写），由 Controller 在配置 `MediaPlayer` 后写入 |
| `addObserver:` | 添加遵循 `PlayerNotificationDelegate` 的观察者（弱引用，重复添加无效果） |
| `removeObserver:` | 移除指定观察者（未注册则无效果） |
| `removeAllObservers` | 移除所有观察者 |
| `notifyObservers:` | 向所有观察者分发通知 Block |
| `notifyObservers:withBlock:` | 仅向实现了指定 selector 的观察者分发（selector 过滤） |
| `observerCount` | 返回当前活跃观察者数量 |

**便捷分发方法（由 Controller 内部调用）：**

| 方法 | 触发场景 |
|------|---------|
| `dispatchDidChangeState:` | 播放器状态变化 |
| `dispatchDidPreparedWithDuration:` | 准备完成 |
| `dispatchDidRenderFirstFrame` | 首帧渲染 |
| `dispatchDidCompletion` | 播放完成 |
| `dispatchDidUpdatePosition:duration:bufferedPosition:` | 进度更新 |
| `dispatchDidEncounterError:` | 错误发生 |
| `dispatchDidCaptureScreenImage:` | 截图完成 |
| `dispatchDidChangeVideoWidth:height:` | 视频尺寸变化 |
| `dispatchFullscreenChanged:` | 全屏状态变化 |
| `dispatchDidLoadingBegin` | 缓冲开始 |
| `dispatchDidLoadingEnd` | 缓冲结束 |
| `dispatchDidUpdateLoadingProgress:` | 缓冲进度更新 |
| `dispatchDidChangeMirrorMode:` | 镜像模式变化 |
| `dispatchDidChangeScaleMode:` | 缩放模式变化 |
| `dispatchDidChangeRotateMode:` | 旋转模式变化 |
| `dispatchDidTrackReady:` | 轨道信息就绪 |
| `dispatchDidTrackChanged:` | 轨道切换完成 |

> **说明**：`PlayerNotificationDelegate` 定义了 22 个 `@optional` 回调方法，但 Dispatcher 提供了 17 个便捷分发方法。`playerDidChangeControlsVisible:` 通知由 `GestureControlSlot` 通过通用的 `notifyObservers:withBlock:` 方法分发，而非专属便捷方法。

### **2.2 GestureNotificationDispatcher**

手势通知分发器，由 `GestureControlSlot` 创建并持有。在识别手势后，将手势语义信息分发给所有观察者。

**核心方法：**

| 接口 | 说明 |
|------|------|
| `addObserver:` | 添加遵循 `GestureNotificationDelegate` 的观察者 |
| `removeObserver:` | 移除指定观察者 |
| `removeAllObservers` | 移除所有观察者 |
| `notifyObservers:` | 向所有观察者分发通知 Block |
| `observerCount` | 返回当前活跃观察者数量 |

**特点**：

- 回调参数聚焦于「显示所需的数据」（如亮度/音量百分比），而非手势的原始坐标信息
- 由 `SlotHostLayout` 在插槽构建时注入到 `TopBarSlot`、`BottomBarSlot`、`CenterDisplaySlot` 等需要响应手势的插槽中

### **2.3 SlotActionNotificationDispatcher**

插槽操作通知分发器，由 `SlotHostLayout` 创建并管理。用于解耦插槽之间的直接方法调用（如 `TopBarSlot` / `BottomBarSlot` 触发 `SettingMenuSlot`）。

**核心方法：**

| 接口 | 说明 |
|------|------|
| `addObserver:` | 添加遵循 `SlotActionNotificationDelegate` 的观察者 |
| `removeObserver:` | 移除指定观察者 |
| `removeAllObservers` | 移除所有观察者 |
| `notifyObservers:` | 向所有观察者**异步**分发通知 Block |
| `observerCount` | 返回当前活跃观察者数量 |

**特点**：与其他 Dispatcher 不同，`SlotActionNotificationDispatcher` 始终通过 `dispatch_async(dispatch_get_main_queue(), ...)` 异步分发通知，避免在按钮事件处理链中同步执行重量级 UI 操作导致的 UI 卡死。

---

## **3. 使用方式**

### **3.1 通过 Controller 注册（推荐）**

`AliPlayerController` 提供便捷方法注册 `PlayerNotificationDelegate` 观察者。这是最常用的订阅方式：

```objc
@interface MyViewController () <PlayerNotificationDelegate>
@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.controller = [[AliPlayerController alloc] init];

    // 注册为通知观察者
    [self.controller addNotificationDelegate:self];

    // 配置并绑定播放器...
    [self.controller configure:model];
    [self.playerView attach:self.controller];
}

- (void)dealloc {
    // 推荐显式移除观察者
    [self.controller removeNotificationDelegate:self];
    [self.controller destroy];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // 更新播放/暂停按钮状态
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // 更新进度条
}

- (void)playerDidEncounterError:(NSError *)error {
    // 显示错误提示
}

@end
```

**Controller 注册入口：**

| 方法 | 说明 |
|------|------|
| `addNotificationDelegate:` | 添加遵循 `PlayerNotificationDelegate` 协议的观察者，以弱引用方式持有 |
| `removeNotificationDelegate:` | 移除之前添加的通知观察者 |

> **说明**：观察者通过 `NSHashTable` 以弱引用方式存储，当观察者对象被释放后会自动从列表中移除。但推荐在 `dealloc` 中显式调用 `removeNotificationDelegate:` 确保及时清理。

### **3.2 插槽内部通信（高级）**

`GestureNotificationDispatcher` 和 `SlotActionNotificationDispatcher` 属于插槽内部通信机制，由 `SlotHostLayout` 在插槽构建时通过属性注入方式提供给内置插槽。

自定义插槽如需接收手势或插槽操作通知，可声明对应的 Dispatcher 属性，由 `SlotHostLayout` 注入后使用：

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
    // 单击切换控制栏显隐
}

- (void)gestureDidUpdateVolumeWithPercent:(CGFloat)currentPercent {
    // 显示音量调节 UI
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidRequestToggleSettingMenu {
    // 响应设置菜单切换请求
}

@end
```

> **说明**：`GestureNotificationDispatcher` 由 `GestureControlSlot` 创建并持有（`readonly` 属性），`SlotActionNotificationDispatcher` 由 `SlotHostLayout` 创建并持有。插槽的 Dispatcher 属性声明为 `weak`，由 `SlotHostLayout` 在 `rebuildSlots` 后自动注入。

### **3.3 完整代码示例**

以下展示一个完整的播放页面如何订阅播放器通知：

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

    // 注册为通知观察者
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
    NSLog(@"播放状态变化: %ld", (long)state);
}

- (void)playerDidPreparedWithDuration:(NSInteger)duration {
    NSLog(@"准备完成，总时长: %ld ms", (long)duration);
}

- (void)playerDidRenderFirstFrame {
    // 隐藏封面图
}

- (void)playerDidCompletion {
    // 显示重播按钮
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // 更新进度条
}

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    // 更新全屏/非全屏布局
}

- (void)playerDidChangeControlsVisible:(BOOL)visible {
    // 同步控制栏显隐
}

- (void)playerDidEncounterError:(NSError *)error {
    NSLog(@"播放错误: %@", error.localizedDescription);
}

@end
```

> **参考**：`PlayerKitUsages/UsageNotificationSystem` 模块提供了完整的通知系统使用示例，展示了如何注册 `PlayerNotificationDelegate` 观察者并实时接收播放状态变更、进度更新等通知。

---

## **4. 通知列表**

### **4.1 PlayerNotificationDelegate（22 个 @optional 方法）**

#### **播放状态通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeState:` | 播放器状态转换时 | `state` — 新的 `PlayerState` 枚举值 |
| `playerDidPreparedWithDuration:` | 播放器准备完成 | `duration` — 媒体总时长（毫秒） |
| `playerDidRenderFirstFrame` | 首帧视频画面渲染完成 | — |
| `playerDidCompletion` | 播放到达媒体末尾 | — |

#### **播放进度通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidUpdateCurrentPosition:duration:bufferedPosition:` | 播放期间定期调用 | `position` — 当前位置（ms）；`duration` — 总时长（ms）；`bufferedPosition` — 已缓冲位置（ms） |

#### **错误通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidEncounterError:` | 播放错误发生 | `error` — `NSError` 对象 |

#### **截图通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidCompleteSnapshot:` | 截图完成时 | `image` — 截取的 `UIImage`，失败为 nil |

#### **视频尺寸通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeVideoWidth:height:` | 视频尺寸变化时 | `width`/`height` — 视频原始尺寸（像素） |

#### **全屏与控制栏通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeFullscreen:` | 全屏过渡完成后 | `isFullscreen` — 当前是否全屏 |
| `playerDidChangeControlsVisible:` | 控制栏可见性变化时 | `visible` — 控制栏是否应可见 |

> **说明**：`playerDidChangeControlsVisible:` 由 `GestureControlSlot` 单击手势或自动隐藏定时器触发。所有需要同步显隐的控制栏都应实现此方法，避免各自独立 toggle 导致状态不同步。

#### **加载通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidLoadingBegin` | 网络卡顿或缓冲不足时 | — |
| `playerDidLoadingEnd` | 缓冲数据充足可恢复播放时 | — |
| `playerDidUpdateLoadingProgress:` | 缓冲进度变化时 | `progress` — 范围 0-100（`float`） |

#### **显示模式通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeMirrorMode:` | 镜像模式变化时 | `mirrorMode` — 新的 `MirrorMode` |
| `playerDidChangeScaleMode:` | 缩放模式变化时 | `scaleMode` — 新的 `ScaleMode` |
| `playerDidChangeRotateMode:` | 旋转模式变化时 | `rotateMode` — 新的 `RotateMode` |

#### **轨道通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidTrackReady:` | 可用轨道信息就绪时 | `tracks` — `NSArray<TrackQuality *>` |
| `playerDidTrackChanged:` | 轨道切换完成时 | `quality` — 切换后的 `TrackQuality` |

#### **VID 信息就绪通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidReadyCoverUrl:` | Vid 播放 prepared 后，从 MediaInfo 中提取到封面图时 | `coverUrl` — 封面图 URL（`NSString *`） |
| `playerDidReadyVideoTitle:` | Vid 播放 prepared 后，从 MediaInfo 中提取到标题时 | `videoTitle` — 视频标题（`NSString *`） |
| `playerDidReadyThumbnailUrl:` | Vid 播放 prepared 后，从 MediaInfo 中提取到缩略图时 | `thumbnailUrl` — 缩略图 URL（`NSString *`） |

#### **缩略图通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidRetrieveThumbnail:image:` | 调用 `requestThumbnailAtPosition:` 后获取到图片时 | `positionMs` — 请求位置（`int64_t`，毫秒）；`image` — 获取到的 `UIImage` |

### **4.2 GestureNotificationDelegate（7 个 @optional 方法）**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `gestureDidSingleTap` | 单击手势触发 | — |
| `gestureDidBeginLongPress` | 长按手势开始（倍速激活） | — |
| `gestureDidEndLongPress` | 长按手势结束（倍速恢复） | — |
| `gestureDidUpdateBrightnessWithPercent:` | 左侧垂直拖动更新 | `currentPercent` — 亮度值 0.0~1.0 |
| `gestureDidEndBrightnessAdjust` | 左侧垂直拖动结束 | — |
| `gestureDidUpdateVolumeWithPercent:` | 右侧垂直拖动更新 | `currentPercent` — 音量值 0.0~1.0 |
| `gestureDidEndVolumeAdjust` | 右侧垂直拖动结束 | — |

### **4.3 SlotActionNotificationDelegate（7 个 @optional 方法）**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `slotDidRequestToggleSettingMenu` | `TopBarSlot` 设置按钮点击 | — |
| `slotDidRequestShowSpeedPanel` | `BottomBarSlot` 倍速按钮点击 | — |
| `slotDidRequestShowQualityPanel` | `BottomBarSlot` 画质按钮点击 | — |

#### **Seek 预览通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `slotDidBeginSeekPreview` | 用户开始拖动进度条时（BottomBarSlot 触发） | — |
| `slotDidUpdateSeekPreview:duration:` | 拖动期间目标位置变化时 | `targetPositionMs` — 目标位置（`int64_t`，毫秒）；`durationMs` — 媒体总时长（`int64_t`，毫秒） |
| `slotDidEndSeekPreview` | 用户松手结束拖动时（BottomBarSlot 触发） | — |

#### **章节面板通知**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `slotDidRequestShowChapterPanel` | 用户点击章节按钮时（BottomBarSlot 触发） | — |

> **说明**：`SlotActionNotificationDelegate` 的所有通知均通过 `dispatch_async(dispatch_get_main_queue(), ...)` 异步分发，确保在下一个 RunLoop 执行，避免在按钮事件处理链中同步执行导致的 UI 问题。

---

## **5. 实例级隔离机制**

### **5.1 设计原理**

在多播放器实例场景（如短视频上下滑、画中画）中，不同播放器产生的通知必须互不干扰。PlayerKit 通过**实例粒度**而非全局过滤实现通知隔离。

### **5.2 隔离方式**

每个 `AliPlayerController` 持有独立的 `PlayerNotificationDispatcher` 实例。观察者注册到某个 Controller 的 Dispatcher 后，只会接收该 Controller 产生的通知：

```text
┌── AliPlayerController (A) ──┐     ┌── AliPlayerController (B) ──┐
│  PlayerNotificationDispatcher │     │  PlayerNotificationDispatcher │
│  ├── Observer 1               │     │  ├── Observer 3               │
│  └── Observer 2               │     │  └── Observer 4               │
└───────────────────────────────┘     └───────────────────────────────┘

Observer 1/2 只收到 Controller A 的通知
Observer 3/4 只收到 Controller B 的通知
```

**关键设计**：

- 无需全局 EventBus，无需在回调中手动判断 `playerId`
- `PlayerNotificationDispatcher.playerId` 属性用于让观察者获知通知来源标识，而非用于过滤
- 注册即隔离，解除注册即断开

```objc
// Controller A 的通知只分发给注册到 A 的观察者
[controllerA addNotificationDelegate:slotA];  // slotA 只收到 A 的通知
[controllerB addNotificationDelegate:slotB];  // slotB 只收到 B 的通知
```

---

## **6. 自定义观察者开发**

### **6.1 实现 Delegate 协议**

实现所需的 Delegate 协议，只需实现关心的方法（所有方法均为 `@optional`）：

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

### **6.2 注册与注销**

```objc
// 创建观察者
MyAnalyticsObserver *observer = [[MyAnalyticsObserver alloc] init];

// 注册：通过 Controller 便捷入口
[controller addNotificationDelegate:observer];

// 注销：显式移除
[controller removeNotificationDelegate:observer];
```

> **注意**：虽然 `NSHashTable` 弱引用会在观察者释放后自动清理，但推荐显式调用 `removeNotificationDelegate:` 确保及时清理，避免在观察者释放前的短暂时间窗口内收到意外通知。

### **6.3 线程安全机制**

| 特性 | 说明 |
|------|------|
| 观察者存储 | `NSHashTable weakObjectsHashTable` 弱引用存储 |
| 列表访问 | `PlayerNotificationDispatcher` 使用 `os_unfair_lock` 保护；`GestureNotificationDispatcher`/`SlotActionNotificationDispatcher` 使用串行分派队列（`dispatch_queue_t`）保护，均线程安全 |
| 回调线程 | 通知始终在**主线程**分派（`SlotActionNotificationDispatcher` 为异步主线程） |
| 异常隔离 | 每次观察者调用通过 `@try/@catch` 包裹，单个观察者异常不影响其他观察者 |
| 重复添加 | 重复添加同一观察者不会产生效果 |
| 空操作安全 | 移除未注册的观察者不会产生任何效果 |

**分发流程：**

```text
PlayerNotificationDispatcher / GestureNotificationDispatcher：
    dispatch 方法调用
        → 串行队列内获取观察者快照（线程安全）
        → 主线程上逐个调用观察者回调
        → 每次调用 @try/@catch 包裹（异常隔离）

SlotActionNotificationDispatcher：
    notifyObservers: 调用
        → 串行队列内获取观察者快照（线程安全）
        → dispatch_async(dispatch_get_main_queue(), ...) 异步分发
        → 下一个 RunLoop 逐个调用观察者回调
        → 每次调用 @try/@catch 包裹（异常隔离）
```

---

## **7. API 速查**

### **7.1 Dispatcher 类**

| 类 | 关键方法 | 说明 |
|----|---------|------|
| `PlayerNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` / `notifyObservers:` / `notifyObservers:withBlock:` | 播放器通知分发器，含 `playerId` 属性和 selector 过滤分发 |
| `GestureNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` / `notifyObservers:` | 手势通知分发器 |
| `SlotActionNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` / `notifyObservers:` | 插槽操作通知分发器（异步分发） |

### **7.2 Delegate 协议**

| 协议 | 方法数量 | 职责范围 |
|------|---------|---------|
| `PlayerNotificationDelegate` | 22 个 `@optional` 方法 | 播放状态、进度、错误、截图、全屏、控制栏、加载、显示模式、轨道、VID 信息、缩略图 |
| `GestureNotificationDelegate` | 7 个 `@optional` 方法 | 单击、长按、亮度调节、音量调节 |
| `SlotActionNotificationDelegate` | 7 个 `@optional` 方法 | 设置菜单切换、倍速面板、画质面板、Seek 预览、章节面板 |

### **7.3 Controller 入口**

| 方法 | 说明 |
|------|------|
| `addNotificationDelegate:` | 注册 `PlayerNotificationDelegate` 观察者（弱引用） |
| `removeNotificationDelegate:` | 移除 `PlayerNotificationDelegate` 观察者 |

### **7.4 通用 Dispatcher 方法**

| 方法 | 说明 |
|------|------|
| `addObserver:` | 添加观察者（弱引用，重复添加无效果） |
| `removeObserver:` | 移除指定观察者（未注册则无效果） |
| `removeAllObservers` | 清空所有观察者 |
| `notifyObservers:` | 向所有观察者分发通知 Block |
| `observerCount` | 返回当前活跃观察者数量 |

### **7.5 PlayerNotificationDispatcher 专有方法**

| 方法 | 说明 |
|------|------|
| `notifyObservers:withBlock:` | 仅向实现了指定 selector 的观察者分发（selector 过滤） |
| `dispatchDidChangeState:` 等 17 个便捷方法 | 播放器状态、进度、错误、截图、全屏、加载、显示模式、轨道的便捷分发 |
