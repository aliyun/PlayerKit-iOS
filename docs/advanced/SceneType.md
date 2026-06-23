# **场景类型（SceneType）**

**场景类型 (SceneType)** 是 AliPlayerKit 的播放场景抽象机制，通过指定不同场景自动适配 UI 行为、手势控制和插槽可见性。

> 💡 **大多数开发者不需要关心此配置**：如果你是最普通的点播场景，无需设置 SceneType，默认即为 `SceneTypeVOD`，具备完整的播放能力。只有在直播、受限播放等**非点播场景**时，才需要显式指定。

---

## **1. 概念介绍**

### **1.1 什么是 SceneType？**

SceneType 是告知播放器「当前运行在什么业务场景中」的枚举标识。设置 SceneType 后，AliPlayerKit 会自动：

- 调整**插槽可见性**（如直播场景隐藏封面图、进度条拖拽相关组件）
- 过滤**手势行为**（如视频列表场景禁用垂直手势以避免与列表滑动冲突）
- 适配**功能限制**（如受限场景禁止快进/拖拽/倍速播放）

开发者只需设置一个枚举值，框架自动完成上述适配，极大降低不同业务场景的定制成本。

### **1.2 核心价值**

| 价值 | 说明 |
|------|------|
| 零配置适配 | 设定场景后，UI 与交互行为自动调整，无需逐个配置插槽和手势 |
| 一致性保证 | 同一场景下所有播放器实例保持统一的 UI 规范和交互行为 |
| 降低定制成本 | 用一行代码替代数十行插槽可见性 + 手势过滤代码 |
| 可扩展性 | 可通过 `SlotConfig` 和 `GestureControlSlotConfig` 进一步微调 |

---

## **2. 功能特性**

### **2.1 场景概览**

AliPlayerKit 内置 5 种场景类型，覆盖绝大多数播放业务：

| 场景 | 枚举值 | 说明 | 适用业务 | 与 VOD 的差异 |
|------|--------|------|---------|---------------|
| 点播 | `SceneTypeVOD` | 默认场景，支持全部控制能力 | 常规点播、课程、媒体库 | — |
| 直播 | `SceneTypeLive` | 实时流无固定时长，自动禁用时间轴操作 | 直播、赛事、电商直播 | 禁用进度拖拽/快进/倍速；隐藏封面图 |
| 视频列表 | `SceneTypeVideoList` | 禁用垂直手势，避免与列表滚动冲突 | 信息流、短视频列表 | 禁用音量/亮度垂直手势；其余与 VOD 一致 |
| 受限播放 | `SceneTypeRestricted` | 防跳播，确保用户完整观看 | 考试监控、培训课程 | 禁用进度拖拽/快进/倍速；隐藏封面图 |
| 极简模式 | `SceneTypeMinimal` | 纯净画面，所有控制需自行实现 | 背景播放、完全自定义 UI | 隐藏所有控制组件和手势 |

### **2.2 枚举定义**

```objc
// SceneType.h
typedef NS_ENUM(NSInteger, SceneType) {
    /** 视频点播场景（默认） */
    SceneTypeVOD = 0,

    /** 直播场景 */
    SceneTypeLive = 1,

    /** 视频列表或短视频流场景 */
    SceneTypeVideoList = 2,

    /** 受限播放场景 */
    SceneTypeRestricted = 3,

    /** 极简播放页场景 */
    SceneTypeMinimal = 4,
};
```

---

## **3. 场景能力矩阵**

### **3.1 插槽可见性**

插槽系统根据场景类型自动控制组件可见性：

| 插槽 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|---------|
| `PlayerSurface` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `Fullscreen` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `GestureControl` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `LandscapeHint` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `Cover` | ✓ | ✗ | ✓ | ✗ | ✗ |
| `CenterDisplay` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `PlayState` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `LogPanel` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `TopBar` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `BottomBar` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `SettingMenu` | ✓ | ✓ | ✓ | ✓ | ✗ |
| `OptionPanel` | ✓ | ✓ | ✓ | ✓ | ✗ |

