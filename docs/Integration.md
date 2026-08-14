> 📚 **推荐阅读路径**
>
> [核心能力](./CoreFeatures.md) → **集成准备** → [快速开始](./QuickStart.md) → [API 参考](./ApiReference.md)

---

# **AliPlayerKit 集成准备**

本文档将介绍 AliPlayerKit iOS 端的集成步骤与前提条件，帮助您将 AliPlayerKit 集成到 iOS 项目中。

---

## **1. 集成方案概览**

AliPlayerKit 采用分层架构设计，根据集成深度提供两种方案：

| 集成方案 | 模块 | 说明 | 适用场景 |
|---------|------|------|---------|
| **方案一：组件层集成** | `PlayerKit` | 核心播放器 UI 组件，提供 MVC 架构的播放器视图、控制器和数据模型 | 需要自定义播放器 UI 或灵活控制播放行为 |
| **方案二：场景层集成** | `PlayerKitScenes` | 在组件层基础上提供标准播放场景方案 | 快速实现中长视频、短视频、直播、列表播放等标准场景 |

> **说明**：场景层依赖组件层。若选择场景层集成，需先完成组件层集成。

![Integration](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/iOS/Integration.png)

---

## **2. 前提条件**

### **2.1 开发环境要求**

| 项目 | 最低要求 | 说明 |
|------|---------|------|
| iOS Deployment Target | 9.0+ | Podspec 声明的最低版本 |
| Xcode | 15.0+ | 推荐最新稳定版 |
| CocoaPods | 1.13.0+ | 依赖管理工具 |
| 语言 | Objective-C | Swift 项目可通过桥接调用 |
| 架构 | arm64 | 真机运行 |

> **Swift 项目接入**：PlayerKit 使用 Objective-C 开发，对于 Swift 工程，推荐参考 [Swift-Call-OC-Example](https://github.com/MediaBox-Demos/AliPlayer-iOS/tree/master/Swift-Call-OC-Example) 方案完成 PlayerKit 的集成与使用。

### **2.2 License 准备**

播放器 SDK 需要有效的 License 授权才能正常工作。

- 您已获取音视频终端 SDK 的播放器 **License 授权证书**（`license.crt`）和 **License Key**
- 获取步骤详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)

> **注意**：未正确配置 License 将导致播放器无法正常工作，播放时出现黑屏等异常。这是最常见的集成问题。

---

## **3. 方案一：组件层集成**

`PlayerKit` 模块提供开箱即用、可配置的播放器 UI 组件，是整个 AliPlayerKit 的核心。

### **步骤 1：拷贝模块到项目中**

将本仓库中的 `PlayerKit/` 目录拷贝到您的项目工程目录下（与您的 `Podfile` 同级或合适的子目录中）。

```
YourProject/
├── YourApp/
├── PlayerKit/                  # ← 拷贝此目录
│   ├── PlayerKit.podspec
│   ├── Source/
│   └── Resources/
└── Podfile
```

### **步骤 2：配置 Podfile**

在 `Podfile` 中通过本地路径引用 `PlayerKit`：

```ruby
platform :ios, '9.0'

target 'YourApp' do
  use_frameworks!

  # 核心组件（必选，通过本地路径引用）
  pod 'PlayerKit', :path => './PlayerKit'

  # 底层播放器 SDK（必选）
  pod 'AliPlayerSDK_iOS', '~> 7.15.0'

  # 直播 RTS 超低延时（可选，仅直播场景需要）
  # pod 'AliPlayerSDK_iOS_ARTC', '~> 7.15.0'
  # pod 'RtsSDK', '~> 7.12.0'
end
```

> **依赖说明**：`PlayerKit.podspec` 内部声明了对 `AliPlayerSDK_iOS` 和 `SDWebImage` 的依赖，`pod install` 时会自动拉取。`AliPlayerSDK_iOS` 提供视频解码与渲染能力，`SDWebImage` 用于封面图加载。如果您的项目已有 SDWebImage，请注意版本兼容性。

### **步骤 3：安装依赖**

```bash
pod install
open YourApp.xcworkspace
```

> **注意**：使用 CocoaPods 后请通过 `.xcworkspace` 打开工程，而非 `.xcodeproj`。

### **步骤 4：配置 License**

播放器 SDK 需要有效的 License 授权才能正常工作。请参阅 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management) 完成 License 的获取与配置。

> **注意**：未正确配置 License 将导致播放器无法正常工作，播放时出现黑屏等异常。请确保 License 注册在 `[AliPlayerKit setup]` 之前完成。

### **步骤 5：全局初始化**

在 `AppDelegate` 中完成框架初始化（整个应用生命周期只需调用一次）：

* **Objective-C**：

