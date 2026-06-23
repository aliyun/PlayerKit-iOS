# **事件系统**

PlayerKit 采用 **Notification Dispatcher + Delegate 协议**模式实现组件间通信。每种 Dispatcher 管理一组弱引用观察者，通过对应的 Delegate 协议定义回调接口，实现播放器控制器、UI 插槽、策略之间的完全解耦。

---

## **1. 概念介绍**

### **1.1 什么是事件系统？**

事件系统是 PlayerKit 的通信基础设施，负责将播放器内部状态变化、手势交互、插槽操作等信息分发给所有关注方。它解决了以下问题：

| 问题 | 事件系统的解法 |
|------|--------------|
| 组件间直接依赖导致耦合度高 | 通过 Delegate 协议通信，组件间无直接引用 |
| 多播放器实例事件混乱 | 每个 Controller 持有独立的 Dispatcher 实例，天然隔离 |
| UI 与业务逻辑混杂 | 状态事件下行通知，职责分离 |
| 订阅者泄漏 | `NSHashTable` 弱引用自动管理，对象释放后自动清理 |

### **1.2 核心架构**

PlayerKit 事件系统由三大 Dispatcher 和对应的 Delegate 协议组成：

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

| Dispatcher | Delegate 协议 | 职责 |
|-----------|---------------|------|
| `PlayerNotificationDispatcher` | `PlayerNotificationDelegate` | 播放器核心事件：状态、进度、错误、截图、全屏、加载、显示模式、轨道 |
| `GestureNotificationDispatcher` | `GestureNotificationDelegate` | 手势事件：单击、长按、亮度滑动、音量滑动 |
| `SlotActionNotificationDispatcher` | `SlotActionNotificationDelegate` | 插槽操作事件：设置菜单、倍速面板、画质面板 |

---

## **2. 三大 Dispatcher**

### **2.1 PlayerNotificationDispatcher**

播放器核心事件分发器，负责将播放状态变化、进度更新、错误通知等事件分发给所有观察者。

**核心属性与方法：**

| 接口 | 说明 |
|------|------|
| `playerId` | 事件来源播放器的唯一标识符（`NSString`，可读写） |
| `addObserver:` | 添加遵循 `PlayerNotificationDelegate` 的观察者 |
| `removeObserver:` | 移除指定观察者 |
| `removeAllObservers` | 移除所有观察者 |
| `notifyObservers:` | 向所有观察者分发通知 Block |
| `notifyObservers:withBlock:` | 仅向实现了指定 selector 的观察者分发 |
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

### **2.2 GestureNotificationDispatcher**

手势事件分发器，由 `GestureControlSlot` 在识别手势后触发，将手势语义信息分发给所有观察者。

**核心方法：**

| 接口 | 说明 |
|------|------|
| `addObserver:` | 添加遵循 `GestureNotificationDelegate` 的观察者 |
| `removeObserver:` | 移除指定观察者 |
| `removeAllObservers` | 移除所有观察者 |
| `notifyObservers:` | 向所有观察者分发通知 Block |
| `observerCount` | 返回当前活跃观察者数量 |

**特点**：回调参数聚焦于「显示所需的数据」（如百分比），而非手势的原始坐标信息。

### **2.3 SlotActionNotificationDispatcher**

插槽操作事件分发器，用于解耦 Slot 之间的直接方法调用（如 TopBar/BottomBar 触发 SettingMenu）。

**核心方法：**

| 接口 | 说明 |
|------|------|
| `addObserver:` | 添加遵循 `SlotActionNotificationDelegate` 的观察者 |
| `removeObserver:` | 移除指定观察者 |
| `removeAllObservers` | 移除所有观察者 |
| `notifyObservers:` | 向所有观察者**异步**分发通知 Block |
| `observerCount` | 返回当前活跃观察者数量 |

**特点**：与其他 Dispatcher 不同，`SlotActionNotificationDispatcher` 始终通过 `dispatch_async(dispatch_get_main_queue(), ...)` 异步分发通知，避免在按钮事件处理链中同步执行重量级 UI 操作导致的卡死。

---

## **3. 使用方式**