> **可见性规则来源**：`DefaultSlotFactory.defaultConfigs` 中通过 `SlotConfig.excludedScenes` 配置。

### **3.2 手势行为差异**

| 手势 | VOD | LIVE | VIDEO_LIST | RESTRICTED | MINIMAL |
|------|-----|------|------------|------------|---------|
| 单击（显示/隐藏控制栏） | ✓ | ✓ | ✓ | ✓ | ✗ |
| 双击（播放/暂停） | ✓ | ✓ | ✓ | ✓ | ✗ |
| 长按（倍速播放） | ✓ | ✗ | ✓ | ✗ | ✗ |
| 水平拖动（进度跳转） | ✓ | ✗ | ✓ | ✗ | ✗ |
| 左侧垂直拖动（亮度） | ✓ | ✓ | ✗ | ✓ | ✗ |
| 右侧垂直拖动（音量） | ✓ | ✓ | ✗ | ✓ | ✗ |

> **过滤逻辑来源**：`GestureControlSlot` 内部根据 `currentSceneType` 在各手势处理方法中进行场景过滤。

---

## **4. 使用方式**

### **4.1 基本用法**

场景类型通过 `AliPlayerModel.sceneType` 属性指定。**默认为 `SceneTypeVOD`**，无需显式设置。

**点播场景（默认，无需设置）**：

```objc
VideoSource *source = [[VideoSource alloc] initWithUrl:@"https://example.com/video.mp4"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
// model.sceneType 默认为 SceneTypeVOD，无需设置

[controller configure:model];
```

**直播场景**：

```objc
VideoSource *source = [[VideoSource alloc] initWithUrl:@"https://live.example.com/stream.m3u8"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeLive;
model.videoTitle = @"直播间";

[controller configure:model];
```

**视频列表场景**：

```objc
VideoSource *source = [[VideoSource alloc] initWithUrl:videoUrl];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeVideoList;

[controller configure:model];
```

### **4.2 各场景详细说明**

#### **4.2.1 VOD — 点播场景（默认）**

**适用场景**：常规视频播放、在线课程、媒体库浏览等。

**能力说明**：
- 支持全部 12 种内置插槽
- 支持全部 6 种手势
- 支持进度拖拽、倍速播放、清晰度切换
- 支持全屏切换

```objc
// 无需显式指定 SceneType，默认即为 VOD
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.coverUrl = @"https://example.com/cover.jpg";
model.videoTitle = @"精彩视频";
model.autoPlay = YES;

[controller configure:model];
```

#### **4.2.2 LIVE — 直播场景**

**适用场景**：实时直播、赛事直播、电商直播等。

**与 VOD 的关键差异**：
- **禁用**：进度拖拽、快进/快退、倍速播放（因为直播无固定时长）
- **隐藏**：封面图插槽（直播流无需封面）
- **保留**：单击/双击手势、音量/亮度调节

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:liveSource];
model.sceneType = SceneTypeLive;
model.videoTitle = @"热门直播";
model.autoPlay = YES;

[controller configure:model];
```

#### **4.2.3 VIDEO_LIST — 视频列表场景**

**适用场景**：信息流中的内嵌视频、短视频列表、可滑动视频集合等。

**与 VOD 的关键差异**：
- **禁用**：左侧/右侧垂直拖动手势（避免与列表 `UIScrollView` 滑动冲突）
- **保留**：其余所有功能（进度拖拽、倍速、单击/双击/长按等）

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeVideoList;
model.autoPlay = YES;

[controller configure:model];
```

#### **4.2.4 RESTRICTED — 受限播放场景**

**适用场景**：在线考试监控视频、培训认证课程、版权保护场景等。

**与 VOD 的关键差异**：
- **禁用**：进度拖拽、快进/快退、倍速播放（确保用户按序完整观看）
- **隐藏**：封面图插槽
- **保留**：单击/双击手势、音量/亮度调节

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeRestricted;
model.videoTitle = @"安全培训课程";
model.autoPlay = YES;
// 通常配合禁止截屏
model.disableScreenshot = YES;

