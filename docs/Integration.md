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

**架构层级**：

```
┌─────────────────────────────────────────────────────────┐
│                    应用业务层 (App)                       │
├─────────────────────────────────────────────────────────┤
│                  场景层 (PlayerKitScenes)   ← 方案二      │
│    SceneLongVideo / SceneShortVideo / SceneLive / ...    │
├─────────────────────────────────────────────────────────┤
│                 组件层 (PlayerKit)          ← 方案一      │
│    AliPlayerView + AliPlayerController + AliPlayerModel  │
│    + 插槽系统 + 通知系统 + 策略系统 + 生命周期策略          │
├─────────────────────────────────────────────────────────┤
│              底层播放器 SDK (AliPlayerSDK_iOS)            │
│              解码 / 渲染 / 网络 / DRM                     │
└─────────────────────────────────────────────────────────┘
```

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

### **步骤 1：添加 CocoaPods 依赖**

在 `Podfile` 中添加以下依赖：

```ruby
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!

  # 核心组件（必选）
  pod 'PlayerKit'

  # 底层播放器 SDK（必选）
  pod 'AliPlayerSDK_iOS', '~> 7.15.0'

  # 直播 RTS 超低延时（可选，仅直播场景需要）
  # pod 'AliPlayerSDK_iOS_ARTC', '~> 7.15.0'
  # pod 'RtsSDK', '~> 7.12.0'
end
```

> **依赖说明**：`PlayerKit` 内部声明了对 `AliPlayerSDK_iOS` 和 `SDWebImage` 的依赖。`AliPlayerSDK_iOS` 提供视频解码与渲染能力，`SDWebImage` 用于封面图加载。如果您的项目已有 SDWebImage，请注意版本兼容性。

执行安装：

```bash
pod install
open YourApp.xcworkspace
```

> **注意**：使用 CocoaPods 后请通过 `.xcworkspace` 打开工程，而非 `.xcodeproj`。

### **步骤 2：配置 Info.plist**

根据业务需求，在 `Info.plist` 中添加以下配置：

```xml
<!-- 必选：允许 HTTP 视频流加载 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- 可选：后台音频播放 -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

| 配置键 | 用途 | 是否必选 |
|--------|------|---------|
| `NSAppTransportSecurity` | 允许 HTTP 视频流加载 | 必选 |
| `UIBackgroundModes` (audio) | 后台音频播放 | 按需 |
| `NSMicrophoneUsageDescription` | 麦克风（直播推流场景） | 按需 |

### **步骤 3：配置 License**

播放器 SDK 需要有效 License 才能正常工作。支持两种配置方式：

#### **方式一：Info.plist 配置**

```xml
<key>AlivcLicenseKey</key>
<string>您的 License Key</string>
<key>AlivcLicenseFile</key>
<string>license.crt</string>
```

#### **方式二：代码配置（推荐）**

* **Objective-C**：

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@"crt"];
    [AlivcLicenseManager registerLicenseFile:path licenseKey:@"您的 License Key"];
    return YES;
}
```