### **3.1 通过 Controller 订阅**

推荐方式。`AliPlayerController` 提供便捷方法注册播放器事件观察者：

```objc
@interface MyViewController () <PlayerNotificationDelegate>
@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 注册为播放器事件观察者
    [self.controller addNotificationDelegate:self];
}

- (void)dealloc {
    // 移除观察者（推荐显式移除）
    [self.controller removeNotificationDelegate:self];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeState:(PlayerState)state {
    // 更新播放/暂停按钮状态
    [self updatePlayPauseButton:state];
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // 更新进度条
    [self.progressBar setProgress:(CGFloat)position / duration];
}

- (void)playerDidEncounterError:(NSError *)error {
    // 显示错误提示
    [self showErrorAlert:error.localizedDescription];
}

@end
```

**Controller 入口方法：**

| 方法 | 说明 |
|------|------|
| `addNotificationDelegate:` | 添加遵循 `PlayerNotificationDelegate` 协议的代理，以弱引用方式持有 |
| `removeNotificationDelegate:` | 移除之前添加的通知代理 |

### **3.2 直接通过 Dispatcher 订阅**

高级用法，适用于需要直接监听手势或插槽操作事件的场景：

```objc
@interface MyCustomSlot () <GestureNotificationDelegate, SlotActionNotificationDelegate>
@end

@implementation MyCustomSlot

- (void)onAttach {
    // 直接注册到手势 Dispatcher
    [self.gestureDispatcher addObserver:self];

    // 直接注册到插槽操作 Dispatcher
    [self.slotActionDispatcher addObserver:self];
}

- (void)onDetach {
    [self.gestureDispatcher removeObserver:self];
    [self.slotActionDispatcher removeObserver:self];
}

#pragma mark - GestureNotificationDelegate

- (void)gestureDidSingleTap {
    // 单击切换控制栏显隐
    [self toggleControlsVisibility];
}

- (void)gestureDidUpdateVolumeWithPercent:(CGFloat)currentPercent {
    // 显示音量调节 UI
    [self showVolumeIndicator:currentPercent];
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidRequestToggleSettingMenu {
    // 响应设置菜单切换请求
    [self toggleSettingMenu];
}

@end
```

### **3.3 完整代码示例**

以下展示一个完整的播放页面如何订阅三类事件：

```objc
@interface PlayerPageViewController ()
    <PlayerNotificationDelegate,
     GestureNotificationDelegate,
     SlotActionNotificationDelegate>

@property (nonatomic, strong) AliPlayerController *controller;
@end

@implementation PlayerPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 订阅播放器事件
    [self.controller addNotificationDelegate:self];
}

- (void)dealloc {
    [self.controller removeNotificationDelegate:self];
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
    [self.coverImageView setHidden:YES];
}

- (void)playerDidCompletion {
    // 显示重播按钮
    [self showReplayButton];
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    [self.progressBar updatePosition:position
                            duration:duration
                    bufferedPosition:bufferedPosition];
}

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    [self updateLayoutForFullscreen:isFullscreen];
}

- (void)playerDidChangeControlsVisible:(BOOL)visible {
    [self.topBar setHidden:!visible];
    [self.bottomBar setHidden:!visible];
}

#pragma mark - GestureNotificationDelegate

- (void)gestureDidSingleTap {
    [self.controller setControlsVisible:!self.controlsVisible];
}

- (void)gestureDidBeginLongPress {
    [self showSpeedIndicator:@"2x 倍速播放中"];
}

- (void)gestureDidEndLongPress {
    [self hideSpeedIndicator];
}

- (void)gestureDidUpdateBrightnessWithPercent:(CGFloat)currentPercent {
    [self showBrightnessIndicator:currentPercent];
}

- (void)gestureDidEndBrightnessAdjust {
    [self hideBrightnessIndicator];
}

#pragma mark - SlotActionNotificationDelegate

- (void)slotDidRequestToggleSettingMenu {
    [self.settingMenu toggle];
}

- (void)slotDidRequestShowSpeedPanel {
    [self.optionPanel showWithType:OptionTypeSpeed];
}

- (void)slotDidRequestShowQualityPanel {
    [self.optionPanel showWithType:OptionTypeQuality];
}

@end
```