[controller configure:model];
```

#### **4.2.5 MINIMAL — 极简模式**

**适用场景**：背景播放、完全自定义 UI、预览缩略图播放等。

**与 VOD 的关键差异**：
- **隐藏**：几乎所有 UI 控制插槽（仅保留 PlayerSurface、Fullscreen、PlayState）
- **禁用**：所有手势
- **适用**：需要完全自定义播放控制 UI 的场景

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeMinimal;

[controller configure:model];
// 所有控制需要自行通过 controller 的 API 实现
// 例如：[controller play]; [controller pause]; [controller seekTo:position];
```

---

## **5. 自定义开发**

### **5.1 插槽可见性微调**

当场景预设的插槽可见性不完全满足需求时，可通过 `SlotConfig` 进行微调：

```objc
// 示例：在 LIVE 场景下额外隐藏 TopBar
SlotConfig *topBarConfig = [SlotConfig configWithSlotType:SlotTypeTopBar
                                           excludedScenes:[NSSet setWithObjects:
                                               @(SceneTypeMinimal),
                                               @(SceneTypeLive), nil]];

// 注册到 SlotManager
[playerView.slotManager registerSlotConfig:topBarConfig];
```

### **5.2 手势行为微调**

通过 `GestureControlSlotConfig` 可在场景过滤之外进一步精细控制手势：

```objc
// 示例：在 VOD 场景下额外禁用长按倍速
GestureControlSlotConfig *gestureConfig = [[GestureControlSlotConfig alloc] init];
gestureConfig.longPressEnabled = NO;

// 通过 SlotManager 的元素控制 API 禁用特定手势
[playerView.slotManager hideElements:GestureElementLongPress
                             forSlot:SlotTypeGestureControl];
```

### **5.3 自定义插槽注册**

在 MINIMAL 场景下通过自定义插槽实现完全定制的 UI：

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeMinimal;

[controller configure:model];

// 注册自定义底部控制栏
[playerView.slotManager registerSlotConfig:
    [SlotConfig configWithSlotType:SlotTypeBottomBar]]; // 移除场景排除
// 然后注册自定义插槽实现...
```

### **5.4 动态可见性条件**

使用 `SlotConfig` 的 `visibilityCondition` 回调实现动态控制：

```objc
SlotConfig *coverConfig = [SlotConfig configWithSlotType:SlotTypeCover
                                          excludedScenes:nil
                                     visibilityCondition:^BOOL{
    // 仅在有封面 URL 时显示封面插槽
    return controller.playerModel.coverUrl != nil;
}];

[playerView.slotManager registerSlotConfig:coverConfig];
```

---

## **6. 场景选择指南**

### **6.1 决策流程**

```text
需要播放器控制 UI 吗？
├── 否 → SceneTypeMinimal
└── 是 → 是直播流吗？
         ├── 是 → SceneTypeLive
         └── 否 → 播放器嵌入可滚动列表中吗？
                   ├── 是 → SceneTypeVideoList
                   └── 否 → 需要防止用户跳播吗？
                             ├── 是 → SceneTypeRestricted
                             └── 否 → SceneTypeVOD（默认）
