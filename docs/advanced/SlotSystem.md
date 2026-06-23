# **插槽系统 (Slot System)**

**插槽系统 (Slot System)** 是 AliPlayerKit 的核心架构设计。它通过组件化与可插拔机制，将播放器 UI 拆分为多个独立的插槽组件，并由统一的系统进行管理与调度，从而实现播放器界面的解耦、组合与灵活扩展。

---

## **1. 概念介绍**

### **1.1 什么是插槽？**

**插槽 (Slot)** 是播放器 UI 的基本组成单元，每个插槽代表一个独立的界面组件，负责播放器界面中的某一部分功能，例如顶部控制栏、底部进度条、封面图或提示信息等。

所有插槽按照预定义的 **Z-Order 层级** 进行叠加排列，共同构成完整的播放器界面。每个插槽只关注自身的 UI 展示与交互逻辑，从而实现职责清晰、粒度可控的界面结构。

### **1.2 什么是插槽系统？**

**插槽系统 (Slot System)** 是用于统一管理这些插槽组件的架构机制。

它负责定义插槽的 **注册机制、生命周期管理、场景适配以及渲染顺序**，并在播放器运行过程中统一管理插槽的创建、展示、隐藏与销毁。

基于这一机制，开发者可以像搭积木一样灵活构建播放器界面：既可以使用系统提供的默认插槽快速搭建播放器 UI，也可以按需替换或扩展特定插槽，甚至完全自定义所有组件，实现高度定制化的播放器界面。

### **1.3 核心价值**

| 使用方式 | 说明 | 优势 |
|---------|------|------|
| 使用默认界面 | 零配置，开箱即用 | 简化接入流程，低代码接入 |
| 自定义部分插槽 | 只替换需要定制的插槽，其他保持默认 | 局部定制，保留默认交互 |
| 完全自定义界面 | 替换所有插槽实现 | 满足品牌专属 UI 需求 |
| 不使用插槽 | 仅使用播放能力，无 UI 依赖 | 纯播放场景 |

**架构优势**：

- **解耦**：UI 组件与播放器核心逻辑分离，职责清晰
- **灵活**：运行时动态组合、替换 UI 组件
- **可扩展**：无需修改框架即可自定义 UI
- **关注点分离**：UI 样式与业务逻辑分离

---

## **2. 功能特性**

### **2.1 核心能力**

| 能力 | 说明 |
|-----|------|
| 动态组合 | 运行时自由组合 UI 组件 |
| 热替换 | 无需重启即可替换组件实现 |
| 场景适配 | 不同播放场景自动切换 UI 行为 |
| 双生命周期 | View 生命周期与 Data 生命周期独立管理 |

### **2.2 内置插槽类型**

AliPlayerKit 内置 11 种插槽类型，按 Z-Order 从底到顶排列：

| 插槽类型 | 枚举值 | 说明 | 默认实现 |
|---------|--------|------|---------|
| 视频画面 | `SlotTypePlayerSurface` | 显示播放器视频内容（最底层） | `PlayerSurfaceSlot` |
| 全屏管理 | `SlotTypeFullscreen` | 无头插槽，管理全屏切换逻辑 | `FullscreenSlot` |
| 手势控制 | `SlotTypeGestureControl` | 处理单击/双击/长按/拖动 | `GestureControlSlot` |
| 横屏提示 | `SlotTypeLandscapeHint` | 横屏视频在竖屏时提示全屏观看 | `LandscapeHintSlot` |
| 封面图 | `SlotTypeCover` | 播放前显示视频封面 | `CoverSlot` |
| 中心显示 | `SlotTypeCenterDisplay` | 显示倍速/亮度/音量等状态提示 | `CenterDisplaySlot` |
| 播放状态 | `SlotTypePlayState` | 显示加载中/错误/播放完成等 | `PlayStateSlot` |
| 日志面板 | `SlotTypeLogPanel` | 调试时显示播放器日志 | `LogPanelSlot` |
| 顶部控制栏 | `SlotTypeTopBar` | 返回按钮/标题/设置按钮 | `TopBarSlot` |
| 底部控制栏 | `SlotTypeBottomBar` | 播放暂停/进度条/全屏按钮 | `BottomBarSlot` |
| 设置菜单 | `SlotTypeSettingMenu` | 倍速/清晰度/镜像/旋转（最顶层） | `SettingMenuSlot` |

