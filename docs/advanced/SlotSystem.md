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
| 视频画面 | `SlotTypePlayerSurface` (10) | 显示播放器视频内容（最底层） | `PlayerSurfaceSlot` |
| 手势控制 | `SlotTypeGestureControl` (20) | 处理单击/双击/长按/拖动 | `GestureControlSlot` |
| 横屏提示 | `SlotTypeLandscapeHint` (30) | 横屏视频在竖屏时提示全屏观看 | `LandscapeHintSlot` |
| 封面图 | `SlotTypeCover` (40) | 播放前显示视频封面 | `CoverSlot` |
| 中心显示 | `SlotTypeCenterDisplay` (50) | 显示倍速/亮度/音量等状态提示 | `CenterDisplaySlot` |
| 播放状态 | `SlotTypePlayState` (60) | 显示加载中/错误/播放完成等 | `PlayStateSlot` |
| 日志面板 | `SlotTypeLogPanel` (70) | 调试时显示播放器日志 | `LogPanelSlot` |
| 顶部控制栏 | `SlotTypeTopBar` (80) | 返回按钮/标题/设置按钮 | `TopBarSlot` |
| 底部控制栏 | `SlotTypeBottomBar` (90) | 播放暂停/进度条/全屏按钮 | `BottomBarSlot` |
| 设置菜单 | `SlotTypeSettingMenu` (100) | 倍速/清晰度/镜像/旋转 | `SettingMenuSlot` |
| 选项面板 | `SlotTypeOptionPanel` (110) | 倍速/清晰度选项弹出面板（最顶层） | `OptionPanelSlot` |

> **说明**：枚举值间隔为 10，以便后续插入新类型时不影响现有排序。枚举值同时决定了插槽的 Z 轴顺序（值越小越靠下）。通过 `SlotTypeName()` 函数可获取插槽类型的可读名称，`SlotTypeAllBuiltinTypes()` 函数可获取所有内置类型的有序数组。

### **2.3 Z-Order 层级示意**

```text
┌────────────────────────────────────────┐  ← 最顶层
│       OptionPanel (选项面板)            │  Z=110
├────────────────────────────────────────┤
│       SettingMenu (设置菜单)            │  Z=100
├────────────────────────────────────────┤
│       BottomBar (底部控制栏)            │  Z=90
├────────────────────────────────────────┤
│       TopBar (顶部控制栏)              │  Z=80
├────────────────────────────────────────┤
│       LogPanel (日志面板)              │  Z=70
├────────────────────────────────────────┤
│       PlayState (播放状态)             │  Z=60
├────────────────────────────────────────┤
│       CenterDisplay (中心显示)         │  Z=50
├────────────────────────────────────────┤
│       Cover (封面图)                   │  Z=40
├────────────────────────────────────────┤
│       LandscapeHint (横屏提示)         │  Z=30
├────────────────────────────────────────┤
│       GestureControl (手势控制)        │  Z=20
├────────────────────────────────────────┤
│       PlayerSurface (视频画面)          │  Z=10
└────────────────────────────────────────┘  ← 最底层
```

### **2.4 场景适配**

AliPlayerKit 定义了 5 种播放场景，不同场景下插槽的可见性和行为自动适配。场景适配通过 `SlotConfig` 实现，`DefaultSlotFactory` 预置了所有内置插槽的默认配置。

| 场景 | 枚举值 | 说明 | 典型应用 |
|-----|--------|------|---------|
| VOD | `SceneTypeVOD` | 点播场景，支持所有功能 | 常规视频播放 |
| LIVE | `SceneTypeLive` | 直播场景，禁用时间轴操作 | 实时直播流 |
| VIDEO_LIST | `SceneTypeVideoList` | 列表播放场景，禁用垂直手势 | 信息流、短视频列表 |
| RESTRICTED | `SceneTypeRestricted` | 受限播放场景，限制跳跃播放 | 教育培训、考试监控 |
| MINIMAL | `SceneTypeMinimal` | 最小化播放场景，仅显示视频画面 | 背景视频、装饰视频 |

**插槽可见性规则**（由 `DefaultSlotFactory.defaultConfigs` 定义）：