```

### **6.2 场景选择汇总表**

| 业务需求 | 推荐场景 | 关键理由 |
|---------|---------|---------|
| 常规视频播放 | `SceneTypeVOD` | 默认场景，全功能支持 |
| 直播/赛事实时流 | `SceneTypeLive` | 自动禁用无意义的进度操作 |
| UIScrollView 嵌入视频 | `SceneTypeVideoList` | 自动规避垂直手势冲突 |
| 培训/考试/版权保护 | `SceneTypeRestricted` | 自动禁止跳播和倍速 |
| 完全自定义 UI | `SceneTypeMinimal` | 纯净画布，零内置 UI 干扰 |
| 后台/画中画播放 | `SceneTypeMinimal` | 无需 UI 控制组件 |

---

## **7. API 速查**

### **7.1 SceneType 枚举**

| 枚举值 | 整数值 | 说明 |
|--------|--------|------|
| `SceneTypeVOD` | 0 | 视频点播场景（默认） |
| `SceneTypeLive` | 1 | 直播场景 |
| `SceneTypeVideoList` | 2 | 视频列表/短视频流场景 |
| `SceneTypeRestricted` | 3 | 受限播放场景 |
| `SceneTypeMinimal` | 4 | 极简播放页场景 |

### **7.2 相关 API**

| 类/协议 | 属性/方法 | 说明 |
|---------|----------|------|
| `AliPlayerModel` | `sceneType` | 设置场景类型（默认 `SceneTypeVOD`） |
| `SlotConfig` | `excludedScenes` | 配置插槽在哪些场景中不可见 |
| `SlotConfig` | `isVisibleInScene:` | 判断插槽在指定场景中是否可见 |
| `DefaultSlotFactory` | `defaultConfigs` | 获取所有内置插槽的默认场景可见性配置 |
| `BaseSlot` | `currentSceneType` | 获取当前生效的场景类型 |
| `SlotManager` | `hideElements:forSlot:` | 按位掩码隐藏插槽内元素/禁用手势 |

### **7.3 相关文件**

| 文件 | 说明 |
|------|------|
| `PlayerKit/Source/Data/SceneType.h` | SceneType 枚举定义 |
| `PlayerKit/Source/AliPlayerModel.h` | 场景类型设置入口 |
| `PlayerKit/Source/Slot/SlotConfig.h` | 插槽可见性配置 |
| `PlayerKit/Source/Slot/DefaultSlotFactory.h` | 默认场景可见性规则 |
| `PlayerKit/Source/Slot/SlotElements.h` | 手势元素位掩码定义 |

> 完整 API 详见 [API 参考](../ApiReference.md)。

---

## **8. 最佳实践**

### **8.1 注意事项**

| 事项 | 说明 |
|------|------|
| 创建时确定 | SceneType 在 `AliPlayerModel` 创建时指定，播放过程中不应动态切换 |
| 列表场景优先 | 当播放器嵌入 `UIScrollView`/`UICollectionView` 时务必使用 `SceneTypeVideoList` |
| MINIMAL 需自行控制 | 选择 MINIMAL 后所有播放控制需开发者通过 `AliPlayerController` API 自行实现 |
| 可组合微调 | 当预设行为不完全满足需求时，可通过 `SlotConfig` 和 `SlotManager` 进一步微调 |

### **8.2 常见问题**

#### **Q: VOD 和 VIDEO_LIST 的区别是什么？**

主要区别在于垂直手势：`SceneTypeVideoList` 禁用音量/亮度垂直手势，避免与列表容器滚动手势冲突。其余功能与 VOD 一致。

#### **Q: MINIMAL 场景下如何实现自定义控制？**

通过 `AliPlayerController` 的 API 直接控制播放行为，并注册自定义插槽覆盖 UI：

```objc
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.sceneType = SceneTypeMinimal;
[controller configure:model];

// 通过 controller API 直接控制
[controller play];
[controller pause];
[controller seekTo:30000]; // 跳到 30 秒
```

#### **Q: 如何在 LIVE 场景下恢复进度拖拽？**

如果你的直播场景支持回看（timeshift），可通过 `SlotManager` 的元素控制 API 恢复被禁用的手势：

```objc
[playerView.slotManager showElements:GestureElementHorizontalDrag
                             forSlot:SlotTypeGestureControl];
```

---

## **9. 下一步**

- 了解插槽系统的完整能力 → [插槽系统](SlotSystem.md)
- 了解多语言支持 → [多语言](Locale.md)
- 了解自定义配置 → [自定义配置](CustomConfig.md)
- 查看完整 API 文档 → [API 参考](../ApiReference.md)