### **2.3 Z-Order 层级示意**

```text
┌────────────────────────────────────────┐  ← 最顶层
│         SettingMenu (设置菜单)           │  Z=10
├────────────────────────────────────────┤
│         BottomBar (底部控制栏)           │  Z=9
├────────────────────────────────────────┤
│         TopBar (顶部控制栏)             │  Z=8
├────────────────────────────────────────┤
│         LogPanel (日志面板)             │  Z=7
├────────────────────────────────────────┤
│         PlayState (播放状态)            │  Z=6
├────────────────────────────────────────┤
│         CenterDisplay (中心显示)        │  Z=5
├────────────────────────────────────────┤
│         Cover (封面图)                  │  Z=4
├────────────────────────────────────────┤
│         LandscapeHint (横屏提示)        │  Z=3
├────────────────────────────────────────┤
│         GestureControl (手势控制)       │  Z=2
├────────────────────────────────────────┤
│         Fullscreen (全屏管理，无头)      │  Z=1
├────────────────────────────────────────┤
│         PlayerSurface (视频画面)         │  Z=0
└────────────────────────────────────────┘  ← 最底层
```

### **2.4 场景适配**

AliPlayerKit 定义了 5 种播放场景，不同场景下插槽行为自动适配：

| 场景 | 枚举值 | 说明 | 典型应用 |
|-----|--------|------|---------|
| VOD | `SceneTypeVOD` | 点播场景，支持所有功能 | 常规视频播放 |
| LIVE | `SceneTypeLive` | 直播场景，禁用时间轴操作 | 实时直播流 |
| VIDEO_LIST | `SceneTypeVideoList` | 列表播放场景，禁用垂直手势 | 信息流、短视频列表 |
| RESTRICTED | `SceneTypeRestricted` | 受限播放场景，限制跳跃播放 | 教育培训、考试监控 |
| MINIMAL | `SceneTypeMinimal` | 最小化播放场景，仅显示视频画面 | 背景视频、装饰视频 |

**插槽可见性规则**：

| 插槽 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|---------|
| PlayerSurface | ✓ | ✓ | ✓ | ✓ | ✓ |
| Fullscreen | ✓ | ✓ | ✓ | ✓ | ✓ |
| GestureControl | ✓ | ✓ | ✓ | ✓ | ✗ |
| LandscapeHint | ✓ | ✓ | ✓ | ✓ | ✗ |
| Cover | ✓ | ✗ | ✓ | ✗ | ✗ |
| CenterDisplay | ✓ | ✓ | ✓ | ✓ | ✗ |
| PlayState | ✓ | ✓ | ✓ | ✓ | ✓ |
| LogPanel | 可配置 | 可配置 | 可配置 | 可配置 | ✗ |
| TopBar | ✓ | ✓ | ✓ | ✓ | ✗ |
| BottomBar | ✓ | ✓ | ✓ | ✓ | ✗ |
| SettingMenu | ✓ | ✓ | ✓ | ✓ | ✗ |

**手势行为差异**：

| 手势 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|---------|
| 单击 | 显示/隐藏控制栏 | 显示/隐藏控制栏 | 显示/隐藏控制栏 | 显示/隐藏控制栏 | 禁用 |
| 双击 | 切换播放/暂停 | 切换播放/暂停 | 切换播放/暂停 | 切换播放/暂停 | 禁用 |
| 长按 | 2倍速播放 | 禁用 | 2倍速播放 | 禁用 | 禁用 |
| 水平拖动 | 进度跳转 | 禁用 | 进度跳转 | 禁用 | 禁用 |
| 左侧垂直拖动 | 亮度调节 | 亮度调节 | 禁用 | 亮度调节 | 禁用 |
| 右侧垂直拖动 | 音量调节 | 音量调节 | 禁用 | 音量调节 | 禁用 |

---

## **3. 使用方式**

### **3.1 策略一：使用默认界面**

最简单的使用方式，零配置开箱即用：