| 插槽 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|---------|
| PlayerSurface | ✓ | ✓ | ✓ | ✓ | ✓ |
| GestureControl | ✓ | ✓ | ✓ | ✓ | ✗ |
| LandscapeHint | ✓ | ✓ | ✓ | ✓ | ✗ |
| Cover | ✓ | ✗ | ✓ | ✗ | ✗ |
| CenterDisplay | ✓ | ✓ | ✓ | ✓ | ✗ |
| PlayState | ✓ | ✓ | ✓ | ✓ | ✓ |
| LogPanel | 可配置 | 可配置 | 可配置 | 可配置 | ✗ |
| TopBar | ✓ | ✓ | ✓ | ✓ | ✗ |
| BottomBar | ✓ | ✓ | ✓ | ✓ | ✗ |
| SettingMenu | ✓ | ✓ | ✓ | ✓ | ✗ |
| OptionPanel | ✓ | ✓ | ✓ | ✓ | ✗ |

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

清除所有默认配置，逐一注册自定义插槽：

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
SlotManager *slotManager = playerView.slotManager;

// 隐藏整个插槽（rebuildSlots 时不构建）
[slotManager hideSlot:SlotTypeLogPanel];

// 显示之前隐藏的插槽（需调用 rebuildSlots 生效）
[slotManager showSlot:SlotTypeLogPanel];
[slotManager rebuildSlots];

// 检查插槽是否被隐藏
BOOL hidden = [slotManager isSlotHidden:SlotTypeLogPanel];
```

### **3.5 元素级可见性控制**

插槽系统支持对插槽内部的单个 UI 元素进行细粒度可见性控制，通过位掩码（`SlotElements.h`）实现：

```objc
SlotManager *slotManager = playerView.slotManager;

// 隐藏顶部栏中的下载按钮和截图按钮
[slotManager hideElements:(TopBarElementDownload | TopBarElementSnapshot)
                  forSlot:SlotTypeTopBar];

// 隐藏底部栏中的刷新按钮
[slotManager hideElements:BottomBarElementRefresh
                  forSlot:SlotTypeBottomBar];

// 禁用水平拖动手势（对 GestureControl 插槽，隐藏元素表示禁用对应手势）
[slotManager hideElements:GestureElementHorizontalDrag
                  forSlot:SlotTypeGestureControl];

// 显示之前隐藏的元素
[slotManager showElements:TopBarElementDownload
                  forSlot:SlotTypeTopBar];

// 批量设置所有插槽的隐藏元素（替换式）
[slotManager setAllHiddenElementMasks:@{
    @(SlotTypeTopBar): @(TopBarElementDownload | TopBarElementSnapshot),
    @(SlotTypeBottomBar): @(BottomBarElementRefresh),
}];

// 清空所有元素可见性配置
[slotManager clearAllElementMasks];
```

**元素位掩码类型**：

| 插槽类型 | 元素类型 | 可控元素 |
|---------|---------|---------|
| TopBar | `TopBarElement` | Back / Title / Download / Snapshot / Settings |
| BottomBar | `BottomBarElement` | Play / Progress / Refresh / Speed |
| SettingMenu | `SettingMenuElement` | Speed / TrackInfo / Loop / Mute / MirrorMode / RotateMode / ScaleMode / Subtitle |
| CenterDisplay | `CenterDisplayElement` | Volume / Brightness / Speed |
| GestureControl | `GestureElement` | SingleTap / DoubleTap / LongPress / HorizontalDrag / LeftVerticalDrag / RightVerticalDrag |
| PlayState | `PlayStateElement` | ErrorMessage / LoadingMessage |

> **说明**：各插槽子类通过 `onRegisterElements` 声明默认可见的元素组合。外部可通过 `hideElements:forSlot:` 覆盖默认可见的元素，或通过 `showElements:forSlot:` 覆盖默认隐藏的元素。最终可见性通过 `isElementVisible:` 查询。

### **3.6 场景可见性配置**

通过 `SlotConfig` 控制插槽在不同场景下的可见性：

```objc
SlotManager *slotManager = playerView.slotManager;

// 配置封面图插槽在 Live 和 Restricted 场景下不可见
SlotConfig *coverConfig = [SlotConfig configWithSlotType:SlotTypeCover
                                         excludedScenes:[NSSet setWithObjects:@(SceneTypeLive), @(SceneTypeRestricted), nil]];
