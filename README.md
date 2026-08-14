Language: 中文简体 | [English](README-EN.md)

![alibaba_cloud_logo](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/AlibabaCloud.svg)

# **AliPlayerKit iOS**

[![Platform](https://img.shields.io/badge/Platform-iOS%209.0%2B-blue.svg)](https://developer.apple.com/ios/) [![Language](https://img.shields.io/badge/Language-Objective--C-orange.svg)](https://developer.apple.com/documentation/objectivec) [![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-green.svg)](https://cocoapods.org/) [![website](https://img.shields.io/badge/Product-VOD-FF6A00)](https://www.aliyun.com/product/vod)

---

## **1. 项目简介**

**AliPlayerKit** 是阿里云面向视频业务推出的 **播放器含 UI 集成方案**，提供**低代码、可扩展的播放器 UI 组件**与**场景化解决方案**。

<p align="center">
  <img
    src="https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/playerkit-ui-preview.png"
    alt="AliPlayerKit UI 组件预览"
    width="100%"
  />
</p>

<p align="center">
  <sub>开箱即用的播放器 UI，支持多种播放形态与交互配置</sub>
</p>

通过对播放器能力和 UI 交互的高度封装，帮助客户以极低的接入成本快速完成 App 播放能力建设，无需直接调用底层播放器 API，也无需自行实现复杂的播放器 UI。

---

## **2. 核心特性**

- **低代码接入** — 极简 API 设计，几行代码即可完成播放器集成。
- **开箱即用的 UI 组件** — 提供可配置的播放器 UI 组件，覆盖基础播放与常见交互能力，支持按需自定义。
- **All-in-One 播放体验** — 仅需传入视频 VID，即可自动展示封面图、视频标题、Seek 缩略图等完整播放信息，打造一站式播放体验。
- **场景化解决方案** — 内置中长视频、短视频、直播、播放列表等典型业务场景，快速搭建完整播放体验。
- **高度可扩展的架构设计** — 插槽系统支持 UI 自由组合，策略系统支持业务逻辑灵活扩展。
- **跨平台统一架构** — 各端共享相同的设计理念与接口语义，降低多端接入与维护成本。

| 平台 | 说明 | 源码 | 文档 |
|------|------|------|------|
| **Android** | 原生 Android 播放器 UI 组件与场景化解决方案 | [PlayerKit-Android](https://github.com/aliyun/PlayerKit-Android) | [在线文档](https://aliyun.github.io/PlayerKit-Android/) |
| **iOS** | 原生 iOS 播放器 UI 组件与场景化解决方案 | [PlayerKit-iOS](https://github.com/aliyun/PlayerKit-iOS) | [在线文档](https://aliyun.github.io/PlayerKit-iOS/) |
| **Flutter** | 跨平台 Flutter 播放器 Widget 封装 | [player_widget](https://github.com/aliyun/player_widget) | [在线文档](https://aliyun.github.io/player_widget/) |

---

## **3. 项目结构**

在架构层级上，**AliPlayerKit 位于播放器内核之上**，通过统一的 UI 组件体系与播放场景抽象，承载不同播放业务的共性能力：

![ProductArchitecture](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/iOS/ProductArchitecture.png)

项目模块结构如下：

```
PlayerKit-iOS/
├── PlayerKit/                  # 核心模块：播放器 UI 组件
├── PlayerKitScenes/            # 场景模块：业务场景解决方案
├── PlayerKitUsages/            # 示例模块：功能演示
├── App/                        # 演示应用：完整功能演示
├── Example/                    # Xcode 工程配置
└── docs/                       # 项目文档：架构说明、接入指南与 API 文档
```

---

## **4. 快速开始**

### **4.1 在线阅读**

**[🌐 点击这里开始在线阅读](https://aliyun.github.io/PlayerKit-iOS/)**

### **4.2 本地阅读**

如果您希望在本地阅读文档，请参考 [**文档目录**](./docs/README.md)。

该目录提供了清晰的文档结构与步骤说明，便于 **AI 与开发者共同理解和执行**。未来我们还将提供专门的 **Skills 支持**，以实现更加完整和便捷的接入体验。

---

## **5. 快速集成**

AliPlayerKit 提供两种集成方案：

| 层级 | 模块 | 说明 | 适用场景 |
|-----|------|------|---------|
| **组件层** | `PlayerKit` | 核心 UI 组件，提供播放器视图、控制器、数据模型 | 需要自定义 UI 或灵活控制播放行为 |
| **场景层** | `PlayerKitScenes` | 完整场景解决方案，包含 UI 和业务逻辑 | 快速实现标准播放场景 |

> **Swift 项目接入**：PlayerKit 使用 Objective-C 开发，对于 Swift 工程，推荐参考 [Swift-Call-OC-Example](https://github.com/MediaBox-Demos/AliPlayer-iOS/tree/master/Swift-Call-OC-Example) 方案完成 PlayerKit 的集成与使用。

> **详细步骤**：请参阅 [集成准备](./docs/Integration.md)。如需了解更多内容，请参考 [文档目录](./docs/README.md)。

---

## **6. 快速接入**

AliPlayerKit 采用 **MVC「3 + 1」分层架构设计**，提供两种接入方式，您可以根据业务需求灵活选择：

| 层级 | 模块 | 说明 | 适用场景 |
|-----|------|------|---------|
| **组件层** | `PlayerKit` | 核心 UI 组件，提供播放器视图、控制器、数据模型 | 需要自定义 UI 或灵活控制播放行为 |
| **场景层** | `PlayerKitScenes` | 完整场景解决方案，包含 UI 和业务逻辑 | 快速实现标准播放场景 |

只需几步，您就可以轻松实现视频播放功能！下图展示了 **组件层接入** 的流程：

![QuickStart](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/iOS/QuickStart.png)

> **详细步骤**：请参阅 [快速开始](./docs/QuickStart.md)。如需了解更多内容，请参考 [文档目录](./docs/README.md)。

---

## **7. 效果演示**

### **7.1 项目运行**

#### **前置条件**

在运行项目前，请确保满足以下条件：

| 条件 | 说明 |
|-----|------|
| Xcode | 15.0+，推荐最新稳定版 |
| iOS | 最低 9.0，推荐真机运行 |
| CocoaPods | 1.13.0+ |
| License | 已获取播放器 License 授权证书和 License Key，详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management) |

#### **运行步骤**

**步骤 1：安装依赖**

```bash
cd Example
pod install
```

**步骤 2：打开工程**

使用 Xcode 打开 `Example/Example.xcworkspace`（注意使用 `.xcworkspace` 而非 `.xcodeproj`）。

**步骤 3：配置 License**

播放器 SDK 需要有效的 License 授权才能正常工作。请参阅 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management) 完成 License 的获取与配置。

**步骤 4：运行项目**

选择目标设备，点击运行（`Cmd + R`）。

#### **常见问题**

**License 问题**：License 与应用 Bundle ID 绑定，如未正确配置将导致播放器无法正常工作。详见 [管理 License](https://help.aliyun.com/zh/vod/developer-reference/license-authorization-and-management)。

### **7.2 演示应用**

为了帮助开发者快速体验 AliPlayerKit 的功能，我们基于此工程构建了演示包。该演示包可以直接安装到设备上运行，无需配置开发环境。

**获取方式：**

使用手机扫描以下二维码，即可快速下载并安装演示包：

![Demo QR Code](https://alivc-demo-cms.alicdn.com/versionProduct/installPackage/AliPlayerKit/demo-qr-code.png)

> **注意**：二维码链接指向最新版本的演示包，请确保您的设备已开启允许安装第三方应用的权限。

---

## **8. 相关产品**

AliPlayerKit 基于阿里云音视频能力构建，建议结合以下云产品使用，通过端云结合获得更好的播放能力和视频体验：

- [阿里云视频点播（VOD）](https://www.aliyun.com/product/vod)
- [阿里云视频直播（Live）](https://www.aliyun.com/product/live)
- [音视频终端 SDK](https://help.aliyun.com/zh/apsara-video-sdk/)

---

## **9. 联系我们**

- 📘 **官方文档**：[播放器帮助中心](https://help.aliyun.com/zh/vod/)
- 🔍 **控制台**：[视频点播控制台](https://vod.console.aliyun.com)
- 📝 **提交工单**：[阿里云官方技术支持](https://smartservice.console.aliyun.com/service/create-ticket)
- 💬 **GitHub Issues**：[欢迎提交反馈与建议](https://github.com/aliyun/PlayerKit-iOS/issues)

更多关于使用阿里云播放器 SDK 的常见问题及修复建议，请参见[播放器常见问题](https://help.aliyun.com/zh/vod/support/faq-about-apsaravideo-player/)。
