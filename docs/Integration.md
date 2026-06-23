> 📚 **推荐阅读路径**
>
> [核心能力](./CoreFeatures.md) → **集成准备** → [快速开始](./QuickStart.md) → [API 参考](./ApiReference.md)

---

# **AliPlayerKit 集成准备**

本文档将介绍 AliPlayerKit 的集成步骤和前提条件，帮助您快速将 AliPlayerKit 集成到 iOS 项目中。

---

## **1. 集成流程概览**

AliPlayerKit 提供两种集成方案，您可以根据业务需求选择：

| 集成方案 | 模块 | 说明 | 适用场景 |
|---------|------|------|---------|
| **方案一：组件层集成** | `PlayerKit` | 核心播放器 UI 组件 | 需要自定义播放器 UI 或灵活控制播放行为 |
| **方案二：场景层集成** | `PlayerKitScenes` | 在组件层基础上集成场景模块 | 快速实现标准播放场景 |

> **说明**：场景层依赖组件层。若选择场景层集成，需先完成组件层集成。

---

## **2. 前提条件**

### **2.1 开发环境配置**

在使用 AliPlayerKit 之前，请确保您的开发环境满足以下要求：

| 项目 | 最低要求 | 说明 |
|------|---------|------|
| iOS Deployment Target | 11.0+ | 最低支持 iOS 11 |
| Xcode | 15.0+ | 推荐最新稳定版 |
| CocoaPods | 1.13.0+ | 依赖管理工具 |
| 语言 | Objective-C | Swift 兼容调用 |
| 架构 | arm64 | 真机运行 |

### **2.2 License 准备**

- 您已获取音视频终端 SDK 的播放器 License 授权证书和 License Key
- 获取详细步骤请参见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)

> **注意**：如未正确配置 License，播放器将无法正常工作，播放时会出现黑屏等异常。

---

## **3. 方案一：组件层集成**

`PlayerKit` 核心模块提供开箱即用、可配置的播放器 UI 组件，覆盖基础播放与常见交互能力。

### **步骤 1：添加 CocoaPods 依赖**

在 `Podfile` 中添加以下依赖：

```ruby
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!

  # 核心组件（必选）
  pod 'PlayerKit'
  pod 'AliPlayerSDK_iOS', '~> 7.15.0'

  # 直播场景（可选）
  # pod 'AliPlayerSDK_iOS_ARTC', '~> 7.15.0'
  # pod 'RtsSDK', '~> 7.12.0'
end
```

执行安装：

```bash
pod install
open YourApp.xcworkspace
```

> **注意**：使用 CocoaPods 后请用 `.xcworkspace` 打开工程。

### **步骤 2：配置 Info.plist**

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

播放器 SDK 需要有效 License，支持两种方式：

#### **3.1 Info.plist 方式**

```xml
<key>AlivcLicenseKey</key>
<string>您的 License Key</string>
<key>AlivcLicenseFile</key>
<string>license.crt</string>
```

#### **3.2 代码方式（推荐）**

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
> - 将 `license.crt` 拖入工程并勾选 `Copy items if needed`，确保在 `Build Phases → Copy Bundle Resources` 中可见
> - License 获取详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)

### **步骤 4：初始化与验证**

在 `AppDelegate` 中完成 License 注册 + 全局初始化（仅需一次）：

* **Objective-C**：

```objc
#import <AliPlayerKit/AliPlayerKit.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. License 配置
    NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@"crt"];
    [AlivcLicenseManager registerLicenseFile:path licenseKey:@"您的 License Key"];
    // 2. 初始化 AliPlayerKit
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
    // 2. 初始化 AliPlayerKit
    AliPlayerKit.setup()
    return true
}
```

> `[AliPlayerKit setup]` 内置幂等保护，重复调用安全忽略。

**验证检查清单**：

- [ ] `pod install` 成功，无依赖冲突
- [ ] `license.crt` 在 Copy Bundle Resources 中
- [ ] `Info.plist` 已配置 `NSAppTransportSecurity`
- [ ] `AppDelegate` 中调用了 License 注册 + `[AliPlayerKit setup]`
- [ ] 编译通过（`Cmd + B`），无链接错误
- [ ] 真机运行视频正常播放