[slotManager registerSlotConfig:coverConfig];

// 使用 visibilityCondition 进行动态可见性控制
SlotConfig *logConfig = [SlotConfig configWithSlotType:SlotTypeLogPanel
                                       excludedScenes:[NSSet setWithObject:@(SceneTypeMinimal)]
                                  visibilityCondition:^BOOL{
    return [AliPlayerKit isDebugModeEnabled];
}];
[slotManager registerSlotConfig:logConfig];

// 移除场景可见性配置（该插槽在所有场景下均可见）
[slotManager unregisterSlotConfigForType:SlotTypeCover];

// 查询配置
SlotConfig *config = [slotManager slotConfigForType:SlotTypeCover];
BOOL visible = [config isVisibleInScene:SceneTypeLive];
```

> **说明**：`DefaultSlotFactory.defaultConfigs` 已为所有内置插槽预置了默认的场景可见性配置。通过 `registerSlotConfig:` 可覆盖默认配置。

---

## **4. 自定义开发**

### **4.1 插槽协议 (SlotProtocol)**

所有插槽必须遵循 `SlotProtocol`，该协议定义了插槽的最小生命周期契约：

```objc
@protocol SlotProtocol <NSObject>

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

`SlotProvider` 是构建插槽视图的 Block 类型：

```objc
typedef UIView<SlotProtocol> * _Nullable (^SlotProvider)(UIView *parentView);
```

### **4.2 双生命周期**

插槽采用独立的 View 生命周期和 Data 生命周期：

| 生命周期 | 回调方法 | 时机 | 职责 |
|---------|---------|------|------|
| **View 开始** | `onAttach:` | `playerView.attach:` 触发 | 建立宿主连接、订阅通知、初始化视图 |
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

**核心属性**：

| 属性 | 类型 | 说明 |
|-----|------|------|
| `host` | `id<SlotHost>` (weak, readonly) | 当前插槽所附属的宿主 |
| `slotType` | `SlotType` | 当前插槽的类型标识符（由 `SlotHostLayout` 在构建时注入） |
| `safeAreaEdges` | `SlotSafeAreaEdge` | 需要避让的安全区域边缘（默认 `SlotSafeAreaEdgeAll`） |
| `deferContentCreation` | `BOOL` | 延迟内容创建开关 |
| `contentReady` | `BOOL` (readonly) | 内容是否已创建 |
| `touchPassthrough` | `BOOL` | 触摸穿透开关（默认 `YES`） |

**核心方法**：

| 方法 | 说明 |
|-----|------|
| `setupContentView` | 子类重写以创建自定义 UI 元素 |
| `show` / `hide` | 可见性控制 |
| `showWithAnimation:` / `hideWithAnimation:` | 带动画的可见性控制 |
| `isShowing` | 查询当前可见状态 |
| `dismiss` | 通过宿主进行正确的生命周期管理来移除插槽 |
| `ensureContentReady` | 确保延迟内容已创建（幂等） |
| `currentSceneType` | 安全读取当前场景类型 |
| `onRegisterElements` | 子类重写以声明支持的元素及其默认可见性 |
| `isElementVisible:` | 查询指定元素的最终可见性 |

**安全区域避让 (SlotSafeAreaEdge)**：

```objc
typedef NS_OPTIONS(NSUInteger, SlotSafeAreaEdge) {
    SlotSafeAreaEdgeNone   = 0,
    SlotSafeAreaEdgeTop    = 1 << 0,
    SlotSafeAreaEdgeLeft   = 1 << 1,
    SlotSafeAreaEdgeBottom = 1 << 2,
    SlotSafeAreaEdgeRight  = 1 << 3,
    SlotSafeAreaEdgeAll    = SlotSafeAreaEdgeTop | SlotSafeAreaEdgeLeft | SlotSafeAreaEdgeBottom | SlotSafeAreaEdgeRight,
};
```

`SlotHostLayout` 在 `layoutSubviews` 中根据 `safeAreaEdges` 收缩对应边的 frame，使插槽内部布局直接使用自身锚点即可避开刘海、Home Indicator 等区域。子类可在 `initWithFrame:` 中设置此属性。

**延迟内容创建 (deferContentCreation)**：