---

## **4. 事件列表**

### **4.1 播放状态事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeState:` | 播放器状态转换时 | `state` — 新的 `PlayerState` 枚举值 |
| `playerDidPreparedWithDuration:` | 播放器准备完成 | `duration` — 媒体总时长（毫秒） |
| `playerDidRenderFirstFrame` | 首帧视频画面渲染完成 | — |
| `playerDidCompletion` | 播放到达媒体末尾 | — |

### **4.2 播放进度事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidUpdateCurrentPosition:duration:bufferedPosition:` | 播放期间定期调用 | `position` — 当前位置（ms）；`duration` — 总时长（ms）；`bufferedPosition` — 已缓冲位置（ms） |

### **4.3 错误与加载事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidEncounterError:` | 播放错误发生 | `error` — `NSError` 对象 |
| `playerDidLoadingBegin` | 网络卡顿或缓冲不足时 | — |
| `playerDidLoadingEnd` | 缓冲数据充足可恢复播放时 | — |
| `playerDidUpdateLoadingProgress:` | 缓冲进度变化时 | `progress` — 范围 0-100 |

### **4.4 UI 状态事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeFullscreen:` | 全屏过渡完成后 | `isFullscreen` — 当前是否全屏 |
| `playerDidChangeControlsVisible:` | 控制栏可见性变化时 | `visible` — 控制栏是否应可见 |
| `playerDidCompleteSnapshot:` | 截图完成时 | `image` — 截取的 `UIImage`，失败为 nil |
| `playerDidChangeVideoWidth:height:` | 视频尺寸变化时 | `width`/`height` — 视频原始尺寸（像素） |

### **4.5 显示模式事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidChangeMirrorMode:` | 镜像模式变化时 | `mirrorMode` — 新的 `MirrorMode` |
| `playerDidChangeScaleMode:` | 缩放模式变化时 | `scaleMode` — 新的 `ScaleMode` |
| `playerDidChangeRotateMode:` | 旋转模式变化时 | `rotateMode` — 新的 `RotateMode` |

### **4.6 轨道事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `playerDidTrackReady:` | 可用轨道信息就绪时 | `tracks` — `NSArray<TrackQuality *>` |
| `playerDidTrackChanged:` | 轨道切换完成时 | `quality` — 切换后的 `TrackQuality` |

### **4.7 手势事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `gestureDidSingleTap` | 单击手势触发 | — |
| `gestureDidBeginLongPress` | 长按手势开始（倍速激活） | — |
| `gestureDidEndLongPress` | 长按手势结束（倍速恢复） | — |
| `gestureDidUpdateBrightnessWithPercent:` | 左侧垂直拖动更新 | `currentPercent` — 亮度值 0.0~1.0 |
| `gestureDidEndBrightnessAdjust` | 左侧垂直拖动结束 | — |
| `gestureDidUpdateVolumeWithPercent:` | 右侧垂直拖动更新 | `currentPercent` — 音量值 0.0~1.0 |
| `gestureDidEndVolumeAdjust` | 右侧垂直拖动结束 | — |

### **4.8 插槽操作事件**

| 方法 | 触发时机 | 参数说明 |
|------|---------|---------|
| `slotDidRequestToggleSettingMenu` | TopBar 设置按钮点击 | — |
| `slotDidRequestShowSpeedPanel` | BottomBar 倍速按钮点击 | — |
| `slotDidRequestShowQualityPanel` | BottomBar 画质按钮点击 | — |

---

## **5. playerId 隔离机制**

### **5.1 设计原理**

在多播放器实例场景（如短视频上下滑、画中画）中，不同播放器产生的事件必须互不干扰。PlayerKit 通过**实例粒度**而非全局过滤实现事件隔离。

### **5.2 隔离方式**

每个 `AliPlayerController` 持有独立的 `PlayerNotificationDispatcher` 实例。观察者注册到某个 Controller 的 Dispatcher 后，只会接收该 Controller 产生的事件：