```objc
#import <PlayerKit/AliPlayerKit.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // （可选）全局 SDK 配置，如 setOption 等
    // [AliPlayerKit setOnGlobalInitBlock:^{
    //     // 全局配置在 setup 后仅执行一次
    // }];

    // 初始化 AliPlayerKit
    [AliPlayerKit setup];

    return YES;
}
```

* **Swift**：

```swift
import AliPlayerKit

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // （可选）全局 SDK 配置
    // AliPlayerKit.setOnGlobalInitBlock {
    //     // 全局配置在 setup 后仅执行一次
    // }

    // 初始化 AliPlayerKit
    AliPlayerKit.setup()

    return true
}
```

> **说明**：
>
> - `[AliPlayerKit setup]` 内部使用 `dispatch_once` 保证幂等，重复调用安全忽略
> - `setOnGlobalInitBlock:` 必须在 `setup` 之前设置，用于注入全局级 SDK 配置
> - 可通过 `[AliPlayerKit isInitialized]` 查询初始化状态

### **步骤 6：验证集成**

**验证检查清单**：

- [ ] `pod install` 成功，无依赖冲突
- [ ] License 已正确配置（详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)）
- [ ] `AppDelegate` 中调用 `[AliPlayerKit setup]`
- [ ] 编译通过（`Cmd + B`），无链接错误

> 编译通过即表示组件层集成成功。播放器页面的具体创建方式请参阅 [快速开始](./QuickStart.md)。

---

## **4. 方案二：场景层集成**

场景层（`PlayerKitScenes`）在组件层基础上，提供针对特定业务场景的标准播放方案。每个场景模块独立可选，您可按需引入。

> **前置条件**：场景层依赖组件层。在集成场景层之前，请先完成 **方案一：组件层集成** 的全部步骤。

### **步骤 1：拷贝模块到项目中**

将本仓库中的 `PlayerKitScenes/` 目录拷贝到您的项目工程目录下（与 `PlayerKit/` 同级）：

```
YourProject/
├── YourApp/
├── PlayerKit/                  # 组件层（已在方案一中拷贝）
├── PlayerKitScenes/            # ← 拷贝此目录
│   ├── PlayerKitScenes.podspec
│   ├── SceneCommon/
│   ├── SceneLongVideo/
│   ├── SceneShortVideo/
│   ├── SceneLive/
│   ├── ScenePlaylist/
│   └── SceneAiEducation/
└── Podfile
```

### **步骤 2：配置 Podfile**

在 `Podfile` 中通过本地路径引用 `PlayerKitScenes`：

```ruby
target 'YourApp' do
  use_frameworks!

  # 核心组件（必选）
  pod 'PlayerKit', :path => './PlayerKit'
  pod 'AliPlayerSDK_iOS', '~> 7.15.0'

  # 播放场景方案（通过本地路径引用，按需引入）
  pod 'PlayerKitScenes', :path => './PlayerKitScenes'    # 全部场景（默认包含 LongVideo/ShortVideo/Live/Playlist/AiEducation）
  # 或按需选择单个场景：
  # pod 'PlayerKitScenes/SceneLongVideo', :path => './PlayerKitScenes'   # 仅中长视频
  # pod 'PlayerKitScenes/SceneShortVideo', :path => './PlayerKitScenes'  # 仅短视频
  # pod 'PlayerKitScenes/SceneLive', :path => './PlayerKitScenes'        # 仅直播
  # pod 'PlayerKitScenes/ScenePlaylist', :path => './PlayerKitScenes'    # 仅列表播放
  # pod 'PlayerKitScenes/SceneAiEducation', :path => './PlayerKitScenes' # 仅 AI 教育
end
```

**场景模块说明**：

| 场景模块 | Pod Subspec | 说明 |
|---------|-------------|------|
| `SceneCommon` | `PlayerKitScenes/SceneCommon` | 场景公共模块（自动作为基础依赖引入） |
| `SceneLongVideo` | `PlayerKitScenes/SceneLongVideo` | 中长视频场景 |
| `SceneShortVideo` | `PlayerKitScenes/SceneShortVideo` | 短视频场景 |
| `SceneLive` | `PlayerKitScenes/SceneLive` | 直播场景。**额外依赖 `DemoSettings` 模块**（Demo 级配置存储），单独集成时需一并拷贝 `DemoSettings/` 目录，否则 `pod install` 会失败 |
| `ScenePlaylist` | `PlayerKitScenes/ScenePlaylist` | 列表播放场景 |
| `SceneAiEducation` | `PlayerKitScenes/SceneAiEducation` | AI 教育场景。**额外依赖 `DemoSettings` 模块与第三方库 `Down (~> 0.11.0)`**（MIT 协议，内含 cmark），用于 Markdown 渲染，`pod install` 时自动拉取 |