```objc
@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. 创建播放器视图
    AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:playerView];

    // 2. 创建控制器
    AliPlayerController *controller = [[AliPlayerController alloc] init];

    // 3. 创建数据模型
    AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:videoSource];
    model.sceneType = SceneTypeVOD;
    model.autoPlay = YES;

    // 4. 配置并绑定（自动使用默认插槽）
    [controller configure:model];
    [playerView attach:controller];
}

@end
```

### **3.2 策略二：自定义部分插槽**

只替换需要定制的插槽，其他使用默认实现：

```objc
// 1. 获取播放器视图的 SlotManager
SlotManager *slotManager = playerView.slotManager;

// 2. 只注册需要自定义的插槽（其他保持默认）
[slotManager registerSlotType:SlotTypeTopBar provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomTopBarSlot alloc] initWithFrame:parentView.bounds];
}];

// 3. 配置并绑定
[controller configure:model];
[playerView attach:controller];
```

### **3.3 策略三：完全自定义界面**

清除所有默认实现，逐一注册自定义插槽：

```objc
// 1. 获取 SlotManager 并清除默认配置
SlotManager *slotManager = playerView.slotManager;
[slotManager clearAll];

// 2. 注册所有需要的自定义插槽
[slotManager registerSlotType:SlotTypePlayerSurface provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MySurfaceSlot alloc] initWithFrame:parentView.bounds];
}];
[slotManager registerSlotType:SlotTypeCover provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCoverSlot alloc] initWithFrame:parentView.bounds];
}];
// ... 其他插槽

// 3. 绑定
[controller configure:model];
[playerView attach:controller];
```

### **3.4 插槽可见性控制**

不替换插槽实现，仅控制显示/隐藏：

```objc
// 隐藏指定类型插槽
[slotManager hideSlot:SlotTypeLogPanel];
```

---

## **4. 自定义开发**

### **4.1 插槽协议 (SlotProtocol)**

所有插槽必须遵循 `SlotProtocol`，该协议定义了插槽的最小生命周期契约：

```objc
@protocol SlotProtocol <NSObject>

@required

#pragma mark - View 生命周期

/// 插槽被附加到宿主时调用
- (void)onAttach:(id<SlotHost>)host;

/// 插槽从宿主分离时调用
- (void)onDetach;

#pragma mark - Data 生命周期

/// 数据绑定回调
- (void)onBindData:(AliPlayerModel *)model;

/// 数据解绑回调
- (void)onUnbindData;

@end
```

### **4.2 双生命周期**

插槽采用独立的 View 生命周期和 Data 生命周期：

| 生命周期 | 回调方法 | 时机 | 职责 |
|---------|---------|------|------|
| **View 开始** | `onAttach:` | `playerView.attach` 触发 | 建立宿主连接、订阅通知、初始化视图 |
| **Data 开始** | `onBindData:` | `controller.configure:` 设置播放数据后 | 绑定业务数据（封面图、标题等） |
| **Data 结束** | `onUnbindData` | 播放数据被清除或更新前 | 清理数据相关资源 |
| **View 结束** | `onDetach` | `playerView.detach` 或插槽被移除时 | 释放所有资源，断开所有连接 |

```text
┌─────────────────── 完整生命周期 ───────────────────┐
│                                                      │
│   ① onAttach:         ─── View 生命周期开始           │
│       ↓ 可访问 host、订阅通知、初始化子视图            │
│                                                      │
│   ② onBindData:       ─── Data 生命周期开始           │
│       ↓ 加载封面图、设置标题、配置场景行为             │
│                                                      │
│   ③ onUnbindData      ─── Data 生命周期结束           │
│       ↓ 清除图片缓存、重置 UI 状态                    │
│                                                      │
│   ④ onDetach          ─── View 生命周期结束           │
│       ↓ 取消通知订阅、移除定时器、释放所有资源         │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### **4.3 继承 BaseSlot（推荐）**

`BaseSlot` 是所有 UI 插槽的推荐基类，封装了生命周期管理、通知订阅、场景适配等通用逻辑。

```objc
@interface BaseSlot : UIView <SlotProtocol>