设为 `YES` 时，`onAttach:` 不会调用 `setupContentView`，内容将在首次调用 `show` 或 `ensureContentReady` 时创建。适用于使用频率较低的插槽（如 SettingMenu），避免在初始化时创建不必要的视图。

```objc
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.deferContentCreation = YES;
    }
    return self;
}
```

**自动隐藏延迟常量**：

```objc
FOUNDATION_EXPORT const NSTimeInterval SlotAutoHideDelay;
```

控制栏自动隐藏类插槽（如 TopBar、BottomBar）在无交互后的隐藏延迟时间（秒）。

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
        // 可选：配置安全区域避让
        self.safeAreaEdges = SlotSafeAreaEdgeNone;
    }
    return self;
}

#pragma mark - 内容创建

- (void)setupContentView {
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
    [self hideWithAnimation:YES];
}

- (void)playerDidChangeState:(PlayerState)state {
    if (state == PlayerStateError) {
        [self show];
    }
}

#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    _coverImageView.frame = self.bounds;
    _titleLabel.frame = CGRectMake(16, self.bounds.size.height - 50,
                                   self.bounds.size.width - 32, 30);
}

@end
```

> **说明**：`BaseSlot` 遵循 `PlayerNotificationDelegate` 协议，在 `onAttach:` 时自动注册为控制器的通知代理。子类直接实现感兴趣的回调方法即可接收播放器事件，无需手动订阅。

**Step 2**：注册并使用：

```objc
SlotManager *slotManager = playerView.slotManager;
[slotManager registerSlotType:SlotTypeCover provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomCoverSlot alloc] initWithFrame:parentView.bounds];
}];
[controller configure:model];
[playerView attach:controller];
```

### **4.5 元素级可见性声明**

子类通过 `onRegisterElements` 声明支持的元素及其默认可见性：

```objc
@implementation MyCustomTopBarSlot

- (NSUInteger)onRegisterElements {
    // 返回默认可见的元素位掩码
    // Back 和 Title 默认可见，Download 和 Snapshot 默认不可见
    return TopBarElementBack | TopBarElementTitle;
}

- (void)setupContentView {
    // 根据元素可见性决定是否创建 UI
    if ([self isElementVisible:TopBarElementBack]) {
        // 创建返回按钮
    }
    if ([self isElementVisible:TopBarElementDownload]) {
        // 创建下载按钮（默认不可见，但外部可通过 showElements 开启）
    }
}

@end
```

`isElementVisible:` 的合并逻辑：
1. 外部 `hideElements:forSlot:` → 强制隐藏
2. 外部 `showElements:forSlot:` → 强制显示
3. 无外部覆盖 → 使用 `onRegisterElements` 声明的默认值

### **4.6 自定义插槽类型 (CustomSlotType)**

除内置插槽类型外，可通过 `CustomSlotType` 在任意位置插入自定义插槽：

```objc
// 在 TopBar(80) 和 BottomBar(90) 之间插入自定义插槽
CustomSlotType *type = [CustomSlotType typeWithKey:@"myCustomSlot" order:85];
[playerView.slotManager registerCustomSlotType:type provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomSlotView alloc] initWithFrame:parentView.bounds];
}];

// 检查自定义插槽是否已注册
BOOL registered = [playerView.slotManager isCustomSlotRegistered:type];

// 获取所有已注册的自定义插槽类型
NSArray<CustomSlotType *> *types = [playerView.slotManager customSlotTypes];

// 注销自定义插槽
[playerView.slotManager unregisterCustomSlotType:type];
```

> **说明**：`CustomSlotType` 通过 `key`（唯一标识）和 `order`（排序值）定义。相等判断仅基于 `key`，同一 key 不可重复注册。自定义插槽在 `rebuildSlots` 时按 `order` 与内置插槽统一排序。

### **4.7 在插槽中发送命令**

插槽通过 `host.controller` 向控制器发送命令，实现单向数据流：

```objc
// 播放/暂停切换
- (void)onPlayPauseButtonTapped {
    AliPlayerController *controller = self.host.controller;
    if (controller.playerState == PlayerStatePlaying) {
        [controller pause];
    } else {
        [controller play];
    }
}