* **Swift**：

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let path = Bundle.main.path(forResource: "license", ofType: "crt")!
    AlivcLicenseManager.registerLicenseFile(path, licenseKey: "您的 License Key")
    return true
}
```

> **注意**：
>
> - 将 `license.crt` 拖入 Xcode 工程并勾选 `Copy items if needed`
> - 确认文件在 `Build Phases → Copy Bundle Resources` 中可见
> - License 获取详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)

### **步骤 4：全局初始化**

在 `AppDelegate` 中完成 License 注册和框架初始化（整个应用生命周期只需调用一次）：

* **Objective-C**：

```objc
#import <AliPlayerKit/AliPlayerKit.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. License 配置
    NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@"crt"];
    [AlivcLicenseManager registerLicenseFile:path licenseKey:@"您的 License Key"];

    // 2. （可选）全局 SDK 配置，如 setOption 等
    // [AliPlayerKit setOnGlobalInitBlock:^{
    //     // 全局配置在 setup 后仅执行一次
    // }];

    // 3. 初始化 AliPlayerKit
    [AliPlayerKit setup];

    return YES;
}
```

* **Swift**：

```swift
import AliPlayerKit

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 1. License 配置
    let path = Bundle.main.path(forResource: "license", ofType: "crt")!
    AlivcLicenseManager.registerLicenseFile(path, licenseKey: "您的 License Key")

    // 2. （可选）全局 SDK 配置
    // AliPlayerKit.setOnGlobalInitBlock {
    //     // 全局配置在 setup 后仅执行一次
    // }

    // 3. 初始化 AliPlayerKit
    AliPlayerKit.setup()

    return true
}
```

> **说明**：
>
> - `[AliPlayerKit setup]` 内部使用 `dispatch_once` 保证幂等，重复调用安全忽略
> - `setOnGlobalInitBlock:` 必须在 `setup` 之前设置，用于注入全局级 SDK 配置
> - 可通过 `[AliPlayerKit isInitialized]` 查询初始化状态

### **步骤 5：验证集成**

**验证检查清单**：

- [ ] `pod install` 成功，无依赖冲突
- [ ] `license.crt` 在 `Build Phases → Copy Bundle Resources` 中
- [ ] `Info.plist` 已配置 `NSAppTransportSecurity`
- [ ] `AppDelegate` 中依次调用 License 注册 → `[AliPlayerKit setup]`
- [ ] 编译通过（`Cmd + B`），无链接错误
- [ ] 真机运行视频正常播放

> 编译通过即表示组件层集成成功。播放器页面的具体创建方式请参阅 [快速开始 — 方案一](./QuickStart.md#4-方案一组件层接入)。

---

## **4. 方案二：场景层集成**

场景层（`PlayerKitScenes`）在组件层基础上，提供针对特定业务场景的标准播放方案。每个场景模块独立可选，您可按需引入。

> **前置条件**：场景层依赖组件层。在集成场景层之前，请先完成 **方案一：组件层集成** 的全部步骤。

### **步骤 1：选择场景模块**

| 场景模块 | Pod Subspec | 说明 |
|---------|-------------|------|
| `SceneCommon` | `PlayerKitScenes/SceneCommon` | 场景公共模块（必需基础依赖） |
| `SceneLongVideo` | `PlayerKitScenes/SceneLongVideo` | 中长视频场景 |
| `SceneShortVideo` | `PlayerKitScenes/SceneShortVideo` | 短视频场景 |
| `SceneLive` | `PlayerKitScenes/SceneLive` | 直播场景 |
| `ScenePlaylist` | `PlayerKitScenes/ScenePlaylist` | 列表播放场景 |

> **跨平台对齐**：场景模块命名与 Android 端对齐（`scene-longvideo`、`scene-shortvideo`、`scene-live`、`scene-playlist`）。各场景的业务能力和 UI 交互在多端间保持一致。

### **步骤 2：添加依赖**

在 `Podfile` 中添加所需场景模块：

```ruby
target 'YourApp' do
  use_frameworks!

  # 核心组件（必选）
  pod 'PlayerKit'
  pod 'AliPlayerSDK_iOS', '~> 7.15.0'

  # 播放场景方案（按需引入）
  pod 'PlayerKitScenes'                    # 全部场景（默认包含 LongVideo/ShortVideo/Live/Playlist）
  # 或按需选择单个场景：
  # pod 'PlayerKitScenes/SceneLongVideo'   # 仅中长视频
  # pod 'PlayerKitScenes/SceneShortVideo'  # 仅短视频
  # pod 'PlayerKitScenes/SceneLive'        # 仅直播
  # pod 'PlayerKitScenes/ScenePlaylist'    # 仅列表播放
end
```

执行安装：

```bash
pod install
```

### **步骤 3：验证集成**

编译通过即表示场景层集成成功。场景页面的启动方式请参阅 [快速开始 — 方案二](./QuickStart.md#5-方案二场景层接入)。

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

**排查步骤**：

1. 确认 License 证书（`license.crt`）和 Key 配置正确
2. 确认 `license.crt` 在 `Build Phases → Copy Bundle Resources` 中
3. 确认 Bundle ID 与 License 绑定的包名一致
4. 检查 License 是否已过期
5. 确认 License 注册在 `[AliPlayerKit setup]` 之前完成

> **跨平台对比**：Android 端通过 `AndroidManifest.xml` 的 `<meta-data>` 配置 License，iOS 端推荐在代码中调用 `AlivcLicenseManager` 注册。

### **6.2 依赖冲突问题**

**问题**：`pod install` 失败，提示依赖冲突

**排查步骤**：

1. 检查项目中是否已存在 `SDWebImage` 的不同版本（PlayerKit 依赖 `SDWebImage 5.18.1`）
2. 使用 `pod update` 尝试更新到兼容版本
3. 如有第三方库版本冲突，可在 Podfile 中指定兼容版本号
4. 执行 `pod repo update` 刷新本地仓库索引后重试

### **6.3 网络配置问题**

**问题**：`NSURLErrorDomain` 网络错误，视频无法加载

**排查步骤**：

1. 确认 `Info.plist` 中已配置 `NSAllowsArbitraryLoads` 为 `YES`
2. 如仅需允许特定域名，可使用 `NSExceptionDomains` 替代全局放行
3. 检查视频 URL 是否可访问（可在浏览器中测试）

### **6.4 初始化问题**

**问题**：调用 `[AliPlayerKit setup]` 后播放异常

**排查步骤**：

1. 确认在 `AppDelegate` 的 `application:didFinishLaunchingWithOptions:` 中调用
2. 确认 License 注册在 `setup` 之前完成
3. 通过 `[AliPlayerKit isInitialized]` 确认初始化成功
4. `setup` 内置幂等保护（`dispatch_once`），重复调用不会抛异常
5. 如需注入全局 SDK 配置，确认 `setOnGlobalInitBlock:` 在 `setup` 之前设置


### **6.5 日志调试**

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