/// 当前绑定的宿主（onAttach: 后可用，弱引用）
@property (nonatomic, weak, readonly, nullable) id<SlotHost> host;

/// 子类设置内容视图的钩子方法（onAttach: 时调用）
- (void)setupContentView;

/// 显示/隐藏/移除插槽
- (void)show;
- (void)hide;
- (void)dismiss;
- (BOOL)isShowing;

/// 遵循 PlayerNotificationDelegate 协议，
/// 在 onAttach: 时自动注册为控制器通知代理，
/// 子类直接实现感兴趣的回调方法即可接收播放器事件。

@end
```

### **4.4 自定义插槽完整示例**

**Step 1**：创建自定义插槽类，继承 `BaseSlot`：

```objc
@interface MyCustomCoverSlot : BaseSlot

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation MyCustomCoverSlot

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    _coverImageView = [[UIImageView alloc] init];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImageView.clipsToBounds = YES;
    [self addSubview:_coverImageView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self addSubview:_titleLabel];
}

#pragma mark - 生命周期

- (void)onAttach:(id<SlotHost>)host {
    [super onAttach:host];
    // 初始化（此时可访问 host）
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
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self hide];
        self.alpha = 1;
    }];
}

- (void)playerDidChangeState:(PlayerState)state {
    if (state == PlayerStateError) {
        [self show];
    }
}

#pragma mark - 场景适配

- (BOOL)shouldShowInScene:(SceneType)sceneType {
    return sceneType == SceneTypeVOD ||
           sceneType == SceneTypeVideoList;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _coverImageView.frame = self.bounds;
    _titleLabel.frame = CGRectMake(16, self.bounds.size.height - 50,
                                   self.bounds.size.width - 32, 30);
}

@end
```

**Step 2**：注册并使用：

```objc
SlotManager *slotManager = playerView.slotManager;
[slotManager registerSlotType:SlotTypeCover provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomCoverSlot alloc] initWithFrame:parentView.bounds];
}];
[controller configure:model];
[playerView attach:controller];
```

### **4.5 无头插槽**

无头插槽只处理业务逻辑、不渲染 UI。`slotView` 方法返回一个零尺寸的空视图：

```objc
@implementation MyHeadlessSlot

- (UIView *)slotView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.userInteractionEnabled = NO;
    return emptyView;
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidChangeFullscreen:(BOOL)isFullscreen {
    [self toggleFullscreen];
}

@end
```

### **4.6 在插槽中发送命令**

插槽通过 `host.controller` 向控制器发送命令，实现单向数据流：

```objc
// 播放/暂停切换
- (void)onPlayPauseButtonTapped {
    AliPlayerController *controller = self.host.controller;
    if (controller.isPlaying) {
        [controller pause];
    } else {
        [controller play];
    }
}

// 进度跳转
- (void)onSeekBarValueChanged:(UISlider *)slider {
    AliPlayerController *controller = self.host.controller;
    long position = (long)(slider.value * self.host.playerStateStore.duration);
    [controller seekTo:position];
}
```

### **4.7 插槽注册表**

`SlotManager` 管理插槽类型到 Provider 的映射关系：

```objc
// 注册插槽 Provider
[slotManager registerSlotType:SlotTypeTopBar provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomSlot alloc] initWithFrame:parentView.bounds];
}];

// 注销指定类型
[slotManager unregisterSlotType:SlotTypeLogPanel];