// 进度跳转
- (void)onSeekBarValueChanged:(UISlider *)slider {
    long position = (long)(slider.value * self.host.playerStateStore.duration);
    [self.host.controller seekTo:position];
}

// 全屏切换
- (void)onFullscreenButtonTapped {
    BOOL isFullscreen = self.host.viewState.isFullscreen;
    [self.host.controller setFullscreen:!isFullscreen];
}
```

### **4.8 SlotBehavior（组合模式）**

`SlotBehavior` 采用组合模式设计，使非 `UIView` 对象也能获得插槽能力（生命周期管理、事件订阅）。适用于纯逻辑组件需要监听播放器事件的场景。

```objc
@interface MyAnalyticsTracker : NSObject <PlayerNotificationDelegate>

@property (nonatomic, strong) SlotBehavior *behavior;

@end

@implementation MyAnalyticsTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        _behavior = [[SlotBehavior alloc] init];
    }
    return self;
}

- (void)attachToHost:(id<SlotHost>)host {
    [self.behavior attachToHost:host];
    // 通过 behavior 注册通知代理，detach 时自动取消订阅
    [self.behavior addNotificationDelegate:self toController:host.controller];
}

- (void)detach {
    [self.behavior detach];
}

#pragma mark - PlayerNotificationDelegate

- (void)playerDidRenderFirstFrame {
    // 上报首帧渲染事件
}

- (void)playerDidEncounterError:(NSError *)error {
    // 上报播放错误
}

@end
```

**核心优势**：通过 `addNotificationDelegate:toController:` 注册的所有代理，在 `detach` 时自动取消注册，避免手动管理订阅生命周期导致的内存泄漏。

---

## **5. 宿主协议 (SlotHost)**

`SlotHost` 协议由 `SlotHostLayout`（内部实现）遵循，为插槽提供上下文访问能力：

| 方法/属性 | 说明 |
|----------|------|
| `hostView` | 返回宿主容器视图 |
| `model` | 获取当前播放器模型 |
| `controller` | 获取播放器控制器（弱引用） |
| `playerStateStore` | 获取播放器状态存储（只读） |
| `viewState` | 获取视图层级状态（全屏、控制栏可见性等） |
| `sceneType` | 获取当前场景类型 |
| `setRenderView:` | 为播放器设置渲染视图（由 `PlayerSurfaceSlot` 调用） |
| `dismissSlotView:` | 解散插槽视图，确保生命周期管理的一致性 |
| `allSlotViews` | 返回所有已挂载的插槽视图 |
| `slotViewForType:` | 根据类型获取已挂载插槽视图（O(1) 查找） |
| `slotManager` | 获取插槽管理器（用于元素可见性查询） |
| `notifyBackPressed` | 通知宿主：返回键被按下（非全屏状态） |

> **说明**：插槽应优先通过 `host.sceneType` 或 `BaseSlot.currentSceneType` 读取场景类型，而不是经由 `host.model.sceneType` 链式访问，避免在 model 尚未绑定时返回 nil 透传出的隐性 `SceneTypeVOD`(0) 默认值。

---

## **6. 默认插槽工厂 (DefaultSlotFactory)**

`DefaultSlotFactory` 集中管理所有内置插槽的默认注册：

| 类方法 | 说明 |
|--------|------|
| `+defaultProviders` | 返回 `SlotType → SlotProvider` 的工厂闭包映射字典 |
| `+defaultConfigs` | 返回内置插槽的场景可见性配置数组（`SlotConfig` 数组） |

`SlotManager` 在初始化时一次性拉取这两份数据完成默认注册。新增或移除内置插槽仅需修改 `DefaultSlotFactory`。

通过 `SlotManager.clearAll` 可清空所有配置并重新注册默认值。

---

## **7. 技术原理**

### **7.1 槽位选择策略**

```text
请求创建插槽 → 自定义注册表中有该类型？
                  ├── 是 → 使用自定义实现
                  └── 否 → 默认注册表中有该类型？
                              ├── 是 → 使用默认实现
                              └── 否 → 跳过（不创建）