---

## **4. 方案二：场景层集成**

场景层提供针对具体业务场景的播放方案，如中长视频、短视频、直播和列表播放等。每个场景模块都是独立可选的，您可以根据业务需求选择集成。

> **前置条件**：场景层依赖组件层能力。在集成场景层之前，请先完成 **方案一：组件层集成**。

### **步骤 1：选择场景模块**

| 场景模块 | Pod Subspec | 说明 |
|---------|-------------|------|
| `SceneCommon` | `PlayerKitScenes/SceneCommon` | 场景公共模块（必需基础依赖） |
| `SceneLongVideo` | `PlayerKitScenes/SceneLongVideo` | 中长视频场景 |
| `SceneShortVideo` | `PlayerKitScenes/SceneShortVideo` | 短视频场景 |
| `SceneLive` | `PlayerKitScenes/SceneLive` | 直播场景 |
| `ScenePlaylist` | `PlayerKitScenes/ScenePlaylist` | 列表播放场景 |

### **步骤 2：添加依赖并验证**

在 `Podfile` 中添加所需场景模块：

```ruby
target 'YourApp' do
  use_frameworks!

  # 核心组件（必选）
  pod 'PlayerKit'
  pod 'AliPlayerSDK_iOS', '~> 7.15.0'

  # 播放场景方案（按需引入）
  pod 'PlayerKitScenes'                    # 全部场景
  # 或按需选择：
  # pod 'PlayerKitScenes/SceneLongVideo'   # 仅中长视频
  # pod 'PlayerKitScenes/SceneLive'        # 仅直播
end
```

执行安装并验证：

```bash
pod install
```

> 编译通过即表示场景层集成成功。场景页面的启动方式请参阅 [快速开始 — 方案二](./QuickStart.md#5-方案二场景层接入)。

---

## **5. （可选）SDK 升级指南**

AliPlayerKit 内部依赖以下 SDK：

| SDK | 说明 |
|-----|------|
| **AliPlayerSDK_iOS** | 阿里云播放器 SDK，提供视频解码、渲染及播放控制等基础播放能力 |
| **RtsSDK** | 阿里云 RTS SDK，提供超低延时直播播放能力（可选） |

### **5.1 查看版本信息**

您可以通过以下链接查看相关 SDK 的最新版本及文档：

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

> **💡 建议**：升级 SDK 后，建议记录升级前后的版本号，以便后续问题排查和版本追溯。

---

## **6. 常见问题**

### **6.1 License 相关问题**

**问题**：播放器报 License 错误或播放黑屏

**解决方案**：

1. 确认已正确配置 License 证书和 Key
2. 检查 License 是否已过期
3. 确认 Bundle ID 与 License 绑定的包名一致
4. 确认 `license.crt` 在 `Build Phases → Copy Bundle Resources` 中

### **6.2 依赖冲突问题**

**问题**：`pod install` 失败，提示依赖冲突

**解决方案**：

1. 检查项目中是否已存在相同依赖的不同版本
2. 使用 `pod update` 尝试更新到兼容版本
3. 如有第三方库版本冲突，可在 Podfile 中指定兼容版本号

### **6.3 网络配置问题**

**问题**：`NSURLErrorDomain` 网络错误，视频无法加载

**解决方案**：

1. 确认 `Info.plist` 中已配置 `NSAllowsArbitraryLoads` 为 `YES`
2. 如仅需允许特定域名，可使用 `NSExceptionDomains` 替代

### **6.4 初始化失败问题**

**问题**：调用 `[AliPlayerKit setup]` 后播放异常

**解决方案**：

1. 确认在 `AppDelegate` 的 `didFinishLaunchingWithOptions:` 中调用
2. 确认 License 注册在 `setup` 之前完成
3. `setup` 内置幂等保护，重复调用不会抛异常

---

完成以上步骤后，您即可在项目中集成并使用 AliPlayerKit。

接下来，请参考 **[快速开始](./QuickStart.md)**，了解如何创建播放器并实现基本的视频播放功能。