// 检查是否已注册
BOOL registered = [slotManager isRegistered:SlotTypeTopBar];
```

**槽位选择优先级**：自定义实现 > 默认实现 > 跳过（不创建）

---

## **5. API 速查**

### **5.1 核心协议与类**

| 类/协议 | 说明 | 详见 |
|--------|------|------|
| `SlotProtocol` | 插槽协议，定义最小生命周期契约 | [ApiReference.md](../ApiReference.md) |
| `BaseSlot` | 插槽基类，封装通用逻辑 | [ApiReference.md](../ApiReference.md) |
| `SlotManager` | 插槽注册表，管理类型→构建器映射 | [ApiReference.md](../ApiReference.md) |
| `SlotHost` | 宿主协议，提供上下文能力 | [ApiReference.md](../ApiReference.md) |
| `SlotType` | 插槽类型枚举 | [ApiReference.md](../ApiReference.md) |

### **5.2 SlotProtocol 方法**

| 方法 | 说明 |
|-----|------|
| `onAttach:` | View 生命周期开始，初始化视图和通知订阅 |
| `onDetach` | View 生命周期结束，释放所有资源 |
| `onBindData:` | Data 生命周期开始，绑定业务数据 |
| `onUnbindData` | Data 生命周期结束，清理数据资源 |

### **5.3 BaseSlot 方法**

| 方法 | 说明 |
|-----|------|
| `setupContentView` | 子类重写以创建自定义 UI 元素 |
| `show` / `hide` / `dismiss` | 可见性控制 |
| `isShowing` | 查询当前可见状态 |
| `currentSceneType` | 安全读取当前场景类型 |
| `onRegisterElements` | 声明支持的元素及其默认可见性 |
| `isElementVisible:` | 查询指定元素的最终可见性 |

### **5.4 SlotManager 方法**

| 方法 | 说明 |
|-----|------|
| `registerSlotType:provider:` | 注册插槽类型的 Provider |
| `unregisterSlotType:` | 注销指定类型的插槽 |
| `isRegistered:` | 检查指定类型是否已注册 |
| `hideSlot:` / `showSlot:` | 插槽级可见性控制 |
| `hideElements:forSlot:` | 隐藏插槽内的特定元素 |
| `showElements:forSlot:` | 显示插槽内的特定元素 |
| `slotViewForType:` | 获取已挂载的插槽视图 |
| `rebuildSlots` | 重建所有插槽 |

### **5.5 SlotHost 方法**

| 方法 | 说明 |
|-----|------|
| `hostView` | 返回宿主容器视图 |
| `model` | 获取当前播放器模型 |
| `controller` | 获取播放器控制器 |
| `playerStateStore` | 获取播放器状态存储（只读） |
| `viewState` | 获取视图层级状态 |
| `setRenderView:` | 为播放器设置渲染视图 |
| `slotViewForType:` | 根据类型获取已挂载插槽视图 |
| `slotManager` | 获取插槽管理器 |
| `sceneType` | 获取当前场景类型 |

--

## **6. 技术原理**

### **6.1 槽位选择策略**

```text
请求创建插槽 → 自定义注册表中有该类型？
                  ├── 是 → 使用自定义实现
                  └── 否 → 默认注册表中有该类型？
                              ├── 是 → 使用默认实现
                              └── 否 → 跳过（不创建）
```

### **6.2 单向数据流**

插槽系统采用单向数据流架构，插槽不直接持有控制器引用：

```text
Controller → State / Event → Slot（状态下行，只读）
Slot → Command → Controller（命令上行，只发）
```

- **状态下行**：通过 `host.playerStateStore` 主动查询，或通过 `PlayerNotificationDelegate` 回调被动接收
- **命令上行**：通过 `host.controller` 调用播放命令，由控制器执行

### **6.3 插槽间隔离**

插槽之间严禁直接获取对方实例或进行点对点通信。当一个插槽需要影响另一个插槽时：

1. 发起插槽通过 `host.controller` 发送状态变更
2. Controller 通过 `PlayerNotificationDelegate` 通知所有关注此变化的插槽

通过这种"事件上浮，状态下沉"的链路，避免了网状的 UI 耦合。

### **6.4 底部控制栏场景差异**

| 控件 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|--------|
| 播放/暂停按钮 | ✓ | ✓ | ✓ | ✓ | ✗ |
| 进度条 | 可拖拽 | 不可拖拽 | 可拖拽 | 不可拖拽 | ✗ |
| 时间显示 | ✓ | ✓ | ✓ | ✓ | ✗ |
| 刷新按钮 | ✗ | ✓ | ✗ | ✗ | ✗ |
| 全屏按钮 | ✓ | ✓ | ✓ | ✓ | ✗ |

---

## **7. 下一步**

- 了解插槽间的通信机制：[事件系统](./EventSystem.md)
- 了解如何添加自定义业务逻辑：[策略系统](./StrategySystem.md)
- 查看完整 API 参考：[API 文档](../ApiReference.md)
