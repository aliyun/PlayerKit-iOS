Language: 中文简体 | [English](README-EN.md)

![alibaba_cloud_logo](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/AlibabaCloud.svg)

# AliPlayerKit iOS

[![Platform](https://img.shields.io/badge/Platform-iOS%2011.0%2B-blue.svg)](https://developer.apple.com/ios/)[![Language](https://img.shields.io/badge/Language-Objective--C-orange.svg)](https://developer.apple.com/documentation/objectivec)[![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-green.svg)](https://cocoapods.org/)[![website](https://img.shields.io/badge/Product-VOD-FF6A00)](https://www.aliyun.com/product/vod)

---

## 📖 简介

**AliPlayerKit** 是阿里云视频点播团队推出的播放器 UI 组件库，基于 AliPlayer SDK 构建，提供开箱即用的播放器 UI 组件和标准化播放场景方案。

开发者无需直接调用底层播放器 API，也无需自行实现复杂的播放器 UI，即可快速搭建完整的播放体验。

### ✨ 核心特性

| 特性 | 说明 |
|------|------|
| 🧩 **插槽系统（Slot System）** | UI 组件与业务逻辑完全解耦，支持灵活插拔与自定义 |
| 📡 **通知系统（Notification System）** | 统一的播放器事件分发机制，支持多观察者模式 |
| 📊 **状态管理（State Store）** | 集中式播放状态管理，自动去重与同步 |
| 📝 **日志系统（Log System）** | 可扩展的分级日志框架，支持自定义日志观察者 |
| 🎭 **场景化方案** | 开箱即用的中长视频、短视频、直播等播放场景 |
| 🏗️ **工厂模式** | 支持自定义播放器工厂，便于替换底层播放器实现 |

---

## 🏗️ 架构设计

AliPlayerKit 采用分层架构设计，整体分为两层：

```
┌─────────────────────────────────────────────────────────┐
│                   UI 场景层 (Scenes)                      │
│        中长视频 / 短视频 / 直播 / 列表播放                   │
├─────────────────────────────────────────────────────────┤
│                 UI 组件层 (PlayerKit)                     │
│   插槽系统 / 通知系统 / 状态管理 / 日志系统 / 播放器控制      │
├─────────────────────────────────────────────────────────┤
│              AliPlayer SDK (播放器内核)                    │
└─────────────────────────────────────────────────────────┘
```

### 模块结构

| 模块 | 说明 | Pod 名称 |
|------|------|----------|
| **PlayerKit** | 核心组件层，提供播放器 UI 组件与基础能力 | `PlayerKit` |
| **PlayerKitScenes** | 场景方案层，提供标准化播放场景 | `PlayerKitScenes` |
| **PlayerKitUsages** | 使用示例，演示各子系统集成方式 | `PlayerKitUsages` |
| **App** | 示例应用入口，含首页导航与路由框架 | `App` |

---

## 📦 安装

### 环境要求

- iOS 11.0+
- Xcode 15.0+
- CocoaPods 1.13.0+

### CocoaPods

在 `Podfile` 中添加：

```ruby
# 核心组件（必选）
pod 'PlayerKit'

# 播放场景方案（按需引入）
pod 'PlayerKitScenes'                      # 全部场景
pod 'PlayerKitScenes/SceneLongVideo'       # 仅中长视频场景

# 阿里云播放器 SDK（必选依赖）
pod 'AliPlayerSDK_iOS', '~> x.y.z'
```

然后执行：

```bash
pod install
```

---

## 🚀 快速开始

### 1. 初始化 SDK

在 `AppDelegate` 中初始化 AliPlayerKit：

```objectivec
#import <AliPlayerKit/AliPlayerKit.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 初始化 AliPlayerKit（仅需调用一次）
    [AliPlayerKit setup];
    return YES;
}
```

### 2. 基础播放

只需 **4 步** 即可完成视频播放集成：

```objectivec
#import <AliPlayerKit/AliPlayerKit.h>

// 1. 创建播放器视图
AliPlayerView *playerView = [[AliPlayerView alloc] initWithFrame:self.view.bounds];
[self.view addSubview:playerView];

// 2. 创建播放器控制器
AliPlayerController *controller = [[AliPlayerController alloc] init];

// 3. 配置播放模型（推荐使用 VidAuth 方式）
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                              playAuth:@"your_play_auth"];
AliPlayerModel *model = [[AliPlayerModel alloc] initWithVideoSource:source];
model.videoTitle = @"示例视频";
model.autoPlay = YES;

// 4. 配置数据并绑定控制器到视图
[controller configure:model];
[playerView attach:controller];
```

### 3. VID 播放（阿里云点播）

支持通过 VID + PlayAuth 或 VID + STS 方式播放阿里云点播视频：

```objectivec
// VID + PlayAuth 方式（推荐）
VideoSource *source = [VideoSource vidAuthSourceWithVid:@"your_video_id"
                                              playAuth:@"your_play_auth"];

// VID + STS 方式
VideoSource *source = [VideoSource vidStsSourceWithVid:@"your_video_id"
                                          accessKeyId:@"your_access_key_id"
                                      accessKeySecret:@"your_access_key_secret"
                                        securityToken:@"your_security_token"
                                               region:@"your_region"];
```

---

## 🧩 核心系统

### 插槽系统（Slot System）

插槽系统是 AliPlayerKit 的核心架构之一，实现了 UI 组件与播放逻辑的完全解耦。每个 Slot 是一个独立的 UI 组件，拥有完整的生命周期管理。

**内置插槽类型：**

| 插槽类型 | 说明 | Z-Order |
|---------|------|---------|
| `SlotTypePlayerSurface` | 播放器渲染层 | 10 |
| `SlotTypeGestureControl` | 手势控制层 | 20 |
| `SlotTypeCover` | 封面图层 | 40 |
| `SlotTypeCenterDisplay` | 中心显示层（加载指示器等） | 50 |
| `SlotTypePlayState` | 播放状态层 | 60 |
| `SlotTypeTopBar` | 顶部导航栏 | 80 |
| `SlotTypeBottomBar` | 底部控制栏 | 90 |
| `SlotTypeSettingMenu` | 设置菜单层 | 100 |

**自定义 Slot 示例：**

```objectivec
#import <AliPlayerKit/AliPlayerKit.h>

// 1. 创建自定义 Slot
@interface MyCustomSlot : BaseSlot
@end

@implementation MyCustomSlot

- (void)setupContentView {
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.text = @"自定义组件";
    [self addSubview:label];
}

- (void)onBindData:(AliPlayerModel *)model {
    [super onBindData:model];
    // 根据播放数据更新 UI
}

@end

// 2. 通过 SlotManager 注册自定义插槽
SlotManager *slotManager = playerView.slotManager;
[slotManager registerSlotType:SlotTypeTopBar provider:^UIView<SlotProtocol> *(UIView *parentView) {
    return [[MyCustomSlot alloc] initWithFrame:parentView.bounds];
}];

// 3. 配置并绑定
[controller configure:model];
[playerView attach:controller];
```

### 通知系统（Notification System）

支持多观察者的播放器事件通知机制：

```objectivec
// 添加通知代理
[controller addNotificationDelegate:self];

// 实现 PlayerNotificationDelegate 回调方法
- (void)playerDidChangeState:(PlayerState)state {
    NSLog(@"播放状态变化: %ld", (long)state);
}

- (void)playerDidUpdateCurrentPosition:(NSInteger)position
                              duration:(NSInteger)duration
                      bufferedPosition:(NSInteger)bufferedPosition {
    // 更新进度条
}

- (void)playerDidEncounterError:(NSError *)error {
    NSLog(@"播放错误: %@", error.localizedDescription);
}
```

### 状态管理（State Store）

通过 `PlayerStateStore` 获取实时播放状态：

```objectivec
PlayerStateStore *stateStore = controller.stateStore;

// 读取当前状态
PlayerState state = stateStore.playState;
NSInteger position = stateStore.currentPosition;
NSInteger duration = stateStore.duration;
float speed = stateStore.speed;
BOOL isMuted = stateStore.isMuted;
BOOL isLoop = stateStore.isLoop;
```

---

## 🎭 播放场景

### 中长视频场景

使用 `SceneLongVideoViewController` 快速搭建中长视频播放页面：

```objectivec
#import <SceneLongVideoViewController.h>

SceneLongVideoViewController *vc = [[SceneLongVideoViewController alloc] init];
[self.navigationController pushViewController:vc animated:YES];
```

### 场景类型

AliPlayerKit 通过 `SceneType` 控制不同场景下的 UI 组件可见性：

| 场景类型 | 说明 |
|---------|------|
| `SceneTypeVOD` | 点播场景（默认） |
| `SceneTypeLive` | 直播场景 |
| `SceneTypeVideoList` | 视频列表 / 短视频流 |
| `SceneTypeRestricted` | 受限播放场景 |
| `SceneTypeMinimal` | 极简播放页 |

---

## ⚙️ 高级配置

### 调试模式

```objectivec
// 开启调试模式
[AliPlayerKit setDebugModeEnabled:YES];

// 设置日志级别
[AliPlayerKit setLogLevel:LogLevelDebug];

// 开启/关闭控制台日志
[AliPlayerKit enableConsoleLog:YES];
```

### 自定义播放器工厂

```objectivec
// 实现自定义播放器工厂
@interface MyPlayerFactory : NSObject <PlayerFactory>
@end

@implementation MyPlayerFactory

- (id<MediaPlayer>)createPlayer {
    // 返回自定义播放器实例
    return [[MyCustomPlayer alloc] init];
}

- (void)destroyPlayer:(id<MediaPlayer>)player {
    [player destroy];
}

@end

// 注册自定义工厂
[AliPlayerKit setPlayerFactory:[[MyPlayerFactory alloc] init]];
```

### 播放器生命周期管理

```objectivec
// 前后台切换
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.playerController onResume];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playerController onPause];
}

// 释放资源
- (void)dealloc {
    [self.playerController destroy];
}
```

---

## 📁 项目结构

```
PlayerKit-iOS/
├── PlayerKit/                     # 核心组件库
│   ├── Source/
│   │   ├── AliPlayerKit.h/m       # SDK 全局入口
│   │   ├── AliPlayerView.h/m      # 播放器视图容器
│   │   ├── AliPlayerController.h/m # 播放器控制器
│   │   ├── AliPlayerModel.h/m     # 播放配置模型
│   │   ├── Data/                  # 数据模型（VideoSource, SceneType）
│   │   ├── Slot/                  # 插槽系统
│   │   ├── Notification/          # 通知系统
│   │   ├── StateStore/            # 状态管理
│   │   ├── Log/                   # 日志系统
│   │   ├── Player/                # 播放器抽象层（MediaPlayer, PlayerFactory）
│   │   └── UI/                    # 默认 UI 组件
│   └── Resources/                 # 资源文件
├── PlayerKitScenes/               # 场景方案库
│   ├── SceneCommon/               # 场景公共模块
│   └── SceneLongVideo/            # 中长视频场景
├── PlayerKitUsages/               # 使用示例
│   ├── UsageLogSystem/            # 日志系统示例
│   ├── UsageSlotSystem/           # 插槽系统示例
│   └── UsageNotificationSystem/   # 通知系统示例
├── App/                           # 示例应用
│   └── Source/                    # 首页导航与路由
├── Example/                       # Xcode 工程配置
│   ├── Podfile                    # CocoaPods 依赖配置
│   └── project.yml                # XcodeGen 工程描述
└── LICENSE                        # MIT 开源协议
```

---

## 📋 版本兼容

| 组件 | 最低版本 |
|------|---------|
| iOS Deployment Target | 11.0 |
| Xcode | 15.0+ |
| CocoaPods | 1.13.0+ |
| Swift (混合开发) | 5.0 |
| AliPlayerSDK_iOS | 7.15.0 |

---

## **☎️ 联系我们**

- 📘 **官方文档**：[播放器帮助中心](https://help.aliyun.com/zh/vod/)
- 🔍 **控制台**：[视频点播控制台](https://vod.console.aliyun.com)
- 📝 **提交工单**：[阿里云官方技术支持](https://smartservice.console.aliyun.com/service/create-ticket)
- 💬 **GitHub Issues**：[欢迎提交反馈与建议](https://github.com/aliyun/PlayerKit-iOS/issues)

更多关于使用阿里云播放器 SDK 的常见问题及修复建议，请参见[播放器常见问题](https://help.aliyun.com/zh/vod/support/faq-about-apsaravideo-player/)。