```

### **7.2 单向数据流**

插槽系统采用单向数据流架构，插槽不直接持有控制器引用：

```text
Controller → State / Event → Slot（状态下行，只读）
Slot → Command → Controller（命令上行，只发）
```

- **状态下行**：通过 `host.playerStateStore` 主动查询，或通过 `PlayerNotificationDelegate` 回调被动接收
- **命令上行**：通过 `host.controller` 调用播放命令，由控制器执行

### **7.3 插槽间隔离**

插槽之间严禁直接获取对方实例或进行点对点通信。当一个插槽需要影响另一个插槽时：

1. 发起插槽通过 `host.controller` 发送状态变更
2. Controller 通过 `PlayerNotificationDelegate` 通知所有关注此变化的插槽

通过这种"事件上浮，状态下沉"的链路，避免了网状的 UI 耦合。

### **7.4 底部控制栏场景差异**

| 控件 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|--------|
| 播放/暂停按钮 | ✓ | ✓ | ✓ | ✓ | ✗ |
| 进度条 | 可拖拽 | 不可拖拽 | 可拖拽 | 不可拖拽 | ✗ |
| 时间显示 | ✓ | ✓ | ✓ | ✓ | ✗ |
| 刷新按钮 | ✗ | ✓ | ✗ | ✗ | ✗ |
| 全屏按钮 | ✓ | ✓ | ✓ | ✓ | ✗ |

---

## **8. API 速查**

### **8.1 核心协议与类**

| 类/协议 | 说明 |
|--------|------|
| `SlotProtocol` | 插槽协议，定义最小生命周期契约 |
| `BaseSlot` | 插槽基类，封装通用逻辑 |
| `SlotManager` | 插槽管理器，统一注册、可见性控制与运行时访问 |
| `SlotHost` | 宿主协议，提供上下文访问能力 |
| `SlotHostLayout` | 宿主协议的内部实现（`UIView` 子类） |
| `SlotConfig` | 场景可见性配置 |
| `SlotBehavior` | 组合模式行为类，为非 UIView 对象提供插槽能力 |
| `DefaultSlotFactory` | 默认插槽工厂，集中管理内置插槽注册 |
| `CustomSlotType` | 自定义插槽类型，支持在内置插槽之间插入 |
| `SlotType` | 内置插槽类型枚举 |

### **8.2 SlotManager 方法速查**

| 分类 | 方法 | 说明 |
|------|-----|------|
| 插槽注册 | `registerSlotType:provider:` | 注册/覆盖内置插槽 Provider |
| | `unregisterSlotType:` | 注销指定类型的插槽 |
| | `isRegistered:` | 检查是否已注册 |
| 自定义插槽 | `registerCustomSlotType:provider:` | 注册自定义插槽 |
| | `unregisterCustomSlotType:` | 注销自定义插槽 |
| | `isCustomSlotRegistered:` | 检查自定义插槽是否已注册 |
| | `customSlotTypes` | 获取所有已注册的自定义插槽类型 |
| 插槽可见性 | `hideSlot:` / `showSlot:` | 整体隐藏/显示插槽 |
| | `isSlotHidden:` | 检查插槽是否被隐藏 |
| 场景可见性 | `registerSlotConfig:` | 注册场景可见性配置 |
| | `unregisterSlotConfigForType:` | 移除场景可见性配置 |
| | `slotConfigForType:` | 获取场景可见性配置 |
| 元素可见性 | `hideElements:forSlot:` | 隐藏插槽内特定元素 |
| | `showElements:forSlot:` | 显示插槽内特定元素 |
| | `setHiddenElementMask:forSlot:` | 替换隐藏元素掩码 |
| | `hiddenElementMaskForSlot:` | 获取隐藏元素掩码 |
| | `shownElementMaskForSlot:` | 获取显示元素掩码 |
| | `setAllHiddenElementMasks:` | 批量设置所有隐藏元素掩码 |
| | `clearAllElementMasks` | 清空所有元素可见性配置 |
| 运行时 | `slotViewForType:` | 获取已挂载的插槽视图 |
| | `rebuildSlots` | 重建所有插槽 |
| | `clearAll` | 清空配置并重新注册默认值 |

---

## **9. 示例参考**

> **参考**：`PlayerKitUsages/UsageSlotSystem` 模块提供了完整的插槽系统使用示例，演示了默认插槽配置的开箱即用、通过 `SlotManager` 自定义插槽注册与隐藏，以及插槽生命周期的自动管理。