```text
┌── AliPlayerController (A) ──┐     ┌── AliPlayerController (B) ──┐
│  PlayerNotificationDispatcher │     │  PlayerNotificationDispatcher │
│  ├── Observer 1               │     │  ├── Observer 3               │
│  └── Observer 2               │     │  └── Observer 4               │
└───────────────────────────────┘     └───────────────────────────────┘

Observer 1/2 只收到 Controller A 的事件
Observer 3/4 只收到 Controller B 的事件
```

**关键设计**：

- 无需全局 EventBus，无需在回调中手动判断 `playerId`
- `PlayerNotificationDispatcher.playerId` 属性用于让观察者获知事件来源标识，而非用于过滤
- 注册即隔离，解除注册即断开

```objc
// Controller A 的事件只分发给注册到 A 的观察者
[controllerA addNotificationDelegate:slotA];  // slotA 只收到 A 的事件
[controllerB addNotificationDelegate:slotB];  // slotB 只收到 B 的事件
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

// 其他方法不实现则不会收到对应回调

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

**注意**：观察者通过 `NSHashTable` 以弱引用方式存储，当观察者对象被释放后会自动从列表中移除。但推荐显式调用 `removeNotificationDelegate:` 确保及时清理。

### **6.3 线程安全说明**

| 特性 | 说明 |
|------|------|
| 观察者存储 | `NSHashTable weakObjectsHashTable` 弱引用存储 |
| 列表访问 | 串行分派队列（`dispatch_queue_t`）保护，线程安全 |
| 回调线程 | 通知始终在**主线程**分派 |
| 异常隔离 | 每次观察者调用用 `@try/@catch` 包裹，单个观察者异常不影响其他 |
| 重复添加 | 重复添加同一观察者不会产生效果 |
| 空操作安全 | 移除未注册的观察者不会产生任何效果 |

**分发流程：**

```text
dispatch 方法调用
    → 串行队列内获取观察者快照（线程安全）
    → 主线程上逐个调用观察者回调
    → 每次调用 @try/@catch 包裹（异常隔离）
```

---

## **7. API 速查**

### **7.1 Dispatcher 类**

| 类 | 关键方法 | 说明 |
|----|---------|------|
| `PlayerNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` | 播放器事件分发器，含 `playerId` 属性 |
| `GestureNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` | 手势事件分发器 |
| `SlotActionNotificationDispatcher` | `addObserver:` / `removeObserver:` / `removeAllObservers` | 插槽操作事件分发器（异步分发） |

### **7.2 Delegate 协议**

| 协议 | 方法数量 | 职责范围 |
|------|---------|---------|
| `PlayerNotificationDelegate` | 20 个 `@optional` 方法 | 播放状态、进度、错误、截图、全屏、控制栏、加载、显示模式、轨道 |
| `GestureNotificationDelegate` | 7 个 `@optional` 方法 | 单击、长按、亮度调节、音量调节 |
| `SlotActionNotificationDelegate` | 3 个 `@optional` 方法 | 设置菜单切换、倍速面板、画质面板 |

### **7.3 Controller 入口**

| 方法 | 说明 |
|------|------|
| `- (void)addNotificationDelegate:(id<PlayerNotificationDelegate>)delegate` | 注册播放器事件观察者（弱引用） |
| `- (void)removeNotificationDelegate:(id<PlayerNotificationDelegate>)delegate` | 移除播放器事件观察者 |

### **7.4 通用 Dispatcher 方法**

| 方法 | 说明 |
|------|------|
| `addObserver:` | 添加观察者（弱引用，重复添加无效果） |
| `removeObserver:` | 移除指定观察者（未注册则无效果） |
| `removeAllObservers` | 清空所有观察者 |
| `notifyObservers:` | 向所有观察者分发通知 Block |
| `observerCount` | 返回当前活跃观察者数量 |

---

## **8. 下一步**

- 了解插槽如何响应事件更新 UI：[插槽系统](./SlotSystem.md)
- 了解策略如何利用事件执行业务逻辑：[策略系统](./StrategySystem.md)
- 查看完整 API 参考：[API 文档](../ApiReference.md)