> **SceneAiEducation 依赖说明**：
>
> - 该场景包含 Swift 源码（`swift_version 5.1`），集成方需使用支持 Swift 的现代 Xcode，Podfile 需启用 `use_frameworks!`。
> - iOS ≥ 12.2 系统内置 Swift runtime，无额外体积成本；更低版本由 Xcode 自动内嵌 runtime。
> - 默认 subspec 集包含该场景，即默认集成会引入 `Down` 依赖。若不需要 AI 教育场景，可在 Podfile 中仅显式引用所需 subspec（不含 `SceneAiEducation`），即不会编译 Swift、也不会引入 `Down`。
> - 其他 subspec 与 PlayerKit 核心库保持纯 Objective-C，不受影响。

> **跨平台对齐**：场景模块命名与 Android 端对齐（`scene-longvideo`、`scene-shortvideo`、`scene-live`、`scene-playlist`）。各场景的业务能力和 UI 交互在多端间保持一致。

### **步骤 3：安装并验证**

```bash
pod install
```

编译通过即表示场景层集成成功。场景页面的启动方式请参阅 [快速开始](./QuickStart.md)。

---

## **5. （可选）SDK 升级指南**

AliPlayerKit 依赖以下底层 SDK：

| SDK | 说明 |
|-----|------|
| **AliPlayerSDK_iOS** | 阿里云播放器 SDK，提供视频解码、渲染及播放控制等基础播放能力 |
| **RtsSDK** | 阿里云 RTS SDK，提供超低延时直播播放能力（可选） |

### **5.1 查看版本信息**

- 运行时可通过 `[AliPlayerKit getSdkVersion]` 获取底层 SDK 版本号
- 通过 `[AliPlayerKit getPlayerKitVersion]` 获取 AliPlayerKit 组件版本号
- [下载播放器 SDK](https://help.aliyun.com/zh/vod/developer-reference/sdk-download)
- [iOS 播放器 SDK 发布历史](https://help.aliyun.com/zh/vod/developer-reference/release-notes-for-apsaravideo-player-sdk-for-ios)

### **5.2 升级步骤**

1. **确认版本兼容性**

   升级前建议查阅 SDK 发布历史与更新日志，确认目标版本是否存在 Breaking Changes。

2. **修改 Podfile 版本号**

   ```ruby
   pod 'AliPlayerSDK_iOS', '~> x.x.x'  # 替换为目标版本

   # RTS（如使用直播场景）
   # pod 'AliPlayerSDK_iOS_ARTC', '~> x.x.x'
   # pod 'RtsSDK', '~> x.x.x'
   ```

3. **执行更新**

   ```bash
   pod update AliPlayerSDK_iOS
   ```

4. **验证升级**

   - 编译通过，无链接错误
   - 验证核心播放功能：播放、暂停、Seek、倍速等
   - 验证特定播放场景：如 RTS 超低延时直播等

> **建议**：升级 SDK 后，建议记录升级前后的版本号，以便后续问题排查和版本追溯。

---

## **6. 常见问题**

### **6.1 License 相关问题**

**问题**：播放器报 License 错误或播放黑屏

请确认 License 已正确获取与配置，详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)。常见原因包括：证书文件未正确添加到工程、License Key 不匹配、Bundle ID 与 License 绑定的包名不一致、License 已过期等。

### **6.2 依赖冲突问题**

**问题**：`pod install` 失败，提示依赖冲突

**排查步骤**：

1. 检查项目中是否已存在 `SDWebImage` 的不同版本（PlayerKit 依赖 `SDWebImage 5.18.1`）
2. 使用 `pod update` 尝试更新到兼容版本
3. 如有第三方库版本冲突，可在 Podfile 中指定兼容版本号
4. 执行 `pod repo update` 刷新本地仓库索引后重试

### **6.3 初始化问题**

**问题**：调用 `[AliPlayerKit setup]` 后播放异常

**排查步骤**：

1. 确认在 `AppDelegate` 的 `application:didFinishLaunchingWithOptions:` 中调用
2. 确认 License 已正确配置（详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)）
3. 通过 `[AliPlayerKit isInitialized]` 确认初始化成功
4. `setup` 内置幂等保护（`dispatch_once`），重复调用不会抛异常
5. 如需注入全局 SDK 配置，确认 `setOnGlobalInitBlock:` 在 `setup` 之前设置


### **6.4 日志调试**

如果遇到播放异常，可开启调试日志辅助排查：

```objc
// 开启调试模式
[AliPlayerKit setDebugModeEnabled:YES];
// 设置日志级别为 Verbose，输出最详细的日志
[AliPlayerKit setLogLevel:LogLevelVerbose];
```

日志系统的详细使用方式请参阅 [日志系统](./advanced/LogSystem.md)。

---

完成以上步骤后，您即可在项目中集成并使用 AliPlayerKit。

接下来，请参考 **[快速开始](./QuickStart.md)**，了解如何创建播放器并实现基本的视频播放功能。
